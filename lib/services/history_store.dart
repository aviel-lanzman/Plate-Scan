import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicle_result.dart';

/// Scan history, kept on the device only.
class HistoryStore {
  static const _key = 'history_v1';
  static const maxEntries = 200;

  Future<List<VehicleResult>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return [
        for (final e in jsonDecode(raw) as List)
          VehicleResult.fromJson(e as Map<String, dynamic>),
      ];
    } on Object {
      // A corrupt entry should not lock the user out of the app.
      return [];
    }
  }

  /// Adds [result] as the newest entry, replacing an older entry for the
  /// same plate. History is a convenience, so a storage failure is logged
  /// rather than allowed to break the check that produced [result].
  Future<void> add(VehicleResult result) async {
    try {
      final entries = await load()
        ..removeWhere((e) => e.plate == result.plate)
        ..insert(0, result);
      await _save(entries.take(maxEntries).toList());
    } on Object catch (e) {
      debugPrint('HistoryStore: could not save ${result.plate}: $e');
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> _save(List<VehicleResult> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final e in entries) e.toJson()]),
    );
  }
}
