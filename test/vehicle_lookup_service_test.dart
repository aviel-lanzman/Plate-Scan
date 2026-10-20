import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:plate_scan/models/vehicle_result.dart';
import 'package:plate_scan/services/vehicle_lookup_service.dart';

const _active = '053cea08-09bc-40ec-8f7a-156f0677aff3';
const _offRoad = '851ecab1-0622-4dbe-a6c7-f950cf82abf9';
const _offRoadOld = 'ec8cbc34-72e1-4b69-9c48-22821ba0bd6c';
const _inactive = 'f6efe89a-fb3d-43a4-bb61-9bf12a9b9099';
const _textPlateDatasets = {
  '4e6b9724-4c1e-43f0-909a-154d4cc4e046',
  _offRoadOld,
};

http.Response _records(List<Map<String, dynamic>> records) =>
    http.Response.bytes(
      utf8.encode(
        jsonEncode({
          'success': true,
          'result': {'records': records},
        }),
      ),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

/// Serves [data] keyed by resource id; every other dataset is empty.
MockClient _client(
  Map<String, Map<String, dynamic>> data, {
  Set<String> failing = const {},
  List<Uri>? log,
}) {
  return MockClient((request) async {
    log?.add(request.url);
    final id = request.url.queryParameters['resource_id']!;
    if (failing.contains(id)) return http.Response('boom', 500);
    final filters = jsonDecode(request.url.queryParameters['filters']!) as Map;
    final value = filters['mispar_rechev'];
    if (_textPlateDatasets.contains(id)) {
      expect(value, isA<String>());
      expect((value as String).length, 8);
    } else {
      expect(value, isA<int>());
    }
    final record = data[id];
    return _records(record == null ? [] : [record]);
  });
}

final _now = DateTime(2026, 10, 20, 12);

VehicleLookupService _service(MockClient client) =>
    VehicleLookupService(client: client, clock: () => _now);

void main() {
  test('off-road wins and merges details', () async {
    final service = _service(
      _client({
        _offRoad: {
          'mispar_rechev': 7735636,
          'tozeret_nm': 'סיאט ספרד',
          'kinuy_mishari': 'TOLEDO',
          'tzeva_rechev': 'כחול פנינה',
          'shnat_yitzur': 2002,
          'bitul_dt': '2026-10-15',
        },
      }),
    );
    final r = await service.lookup('7735636');
    expect(r.status, PlateStatus.offRoad);
    expect(r.info!.cancelledOn, '2026-10-15');
    expect(r.info!.summary, 'סיאט ספרד TOLEDO, כחול פנינה, 2002');
  });

  test('older off-road datasets are queried with zero-padded text', () async {
    final log = <Uri>[];
    final service = _service(
      _client({
        _offRoadOld: {
          'mispar_rechev': '03602428',
          'bitul_dt': '2005-01-01',
          'shnat_yitzur': '1997', // text in the older datasets
          'tzeva_rechev': ' לא ידוע',
        },
      }, log: log),
    );
    final r = await service.lookup('3602428');
    expect(r.status, PlateStatus.offRoad);
    expect(r.info!.year, 1997);
    expect(r.info!.color, 'לא ידוע');
    final oldQuery = log.firstWhere(
      (u) => u.queryParameters['resource_id'] == _offRoadOld,
    );
    expect(oldQuery.queryParameters['filters'], '{"mispar_rechev":"03602428"}');
  });

  test('active vehicle with valid licence', () async {
    final log = <Uri>[];
    final service = _service(
      _client({
        _active: {
          'mispar_rechev': 23070803,
          'tozeret_nm': "פיג'ו צרפת",
          'kinuy_mishari': '3008',
          'tzeva_rechev': 'שנהב לבן',
          'shnat_yitzur': 2023,
          'tokef_dt': '2027-03-12',
        },
      }, log: log),
    );
    final r = await service.lookup('23070803');
    expect(r.status, PlateStatus.active);
    expect(r.info!.model, '3008');
    // Found in the primary datasets, so secondary ones are skipped.
    expect(log, hasLength(4));
  });

  test('active vehicle with expired licence', () async {
    final service = _service(
      _client({
        _active: {'mispar_rechev': 1234567, 'tokef_dt': '2026-10-19'},
      }),
    );
    expect(
      (await service.lookup('1234567')).status,
      PlateStatus.licenseExpired,
    );
  });

  test('licence expiring today is still valid', () async {
    final service = _service(
      _client({
        _active: {'mispar_rechev': 1234567, 'tokef_dt': '2026-10-20'},
      }),
    );
    expect((await service.lookup('1234567')).status, PlateStatus.active);
  });

  test('inactive vehicle from secondary datasets', () async {
    final log = <Uri>[];
    final service = _service(
      _client({
        _inactive: {'mispar_rechev': 1234567, 'degem_nm': 'X1'},
      }, log: log),
    );
    final r = await service.lookup('1234567');
    expect(r.status, PlateStatus.inactive);
    expect(r.info!.model, 'X1');
    expect(log, hasLength(8));
  });

  test('not found anywhere', () async {
    final service = _service(_client({}));
    expect((await service.lookup('1234567')).status, PlateStatus.notFound);
  });

  test('a failed query turns "not found" into an error', () async {
    final service = _service(_client({}, failing: {_offRoad}));
    expect((await service.lookup('1234567')).status, PlateStatus.error);
  });

  test('a failed query does not hide a match elsewhere', () async {
    final service = _service(
      _client(
        {
          _active: {'mispar_rechev': 1234567, 'tokef_dt': '2027-01-01'},
        },
        failing: {_offRoadOld},
      ),
    );
    expect((await service.lookup('1234567')).status, PlateStatus.active);
  });

  test('timeouts become errors', () async {
    final service = VehicleLookupService(
      client: MockClient((_) => Completer<http.Response>().future),
      timeout: const Duration(milliseconds: 10),
      clock: () => _now,
    );
    expect((await service.lookup('1234567')).status, PlateStatus.error);
  });

  test('non-numeric input is an error without any request', () async {
    final log = <Uri>[];
    final service = _service(_client({}, log: log));
    expect((await service.lookup('12a')).status, PlateStatus.error);
    expect(log, isEmpty);
  });

  test('results are cached, errors are not, refresh bypasses', () async {
    final log = <Uri>[];
    final service = _service(_client({}, log: log));
    await service.lookup('1234567');
    await service.lookup('1234567');
    expect(log, hasLength(8));
    await service.lookup('1234567', refresh: true);
    expect(log, hasLength(16));

    final failingLog = <Uri>[];
    final failing = _service(_client({}, failing: {_active}, log: failingLog));
    await failing.lookup('1234567');
    await failing.lookup('1234567');
    expect(failingLog, hasLength(16));
  });

  test('VehicleResult survives a JSON round trip', () {
    final r = VehicleResult(
      plate: '1234567',
      status: PlateStatus.offRoad,
      checkedAt: _now,
      info: const VehicleInfo(
        manufacturer: 'A',
        year: 2000,
        cancelledOn: '2020-01-01',
      ),
    ).withStolenCheck(StolenCheckOutcome.clean);
    final back = VehicleResult.fromJson(
      jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>,
    );
    expect(back.plate, r.plate);
    expect(back.status, r.status);
    expect(back.checkedAt, r.checkedAt);
    expect(back.stolenCheck, StolenCheckOutcome.clean);
    expect(back.info!.summary, 'A, 2000');
    expect(back.info!.cancelledOn, '2020-01-01');
  });
}
