import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/sync/pending_queue.dart';
import '../../../../core/sync/pending_update.dart';
import '../../../parcels/data/models/parcel.dart';
import '../../../parcels/data/parcel_repository.dart';
import '../../data/manifest_repository.dart';
import '../../data/models/manifest.dart';

/// نتيجة مسحة واحدة. الشاشة تترجمها إلى صوت ولون ورسالة.
sealed class ScanOutcome {
  const ScanOutcome();
}

class ScanAccepted extends ScanOutcome {
  const ScanAccepted(this.parcel, this.status, {this.queued = false});

  final Parcel parcel;
  final ManifestItemStatus status;

  /// سُجّلت محليًّا ولم تصل الخادم بعد — الشبكة مقطوعة والطابور سيتكفّل بها.
  final bool queued;
}

class ScanAlreadyDone extends ScanOutcome {
  const ScanAlreadyDone(this.parcel, this.status);

  final Parcel parcel;
  final ManifestItemStatus status;
}

/// الطرد موجود في النظام لكنه ليس على هذه الشاحنة — الخطأ الأخطر عمليًّا،
/// لأن تحميله يعني وصوله إلى فرع خاطئ.
class ScanNotOnManifest extends ScanOutcome {
  const ScanNotOnManifest(this.parcel);

  final Parcel parcel;
}

class ScanFailed extends ScanOutcome {
  const ScanFailed(this.message);

  final String message;
}

class ManifestState extends Equatable {
  const ManifestState({
    this.manifest,
    this.items = const [],
    this.parcels = const {},
    this.isLoading = true,
    this.isWorking = false,
    this.error,
  });

  final Manifest? manifest;
  final List<ManifestItem> items;

  /// بيانات الطرود التي عُرفت حتى الآن، مفهرسة بمعرّف الطرد. تمتلئ تدريجيًّا
  /// مع كل مسحة: لا توجد نقطة في الخادم تعيد طرود المانيفست دفعة واحدة.
  final Map<String, Parcel> parcels;

  final bool isLoading;
  final bool isWorking;
  final String? error;

  /// أثناء التحميل الهدف LOADED، وبعد انطلاق الشاحنة يصبح UNLOADED.
  ManifestItemStatus get scanTarget =>
      manifest?.status == ManifestStatus.inTransit
          ? ManifestItemStatus.unloaded
          : ManifestItemStatus.loaded;

  bool get isUnloadingPhase => scanTarget == ManifestItemStatus.unloaded;

  int get total => items.length;

  int get handled => items.where((item) => item.status == scanTarget).length;

  List<ManifestItem> get pending =>
      items.where((item) => item.status == ManifestItemStatus.pendingLoad)
          .toList();

  int get missing =>
      items.where((item) => item.status == ManifestItemStatus.missing).length;

  double get progress => total == 0 ? 0 : handled / total;

  /// ترتيب العرض: ما لم يُمسح بعد في الأعلى.
  ///
  /// السائق يسأل «ماذا بقي؟» لا «ما ترتيب الطرد في الكشف؟»، فالمتبقّي يجب أن
  /// يكون أمام عينه دون تمرير.
  List<ManifestItem> get itemsForDisplay {
    final ordered = List<ManifestItem>.from(items);
    ordered.sort((a, b) => _rank(a.status).compareTo(_rank(b.status)));
    return ordered;
  }

  int _rank(ManifestItemStatus status) => switch (status) {
        ManifestItemStatus.pendingLoad => 0,
        ManifestItemStatus.missing => 1,
        ManifestItemStatus.loaded => 2,
        ManifestItemStatus.unloaded => 3,
      };

  /// رقم ثابت لكل طرد مبني على ترتيب الخادم، كي لا يتغيّر الرقم المعروض حين
  /// يُعاد ترتيب القائمة بعد كل مسحة.
  int positionOf(ManifestItem item) =>
      items.indexWhere((entry) => entry.id == item.id) + 1;

  ManifestState copyWith({
    Manifest? manifest,
    List<ManifestItem>? items,
    Map<String, Parcel>? parcels,
    bool? isLoading,
    bool? isWorking,
    String? error,
    bool clearError = false,
  }) =>
      ManifestState(
        manifest: manifest ?? this.manifest,
        items: items ?? this.items,
        parcels: parcels ?? this.parcels,
        isLoading: isLoading ?? this.isLoading,
        isWorking: isWorking ?? this.isWorking,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props =>
      [manifest, items, parcels, isLoading, isWorking, error];
}

class ManifestCubit extends Cubit<ManifestState> {
  ManifestCubit({
    required ManifestRepository manifests,
    required ParcelRepository parcels,
    required PendingQueue queue,
    required this.manifestId,
  })  : _manifests = manifests,
        _parcels = parcels,
        _queue = queue,
        super(const ManifestState());

  final ManifestRepository _manifests;
  final ParcelRepository _parcels;
  final PendingQueue _queue;
  final String manifestId;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final manifest = await _manifests.details(manifestId);

      emit(state.copyWith(
        manifest: manifest,
        items: _withPendingApplied(manifest.items),
        parcels: _knownParcelsFor(manifest.items),
        isLoading: false,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(isLoading: false, error: error.message));
    }
  }

  /// الخادم لا يعرف بعدُ بالمسحات المؤجّلة، فلو عرضنا ردّه كما هو لظهرت
  /// مسحات السائق وكأنها لم تحدث. نُلبس المؤجَّل فوق القادم من الخادم.
  List<ManifestItem> _withPendingApplied(List<ManifestItem> items) {
    final pending = _queue.statusesFor(manifestId);
    if (pending.isEmpty) return items;

    return [
      for (final item in items)
        if (pending[item.id] case final wire?)
          item.copyWith(status: ManifestItemStatus.from(wire))
        else
          item,
    ];
  }

  /// يعيد ما نعرفه أصلًا عن طرود هذا المانيفست من مسحات سابقة، فتبقى
  /// الأسماء ظاهرة بعد تحديث الشاشة.
  Map<String, Parcel> _knownParcelsFor(List<ManifestItem> items) {
    final known = <String, Parcel>{};
    for (final item in items) {
      final parcel = _parcels.cachedById(item.parcelId);
      if (parcel != null) known[item.parcelId] = parcel;
    }
    return known;
  }

  /// معالجة رقم تتبع مقروء من الباركود أو مُدخل يدويًّا.
  Future<ScanOutcome> handleScan(String rawTrackingNumber) async {
    final trackingNumber = rawTrackingNumber.trim();
    if (trackingNumber.isEmpty) {
      return const ScanFailed('رقم التتبع فارغ.');
    }

    try {
      final parcel = await _parcels.byTrackingNumber(trackingNumber);

      final item = _itemFor(parcel.id);
      if (item == null) {
        _remember(parcel);
        return ScanNotOnManifest(parcel);
      }

      _remember(parcel);

      final target = state.scanTarget;
      if (item.status == target) {
        return ScanAlreadyDone(parcel, target);
      }

      final queued = await _sendOrQueue(item.id, target);

      _applyLocally(item.id, target);
      return ScanAccepted(parcel, target, queued: queued);
    } on ApiException catch (error) {
      return ScanFailed(error.message);
    }
  }

  /// يرسل التحديث، ويؤجّله إن كانت الشبكة مقطوعة. يعيد true حين يُؤجَّل.
  ///
  /// رفض الخادم لا يُؤجَّل: إعادة إرساله لن تغيّر شيئًا، والأصحّ أن يعرف
  /// السائق بالرفض فورًا.
  Future<bool> _sendOrQueue(String itemId, ManifestItemStatus status) async {
    try {
      await _manifests.updateItemStatus(
        manifestId: manifestId,
        itemId: itemId,
        status: status,
      );
      return false;
    } on ApiException catch (error) {
      if (!error.isNetwork) rethrow;

      await _queue.enqueue(PendingUpdate(
        manifestId: manifestId,
        itemId: itemId,
        status: status.wire,
        createdAt: DateTime.now(),
      ));
      return true;
    }
  }

  /// تأشير طرد بعينه كمفقود.
  Future<bool> markMissing(ManifestItem item) =>
      _setStatus(item, ManifestItemStatus.missing);

  /// تأشير كل ما لم يُمسح كمفقود عند إقفال التحميل.
  Future<bool> markRemainingMissing() async {
    final remaining = state.pending;
    if (remaining.isEmpty) return true;

    emit(state.copyWith(isWorking: true, clearError: true));

    try {
      for (final item in remaining) {
        await _sendOrQueue(item.id, ManifestItemStatus.missing);
        _applyLocally(item.id, ManifestItemStatus.missing);
      }
      emit(state.copyWith(isWorking: false));
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isWorking: false, error: error.message));
      return false;
    }
  }

  Future<bool> completeManifest() async {
    emit(state.copyWith(isWorking: true, clearError: true));

    try {
      await _manifests.complete(manifestId);
      await load();
      emit(state.copyWith(isWorking: false));
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isWorking: false, error: error.message));
      return false;
    }
  }

  Future<bool> _setStatus(ManifestItem item, ManifestItemStatus status) async {
    emit(state.copyWith(isWorking: true, clearError: true));

    try {
      await _sendOrQueue(item.id, status);
      _applyLocally(item.id, status);
      emit(state.copyWith(isWorking: false));
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isWorking: false, error: error.message));
      return false;
    }
  }

  ManifestItem? _itemFor(String parcelId) {
    for (final item in state.items) {
      if (item.parcelId == parcelId) return item;
    }
    return null;
  }

  void _remember(Parcel parcel) {
    emit(state.copyWith(parcels: {...state.parcels, parcel.id: parcel}));
  }

  /// تحديث الحالة محليًّا بعد نجاح الطلب، بدل إعادة تحميل القائمة كاملة بعد
  /// كل مسحة — السائق يمسح عشرات الطرود بالتتابع.
  void _applyLocally(String itemId, ManifestItemStatus status) {
    emit(state.copyWith(
      items: [
        for (final item in state.items)
          if (item.id == itemId) item.copyWith(status: status) else item,
      ],
    ));
  }
}
