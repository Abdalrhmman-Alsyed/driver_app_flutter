import 'package:flutter_test/flutter_test.dart';

import 'package:driver_app/core/network/api_exception.dart';
import 'package:driver_app/core/sync/pending_queue.dart';
import 'package:driver_app/core/sync/pending_update.dart';
import 'package:driver_app/features/manifests/data/manifest_repository.dart';
import 'package:driver_app/features/manifests/data/models/manifest.dart';
import 'package:driver_app/features/manifests/presentation/cubit/manifest_cubit.dart';
import 'package:driver_app/features/parcels/data/models/parcel.dart';
import 'package:driver_app/features/parcels/data/parcel_repository.dart';

class _FakeManifestRepository implements ManifestRepository {
  _FakeManifestRepository(this.manifest);

  Manifest manifest;
  final List<({String itemId, ManifestItemStatus status})> updates = [];
  bool completed = false;

  /// خطأ يُرمى بدل تنفيذ التحديث، لمحاكاة انقطاع الشبكة أو رفض الخادم.
  ApiException? failure;

  @override
  Future<Manifest> details(String manifestId) async => manifest;

  @override
  Future<void> updateItemStatus({
    required String manifestId,
    required String itemId,
    required ManifestItemStatus status,
  }) async {
    if (failure != null) throw failure!;
    updates.add((itemId: itemId, status: status));
  }

  @override
  Future<void> complete(String manifestId) async => completed = true;

  @override
  Future<List<ManifestItem>> items(String manifestId) async => manifest.items;

  @override
  Future<List<Manifest>> forTrip(String tripId) async => [manifest];
}

class _FakeParcelRepository implements ParcelRepository {
  _FakeParcelRepository(this.byTracking);

  final Map<String, Parcel> byTracking;

  @override
  Parcel? cachedById(String parcelId) => null;

  @override
  Future<Parcel> byTrackingNumber(String trackingNumber) async {
    final parcel = byTracking[trackingNumber];
    if (parcel == null) throw const ApiException('غير موجود.');
    return parcel;
  }
}

const _onTruck = Parcel(
  id: 'parcel-1',
  trackingNumber: 'TRK-1',
  actualWeightKg: 5,
  isFragile: false,
);

const _elsewhere = Parcel(
  id: 'parcel-99',
  trackingNumber: 'TRK-99',
  actualWeightKg: 2,
  isFragile: false,
);

Manifest _manifest({
  required ManifestStatus status,
  required ManifestItemStatus itemStatus,
}) =>
    Manifest(
      id: 'manifest-1',
      tripId: 'trip-1',
      originOrgUnitId: 'unit-a',
      destinationOrgUnitId: 'unit-b',
      status: status,
      items: [
        ManifestItem(
          id: 'item-1',
          manifestId: 'manifest-1',
          parcelId: 'parcel-1',
          status: itemStatus,
        ),
      ],
    );

/// طابور بلا تخزين: [PendingQueue.load] هي ما يربطه بالقرص، وتركها يجعله
/// يعمل في الذاكرة وحدها.
PendingQueue _queue() => PendingQueue();

ManifestCubit _cubit(
  _FakeManifestRepository manifests, {
  _FakeParcelRepository? parcels,
  PendingQueue? queue,
}) =>
    ManifestCubit(
      manifests: manifests,
      parcels: parcels ??
          _FakeParcelRepository({
            'TRK-1': _onTruck,
            'TRK-99': _elsewhere,
          }),
      queue: queue ?? _queue(),
      manifestId: 'manifest-1',
    );

void main() {
  group('طور المسح مشتق من حالة الكشف', () {
    test('الكشف قيد التحميل يجعل هدف المسح "محمّل"', () async {
      final repo = _FakeManifestRepository(_manifest(
        status: ManifestStatus.pending,
        itemStatus: ManifestItemStatus.pendingLoad,
      ));
      final cubit = _cubit(repo);

      await cubit.load();

      expect(cubit.state.scanTarget, ManifestItemStatus.loaded);
      expect(cubit.state.isUnloadingPhase, isFalse);
    });

    test('الكشف في الطريق يجعل هدف المسح "مُفرّغ"', () async {
      final repo = _FakeManifestRepository(_manifest(
        status: ManifestStatus.inTransit,
        itemStatus: ManifestItemStatus.loaded,
      ));
      final cubit = _cubit(repo);

      await cubit.load();

      expect(cubit.state.scanTarget, ManifestItemStatus.unloaded);
      expect(cubit.state.isUnloadingPhase, isTrue);
    });
  });

  group('المسح', () {
    test('طرد على الكشف يُقبل ويُحدَّث محليًّا', () async {
      final repo = _FakeManifestRepository(_manifest(
        status: ManifestStatus.pending,
        itemStatus: ManifestItemStatus.pendingLoad,
      ));
      final cubit = _cubit(repo);
      await cubit.load();

      final outcome = await cubit.handleScan('TRK-1');

      expect(outcome, isA<ScanAccepted>());
      expect(repo.updates.single.status, ManifestItemStatus.loaded);
      // التحديث محلي بلا إعادة تحميل: السائق يمسح عشرات الطرود بالتتابع.
      expect(cubit.state.items.single.status, ManifestItemStatus.loaded);
      expect(cubit.state.handled, 1);
    });

    test('طرد ليس على الكشف يُرفض ولا يُرسل أي تحديث', () async {
      final repo = _FakeManifestRepository(_manifest(
        status: ManifestStatus.pending,
        itemStatus: ManifestItemStatus.pendingLoad,
      ));
      final cubit = _cubit(repo);
      await cubit.load();

      final outcome = await cubit.handleScan('TRK-99');

      expect(outcome, isA<ScanNotOnManifest>());
      expect(repo.updates, isEmpty);
      expect(cubit.state.items.single.status, ManifestItemStatus.pendingLoad);
    });

    test('إعادة مسح الطرد نفسه لا تكرّر الطلب', () async {
      final repo = _FakeManifestRepository(_manifest(
        status: ManifestStatus.pending,
        itemStatus: ManifestItemStatus.loaded,
      ));
      final cubit = _cubit(repo);
      await cubit.load();

      final outcome = await cubit.handleScan('TRK-1');

      expect(outcome, isA<ScanAlreadyDone>());
      expect(repo.updates, isEmpty);
    });

    test('رقم تتبع مجهول يعطي فشلًا مقروءًا لا استثناء', () async {
      final repo = _FakeManifestRepository(_manifest(
        status: ManifestStatus.pending,
        itemStatus: ManifestItemStatus.pendingLoad,
      ));
      final cubit = _cubit(repo, parcels: _FakeParcelRepository(const {}));
      await cubit.load();

      final outcome = await cubit.handleScan('TRK-UNKNOWN');

      expect(outcome, isA<ScanFailed>());
    });
  });

  test('تأشير المتبقّي كمفقود يشمل غير الممسوح وحده', () async {
    final repo = _FakeManifestRepository(Manifest(
      id: 'manifest-1',
      tripId: 'trip-1',
      originOrgUnitId: 'unit-a',
      destinationOrgUnitId: 'unit-b',
      status: ManifestStatus.pending,
      items: const [
        ManifestItem(
          id: 'item-1',
          manifestId: 'manifest-1',
          parcelId: 'parcel-1',
          status: ManifestItemStatus.loaded,
        ),
        ManifestItem(
          id: 'item-2',
          manifestId: 'manifest-1',
          parcelId: 'parcel-2',
          status: ManifestItemStatus.pendingLoad,
        ),
      ],
    ));
    final cubit = _cubit(repo);
    await cubit.load();

    await cubit.markRemainingMissing();

    expect(repo.updates.single.itemId, 'item-2');
    expect(repo.updates.single.status, ManifestItemStatus.missing);
    expect(cubit.state.missing, 1);
  });

  group('انقطاع الشبكة', () {
    Manifest twoPending() => Manifest(
          id: 'manifest-1',
          tripId: 'trip-1',
          originOrgUnitId: 'unit-a',
          destinationOrgUnitId: 'unit-b',
          status: ManifestStatus.pending,
          items: const [
            ManifestItem(
              id: 'item-1',
              manifestId: 'manifest-1',
              parcelId: 'parcel-1',
              status: ManifestItemStatus.pendingLoad,
            ),
          ],
        );

    test('المسحة تُحفظ في الطابور ولا تضيع', () async {
      final repo = _FakeManifestRepository(twoPending())
        ..failure = const ApiException('لا شبكة', isNetwork: true);
      final queue = _queue();
      final cubit = _cubit(repo, queue: queue);
      await cubit.load();

      final outcome = await cubit.handleScan('TRK-1');

      expect(outcome, isA<ScanAccepted>());
      expect((outcome as ScanAccepted).queued, isTrue);
      // السائق يرى طرده محمّلًا رغم انقطاع الشبكة.
      expect(cubit.state.items.single.status, ManifestItemStatus.loaded);
      expect(queue.length, 1);
      expect(queue.updates.single.itemId, 'item-1');
    });

    test('رفض الخادم لا يدخل الطابور', () async {
      final repo = _FakeManifestRepository(twoPending())
        ..failure = const ApiException('ممنوع', statusCode: 403);
      final queue = _queue();
      final cubit = _cubit(repo, queue: queue);
      await cubit.load();

      final outcome = await cubit.handleScan('TRK-1');

      expect(outcome, isA<ScanFailed>());
      // إعادة إرسال ما رفضه الخادم لن تنجح مهما تكرّرت.
      expect(queue.isEmpty, isTrue);
      expect(cubit.state.items.single.status, ManifestItemStatus.pendingLoad);
    });

    test('المؤجَّل يبقى ظاهرًا بعد إعادة التحميل من الخادم', () async {
      final repo = _FakeManifestRepository(twoPending())
        ..failure = const ApiException('لا شبكة', isNetwork: true);
      final queue = _queue();
      final cubit = _cubit(repo, queue: queue);
      await cubit.load();
      await cubit.handleScan('TRK-1');

      // الخادم ما زال يجهل المسحة ويعيد الحالة القديمة.
      await cubit.load();

      expect(cubit.state.items.single.status, ManifestItemStatus.loaded);
    });

    test('آخر حالة للطرد الواحد هي ما يبقى في الطابور', () async {
      final queue = _queue();

      await queue.enqueue(PendingUpdate(
        manifestId: 'm',
        itemId: 'i',
        status: 'LOADED',
        createdAt: DateTime.now(),
      ));
      await queue.enqueue(PendingUpdate(
        manifestId: 'm',
        itemId: 'i',
        status: 'MISSING',
        createdAt: DateTime.now(),
      ));

      expect(queue.length, 1);
      expect(queue.updates.single.status, 'MISSING');
    });
  });

  test('العرض يرفع غير الممسوح إلى الأعلى ويثبّت أرقام الطرود', () async {
    final repo = _FakeManifestRepository(Manifest(
      id: 'manifest-1',
      tripId: 'trip-1',
      originOrgUnitId: 'unit-a',
      destinationOrgUnitId: 'unit-b',
      status: ManifestStatus.pending,
      items: const [
        ManifestItem(
          id: 'item-1',
          manifestId: 'manifest-1',
          parcelId: 'parcel-1',
          status: ManifestItemStatus.loaded,
        ),
        ManifestItem(
          id: 'item-2',
          manifestId: 'manifest-1',
          parcelId: 'parcel-2',
          status: ManifestItemStatus.pendingLoad,
        ),
      ],
    ));
    final cubit = _cubit(repo);
    await cubit.load();

    final display = cubit.state.itemsForDisplay;

    expect(display.first.id, 'item-2', reason: 'المتبقّي أولًا');
    // الرقم يتبع ترتيب الخادم لا ترتيب العرض، وإلا تغيّر رقم الطرد بعد كل مسحة.
    expect(cubit.state.positionOf(display.first), 2);
    expect(cubit.state.positionOf(display.last), 1);
  });
}
