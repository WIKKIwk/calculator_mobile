import 'package:hive_ce/hive.dart';

import 'device_local_key_service.dart';

/// Ilova ma'lumotlari (jurnal; offline loyihada kutilayotgan server partiyalari ishlatilmaydi).
/// Qurilmada AES (HiveAesCipher) bilan shifrlangan; kalit Secure Storage da.
class AppLocalStore {
  AppLocalStore._();

  static const _boxName = 'calculator_offline_app_local';
  static const _pendingKey = 'pending_record_batches';
  static const _eventsKey = 'app_events';

  static Box<dynamic>? _box;

  static Future<void> init() async {
    final key = await DeviceLocalKeyService.getOrCreateHiveEncryptionKey();
    final cipher = HiveAesCipher(key);

    final exists = await Hive.boxExists(_boxName);
    if (!exists) {
      _box = await Hive.openBox<dynamic>(
        _boxName,
        encryptionCipher: cipher,
      );
      return;
    }

    try {
      _box = await Hive.openBox<dynamic>(
        _boxName,
        encryptionCipher: cipher,
      );
      return;
    } catch (_) {
      // Eski ochiq (shifrsiz) quti bo'lishi mumkin — bir marta ko'chiramiz.
    }

    Box<dynamic> plain;
    try {
      plain = await Hive.openBox<dynamic>(_boxName);
    } catch (e) {
      await Hive.deleteBoxFromDisk(_boxName);
      _box = await Hive.openBox<dynamic>(
        _boxName,
        encryptionCipher: cipher,
      );
      return;
    }

    final pending = plain.get(_pendingKey);
    final events = plain.get(_eventsKey);
    await plain.close();
    await Hive.deleteBoxFromDisk(_boxName);

    _box = await Hive.openBox<dynamic>(
      _boxName,
      encryptionCipher: cipher,
    );
    if (pending != null) {
      await _box!.put(_pendingKey, _deep(pending));
    }
    if (events != null) {
      await _box!.put(_eventsKey, _deep(events));
    }
  }

  static Box<dynamic> get _b {
    final b = _box;
    if (b == null) {
      throw StateError('AppLocalStore.init() chaqirilmagan');
    }
    return b;
  }

  static dynamic _deep(dynamic v) {
    if (v is Map) {
      return {for (final e in v.entries) e.key.toString(): _deep(e.value)};
    }
    if (v is List) {
      return v.map(_deep).toList();
    }
    return v;
  }

  static List<Map<String, dynamic>> _readListMap(String key) {
    final raw = _b.get(key);
    if (raw == null) return [];
    if (raw is! List) return [];
    return raw
        .map((e) => Map<String, dynamic>.from(_deep(e) as Map))
        .toList();
  }

  static Future<void> _writeListMap(String key, List<Map<String, dynamic>> list) async {
    await _b.put(key, _deep(list));
  }

  // --- Kutilayotgan kalkulyatsiya partiyalari (serverga yuborish uchun) ---

  static List<Map<String, dynamic>> pendingRecordBatches() =>
      _readListMap(_pendingKey);

  /// [lines] — har bir qator: productId, quantity, name, price, createdAt (mahsulotdan nusxa).
  static Future<void> addPendingRecordBatch({
    required String userId,
    required Map<String, dynamic> userSnapshot,
    required List<Map<String, dynamic>> lines,
  }) async {
    final id = 'pending_${DateTime.now().microsecondsSinceEpoch}';
    final list = pendingRecordBatches();
    list.add({
      'id': id,
      'userId': userId,
      'user': userSnapshot,
      'lines': lines,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
    await _writeListMap(_pendingKey, list);
  }

  static Future<void> removePendingRecordBatch(String id) async {
    final list = pendingRecordBatches().where((e) => e['id'] != id).toList();
    await _writeListMap(_pendingKey, list);
  }

  // --- Ilova o'zi yig'adigan sodda jurnal ---

  static List<Map<String, dynamic>> recentEvents({int max = 100}) {
    final all = _readListMap(_eventsKey);
    if (all.length <= max) return List.from(all.reversed);
    return List.from(all.sublist(all.length - max).reversed);
  }

  static Future<void> logEvent(String type, [String? detail]) async {
    final list = _readListMap(_eventsKey);
    list.add({
      't': DateTime.now().toUtc().toIso8601String(),
      'type': type,
      if (detail != null && detail.isNotEmpty) 'detail': detail,
    });
    const cap = 500;
    if (list.length > cap) {
      list.removeRange(0, list.length - cap);
    }
    await _writeListMap(_eventsKey, list);
  }

  /// Zaxira faylida saqlanadigan to'liq (jurnal limitisiz) nusxa.
  static Future<Map<String, dynamic>> snapshotForBackup() async {
    return {
      'v': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      _pendingKey: pendingRecordBatches(),
      _eventsKey: _readListMap(_eventsKey),
    };
  }

  /// Zaxiradan tiklash — mavjud lokal kutilayotgan yozuvlar va jurnal almashtiriladi.
  static Future<void> replaceFromBackupBundle(Map<String, dynamic> raw) async {
    final v = raw['v'];
    if (v is! int || v != 1) {
      throw FormatException('Zaxira versiyasi qo\'llab-quvvatlanmaydi.');
    }
    final pending = raw[_pendingKey];
    final events = raw[_eventsKey];
    if (pending is! List) {
      throw FormatException('pending_record_batches yo\'q yoki noto\'g\'ri.');
    }
    if (events is! List) {
      throw FormatException('app_events yo\'q yoki noto\'g\'ri.');
    }
    await _b.put(_pendingKey, _deep(pending));
    await _b.put(_eventsKey, _deep(events));
  }
}
