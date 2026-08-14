import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/trip.dart';
import '../../data/trip_repository.dart';

class TripsState extends Equatable {
  const TripsState({
    this.trips = const [],
    this.filter,
    this.isLoading = false,
    this.error,
  });

  final List<Trip> trips;
  final TripStatus? filter;
  final bool isLoading;
  final String? error;

  /// الرحلة التي يعمل عليها الآن، إن وُجدت.
  Trip? get activeTrip {
    for (final trip in trips) {
      if (trip.status == TripStatus.inProgress) return trip;
    }
    return null;
  }

  TripsState copyWith({
    List<Trip>? trips,
    TripStatus? filter,
    bool clearFilter = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) =>
      TripsState(
        trips: trips ?? this.trips,
        filter: clearFilter ? null : (filter ?? this.filter),
        isLoading: isLoading ?? this.isLoading,
        error: clearError ? null : (error ?? this.error),
      );

  @override
  List<Object?> get props => [trips, filter, isLoading, error];
}

class TripsCubit extends Cubit<TripsState> {
  TripsCubit({required TripRepository repository, required this.driverId})
      : _repository = repository,
        super(const TripsState());

  final TripRepository _repository;
  final String driverId;

  Future<void> load({TripStatus? filter, bool replaceFilter = false}) async {
    // القائمة تُحدَّث أيضًا عند الرجوع من صفحة التفاصيل، وقد تكون الجلسة
    // انتهت بينها فأُغلق الكيوبت — والإصدار بعد الإغلاق يرمي استثناءً.
    if (isClosed) return;

    final effectiveFilter = replaceFilter ? filter : (filter ?? state.filter);

    emit(state.copyWith(
      isLoading: true,
      clearError: true,
      filter: effectiveFilter,
      clearFilter: replaceFilter && filter == null,
    ));

    try {
      final trips = await _repository.myTrips(
        driverId: driverId,
        status: effectiveFilter,
      );
      if (isClosed) return;
      emit(state.copyWith(trips: trips, isLoading: false));
    } on ApiException catch (error) {
      if (isClosed) return;
      emit(state.copyWith(isLoading: false, error: error.message));
    }
  }

  Future<void> refresh() => load();
}
