import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/vehicle_result.dart';

enum _DatasetKind { offRoad, active, inactive }

class _Dataset {
  const _Dataset(this.resourceId, this.kind, {this.textPlate = false});

  final String resourceId;
  final _DatasetKind kind;

  /// Older datasets store the plate as zero-padded 8-character text
  /// ("03602428"); filtering those with a number fails with HTTP 404.
  final bool textPlate;

  Object filterValue(int plate) =>
      textPlate ? plate.toString().padLeft(8, '0') : plate;
}

class LookupException implements Exception {
  LookupException(this.message);

  final String message;

  @override
  String toString() => 'LookupException: $message';
}

/// Looks plates up in the Ministry of Transport datasets on data.gov.il
/// (free CKAN API, no key required).
class VehicleLookupService {
  VehicleLookupService({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
    this.cacheTtl = const Duration(hours: 12),
    DateTime Function()? clock,
  }) : _client = client ?? http.Client(),
       _clock = clock ?? DateTime.now;

  static final _endpoint = Uri.parse(
    'https://data.gov.il/api/3/action/datastore_search',
  );

  // Checked on every lookup.
  static const _primary = [
    _Dataset(
      '053cea08-09bc-40ec-8f7a-156f0677aff3',
      _DatasetKind.active,
    ), // private & commercial
    _Dataset(
      '851ecab1-0622-4dbe-a6c7-f950cf82abf9',
      _DatasetKind.offRoad,
    ), // final cancellation
    _Dataset(
      '4e6b9724-4c1e-43f0-909a-154d4cc4e046',
      _DatasetKind.offRoad,
      textPlate: true,
    ), // ... 2010-2016
    _Dataset(
      'ec8cbc34-72e1-4b69-9c48-22821ba0bd6c',
      _DatasetKind.offRoad,
      textPlate: true,
    ), // ... 2000-2009
  ];

  // Checked only when the plate is in none of the primary datasets.
  static const _secondary = [
    _Dataset(
      'f6efe89a-fb3d-43a4-bb61-9bf12a9b9099',
      _DatasetKind.inactive,
    ), // with model code
    _Dataset(
      '6f6acd03-f351-4a8f-8ecf-df792f4f573a',
      _DatasetKind.inactive,
    ), // without model code
    _Dataset(
      'bf9df4e2-d90d-4c0a-a400-19e15af8e95f',
      _DatasetKind.active,
    ), // two-wheelers
    _Dataset(
      'cd3acc5c-03c3-4c89-9c54-d40f93c0d790',
      _DatasetKind.active,
    ), // over 3.5 tons
  ];

  final http.Client _client;
  final DateTime Function() _clock;
  final Duration timeout;
  final Duration cacheTtl;
  final _cache = <String, VehicleResult>{};

  /// [plate] is digits only. Never throws: failures yield [PlateStatus.error].
  /// [refresh] bypasses the cache.
  Future<VehicleResult> lookup(String plate, {bool refresh = false}) async {
    final cached = refresh ? null : _cache[plate];
    if (cached != null && _clock().difference(cached.checkedAt) < cacheTtl) {
      return cached;
    }

    final number = int.tryParse(plate);
    if (number == null) return _result(plate, PlateStatus.error);

    var failed = false;
    Future<Map<String, dynamic>?> query(_Dataset d) async {
      try {
        return await _query(d, number);
      } catch (_) {
        failed = true;
        return null;
      }
    }

    final found = <_DatasetKind, VehicleInfo>{};
    Future<void> collect(List<_Dataset> datasets) async {
      final records = await Future.wait(datasets.map(query));
      for (var i = 0; i < datasets.length; i++) {
        final record = records[i];
        if (record == null) continue;
        final info = VehicleInfo.fromRecord(record);
        final kind = datasets[i].kind;
        found[kind] = found[kind]?.mergedWith(info) ?? info;
      }
    }

    await collect(_primary);
    if (found.isEmpty) await collect(_secondary);

    if (found[_DatasetKind.offRoad] case final offRoad?) {
      final active = found[_DatasetKind.active];
      return _result(
        plate,
        PlateStatus.offRoad,
        active == null ? offRoad : offRoad.mergedWith(active),
      );
    }
    if (found[_DatasetKind.active] case final active?) {
      final expired = _isExpired(active.licenseValidUntil);
      return _result(
        plate,
        expired ? PlateStatus.licenseExpired : PlateStatus.active,
        active,
      );
    }
    if (found[_DatasetKind.inactive] case final inactive?) {
      return _result(plate, PlateStatus.inactive, inactive);
    }
    // "Not found" is only trustworthy when every query succeeded.
    return _result(plate, failed ? PlateStatus.error : PlateStatus.notFound);
  }

  VehicleResult _result(String plate, PlateStatus status, [VehicleInfo? info]) {
    final result = VehicleResult(
      plate: plate,
      status: status,
      info: info,
      checkedAt: _clock(),
    );
    if (status != PlateStatus.error) _cache[plate] = result;
    return result;
  }

  bool _isExpired(String? validUntil) {
    final date = validUntil == null ? null : DateTime.tryParse(validUntil);
    if (date == null) return false;
    final now = _clock();
    return date.isBefore(DateTime(now.year, now.month, now.day));
  }

  Future<Map<String, dynamic>?> _query(_Dataset dataset, int plate) async {
    final resourceId = dataset.resourceId;
    final uri = _endpoint.replace(
      queryParameters: {
        'resource_id': resourceId,
        'filters': jsonEncode({'mispar_rechev': dataset.filterValue(plate)}),
        'limit': '1',
      },
    );
    final response = await _client
        .get(uri, headers: const {'User-Agent': 'PlateScan/1.0'})
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw LookupException('HTTP ${response.statusCode} for $resourceId');
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map<String, dynamic> || body['success'] != true) {
      throw LookupException('Unexpected response for $resourceId');
    }
    final records = (body['result'] as Map<String, dynamic>)['records'] as List;
    return records.isEmpty ? null : records.first as Map<String, dynamic>;
  }

  void dispose() => _client.close();
}
