import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';

/// Lokal Hive qutisi uchun 32 baytli kalit — Android Keystore / iOS Keychain.
class DeviceLocalKeyService {
  DeviceLocalKeyService._();

  static const _storageKey = 'calculator_hive_local_aes_key_b64';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Hive [HiveAesCipher] uchun aynan 32 bayt.
  static Future<List<int>> getOrCreateHiveEncryptionKey() async {
    final existing = await _storage.read(key: _storageKey);
    if (existing != null && existing.isNotEmpty) {
      final bytes = base64Url.decode(existing);
      if (bytes.length == 32) {
        return bytes;
      }
    }
    final key = Hive.generateSecureKey();
    await _storage.write(key: _storageKey, value: base64Url.encode(key));
    return key;
  }
}
