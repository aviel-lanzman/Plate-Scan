import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/vehicle_result.dart';

/// Scan history, kept on the device only.
class HistoryStore {
  static const _key = 'history_v1';

  /// Holds the raw stored value when it could not be read in full, so the
  /// next save does not destroy it. The latest unreadable value wins.
  static const _backupKey = 'history_v1_unreadable';
  static const maxEntries = 200;

  /// Read-modify-write steps run one after another. The app shares a single
  /// store (see AppServices), so the queue belongs to the instance.
  Future<void> _queue = Future.value();

  Future<T> _serialised<T>(Future<T> Function() action) {
    final run = _queue.then((_) => action());
    _queue = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  /// Entries that cannot be read are skipped; the rest are returned.
  Future<List<VehicleResult>> load() => _serialised(_read);

  Future<List<VehicleResult>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on Object {
      await prefs.setString(_backupKey, raw);
      return [];
    }
    if (decoded is! List) {
      await prefs.setString(_backupKey, raw);
      return [];
    }
    final entries = <VehicleResult>[];
    var skipped = false;
    for (final e in decoded) {
      try {
        entries.add(VehicleResult.fromJson(e as Map<String, dynamic>));
      } on Object {
        skipped = true;
      }
    }
    // Skipped entries may come from a newer version of the app.
    if (skipped) await prefs.setString(_backupKey, raw);
    return entries;
  }

  /// Adds [result] as the newest entry, replacing an older entry for the
  /// same plate. History is a convenience, so a storage failure is logged
  /// rather than allowed to break the check that produced [result].
  Future<void> add(VehicleResult result) => _serialised(() async {
    try {
      final entries = await _read()
        ..removeWhere((e) => e.plate == result.plate)
        ..insert(0, result);
      await _save(entries.take(maxEntries).toList());
    } on Object catch (e) {
      debugPrint('HistoryStore: could not save an entry: $e');
    }
  });

  Future<void> clear() => _serialised(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_backupKey);
  });

  Future<void> _save(List<VehicleResult> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode([for (final e in entries) e.toJson()]),
    );
  }
}
