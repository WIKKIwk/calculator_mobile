import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'app_local_store.dart';

/// Parol bilan shifrlangan zaxira fayli — ilova o‘chirilgandan keyin ham tiklash mumkin
/// (fayl bulut / kompyuterga saqlangan bo‘lsa).
class SecureBackupService {
  SecureBackupService._();

  static const _magic = [0x43, 0x41, 0x4c, 0x43]; // "CALC"
  static const int _formatVersion = 1;
  static const int _pbkdf2Iterations = 210000;

  static Future<Uint8List> buildEncryptedFile(String password) async {
    if (password.length < 8) {
      throw ArgumentError('Parol kamida 8 belgi bo‘lishi kerak.');
    }
    final bundle = await AppLocalStore.snapshotForBackup();
    final plain = Uint8List.fromList(utf8.encode(jsonEncode(bundle)));

    final salt = Uint8List.fromList(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)),
    );
    final pbkdf2 = Pbkdf2.hmacSha256(
      iterations: _pbkdf2Iterations,
      bits: 256,
    );
    final secretKey = await pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );

    final aes = AesGcm.with256bits();
    final nonce = aes.newNonce();
    final box = await aes.encrypt(
      plain,
      secretKey: secretKey,
      nonce: nonce,
    );
    final body = box.concatenation();

    final it = ByteData(4)..setUint32(0, _pbkdf2Iterations, Endian.big);
    const headLen = 4 + 1 + 16 + 4;
    final out = Uint8List(headLen + body.length);
    out.setRange(0, 4, _magic);
    out[4] = _formatVersion;
    out.setRange(5, 21, salt);
    out.setRange(21, 25, it.buffer.asUint8List());
    out.setRange(25, out.length, body);
    return out;
  }

  /// Fayl mazmunini tekshiradi va lokal saqlamga yozadi.
  static Future<void> restoreFromEncryptedBytes(
    Uint8List fileBytes,
    String password,
  ) async {
    if (password.length < 8) {
      throw ArgumentError('Parol kamida 8 belgi bo‘lishi kerak.');
    }
    if (fileBytes.length < 5 + 16 + 4) {
      throw FormatException('Fayl juda qisqa.');
    }
    for (var i = 0; i < 4; i++) {
      if (fileBytes[i] != _magic[i]) {
        throw FormatException('Bu hisoblagich zaxira fayli emas.');
      }
    }
    if (fileBytes[4] != _formatVersion) {
      throw FormatException('Noma\'lum zaxira formati (v${fileBytes[4]}).');
    }
    var off = 5;
    final salt = fileBytes.sublist(off, 16);
    off += 16;
    final itData = ByteData.sublistView(fileBytes, off, off + 4);
    off += 4;
    final iterations = itData.getUint32(0, Endian.big);
    final cipherPart = fileBytes.sublist(off);

    if (iterations < 10000 || iterations > 10 * _pbkdf2Iterations) {
      throw FormatException('Zaxira fayli buzilgan.');
    }

    final pbkdf2 = Pbkdf2.hmacSha256(iterations: iterations, bits: 256);
    final secretKey = await pbkdf2.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final aes = AesGcm.with256bits();
    final secretBox = SecretBox.fromConcatenation(
      cipherPart,
      nonceLength: aes.nonceLength,
      macLength: aes.macAlgorithm.macLength,
    );
    final clear = await aes.decrypt(secretBox, secretKey: secretKey);
    final map = jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
    await AppLocalStore.replaceFromBackupBundle(map);
  }
}
