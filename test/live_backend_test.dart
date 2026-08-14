@Tags(['live'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:driver_app/core/network/api_client.dart';
import 'package:driver_app/core/storage/token_storage.dart';
import 'package:driver_app/features/auth/data/auth_repository.dart';
import 'package:driver_app/features/manifests/data/manifest_repository.dart';
import 'package:driver_app/features/org_units/data/org_unit_repository.dart';
import 'package:driver_app/features/parcels/data/parcel_repository.dart';
import 'package:driver_app/features/trips/data/trip_repository.dart';
import 'package:driver_app/features/vehicle/data/vehicle_repository.dart';

/// يستبدل المخزن المشفّر بذاكرة عادية: الإضافة الأصلية تحتاج قناة منصّة
/// غير متاحة في بيئة الاختبار.
class _MemoryTokenStorage implements TokenStorage {
  String? _access;
  String? _refresh;
  String? _email;

  @override
  Future<void> save({
    required String accessToken,
    required String refreshToken,
    String? email,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
    _email = email ?? _email;
  }

  @override
  Future<String?> readAccessToken() async => _access;

  @override
  Future<String?> readRefreshToken() async => _refresh;

  @override
  Future<String?> readEmail() async => _email;

  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
    _email = null;
  }
}

/// اختبار يتصل بالخادم الحقيقي، فيتحقّق من العقود لا من المنطق وحده.
/// يُشغَّل بـ: flutter test --tags live
void main() {
  late ApiClient api;
  late _MemoryTokenStorage storage;

  setUp(() {
    storage = _MemoryTokenStorage();
    api = ApiClient(tokenStorage: storage);
  });

  test('التدفّق كاملًا من الدخول إلى بيانات الطرد', () async {
    final auth = AuthRepository(api: api, storage: storage);

    final session = await auth.login(
      email: 'driver@fastship.com',
      password: 'password123',
    );

    // إرسال type: DRIVER يتخطّى اختيار البروفايل ويعيد التوكن مباشرة.
    expect(session.driverId, isNotEmpty);
    expect(session.tenantId, isNotEmpty);
    // معرّف المركبة داخل التوكن، فلا نحتاج طلبًا لمعرفته.
    expect(session.vehicleId, isNotNull);

    final orgUnits = OrgUnitRepository(api);
    await orgUnits.preload();
    expect(orgUnits.isLoaded, isTrue);

    final trips = await TripRepository(api).myTrips(
      driverId: session.driverId,
    );
    // التصفية بـ driverId إلزامية: الخادم يعيد رحلات كل السائقين بدونها.
    expect(
      trips.every((trip) => trip.driverId == session.driverId),
      isTrue,
      reason: 'ظهرت رحلة لا تخص هذا السائق',
    );

    final vehicle = await VehicleRepository(api).details(session.vehicleId!);
    expect(vehicle.plateNumber, isNotEmpty);

    if (trips.isNotEmpty) {
      final manifests = await ManifestRepository(api).forTrip(trips.first.id);
      for (final manifest in manifests) {
        expect(manifest.tripId, trips.first.id);
      }
    }

    final parcel =
        await ParcelRepository(api).byTrackingNumber('TRK-2026-0002');
    // الحقول الخمسة التي تعتمد عليها شاشة كشف الحمولة.
    expect(parcel.trackingNumber, 'TRK-2026-0002');
    expect(parcel.actualWeightKg, greaterThan(0));
    expect(parcel.isFragile, isNotNull);
  }, timeout: const Timeout(Duration(seconds: 90)));
}
