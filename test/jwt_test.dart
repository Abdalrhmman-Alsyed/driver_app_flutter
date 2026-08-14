import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:driver_app/core/utils/jwt.dart';

String _token(Map<String, dynamic> payload) {
  String encode(Map<String, dynamic> part) =>
      base64Url.encode(utf8.encode(jsonEncode(part))).replaceAll('=', '');

  return '${encode({'alg': 'HS256'})}.${encode(payload)}.signature';
}

void main() {
  test('يقرأ هوية السائق والمركبة من التوكن', () {
    final payload = JwtPayload.tryParse(_token({
      'sub': 'user-1',
      'profileId': 'employee-602',
      'tenantId': 'tenant-101',
      'vehicleId': 'vehicle-1000',
    }));

    expect(payload, isNotNull);
    // profileId هو معرّف الموظف، وهو ما تُصفّى به الرحلات.
    expect(payload!.driverId, 'employee-602');
    expect(payload.vehicleId, 'vehicle-1000');
    expect(payload.tenantId, 'tenant-101');
  });

  test('السائق بلا مركبة مسندة يبقى جلسة صالحة', () {
    final payload = JwtPayload.tryParse(_token({
      'sub': 'user-1',
      'profileId': 'employee-602',
      'tenantId': 'tenant-101',
    }));

    expect(payload, isNotNull);
    expect(payload!.vehicleId, isNull);
  });

  test('التوكن المشوّه يعطي null لا استثناء', () {
    expect(JwtPayload.tryParse('not-a-token'), isNull);
    expect(JwtPayload.tryParse('a.b.c'), isNull);
    // توكن بلا profileId لا يصلح لتشغيل التطبيق.
    expect(JwtPayload.tryParse(_token({'sub': 'user-1'})), isNull);
  });
}
