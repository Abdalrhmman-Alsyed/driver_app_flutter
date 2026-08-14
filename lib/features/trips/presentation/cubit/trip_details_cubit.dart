import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../../manifests/data/manifest_repository.dart';
import '../../../manifests/data/models/manifest.dart';
import '../../data/models/trip.dart';
import '../../data/trip_repository.dart';

class TripDetailsState extends Equatable {
  const TripDetailsState({
    this.trip,
    this.manifests = const [],
    this.isLoading = true,
    this.isWorking = false,
    this.error,
  });

  final Trip? trip;
  final List<Manifest> manifests;
  final bool isLoading;

  /// إجراء جارٍ (بدء أو إنهاء) — لتعطيل الأزرار ومنع الضغط المزدوج.
  final bool isWorking;
  final String? error;

  /// الخادم يرفض بدء رحلة بلا مانيفست، فنمنع الضغط بدل انتظار الخطأ.
  bool get canStart => (trip?.canStart ?? false) && manifests.isNotEmpty;

  bool get startBlockedByMissingManifest =>
      (trip?.canStart ?? false) && manifests.isEmpty;

  TripDetailsState copyWith({
    Trip? trip,
    List<Manifest>? manifests,
    bool? isLoading,
    bool? isWorking,
    String? error,
    bool clearError = false,
  }) =>
      TripDetailsState(
        trip: trip ?? this.trip,
        manifests: manifests ?? this.manifests,
        isLoading: isLoading ?? this.isLoading,
        isWorking: isWorking ?? this.isWorking,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [trip, manifests, isLoading, isWorking, error];
}

class TripDetailsCubit extends Cubit<TripDetailsState> {
  TripDetailsCubit({
    required TripRepository trips,
    required ManifestRepository manifests,
    required this.tripId,
  })  : _trips = trips,
        _manifests = manifests,
        super(const TripDetailsState());

  final TripRepository _trips;
  final ManifestRepository _manifests;
  final String tripId;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      // الطلبان مستقلّان، فلا داعي لانتظار الأول قبل بدء الثاني.
      final results = await Future.wait([
        _trips.details(tripId),
        _manifests.forTrip(tripId),
      ]);

      emit(state.copyWith(
        trip: results[0] as Trip,
        manifests: results[1] as List<Manifest>,
        isLoading: false,
      ));
    } on ApiException catch (error) {
      emit(state.copyWith(isLoading: false, error: error.message));
    }
  }

  Future<bool> start() => _run(() => _trips.start(tripId));

  Future<bool> complete() => _run(() => _trips.complete(tripId));

  Future<bool> _run(Future<void> Function() action) async {
    emit(state.copyWith(isWorking: true, clearError: true));

    try {
      await action();
      await load();
      emit(state.copyWith(isWorking: false));
      return true;
    } on ApiException catch (error) {
      emit(state.copyWith(isWorking: false, error: error.message));
      return false;
    }
  }
}
