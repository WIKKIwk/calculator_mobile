import 'package:hive_ce/hive.dart';

import '../models/product.dart';
import '../models/record.dart';
import '../models/user.dart';
import 'device_local_key_service.dart';

/// Foydalanuvchilar, mahsulotlar va hisobot qatorlari — faqat qurilmada saqlanadi (tarmoq yo'q).
class OfflineEntityStore {
  OfflineEntityStore._();

  static const _boxName = 'calculator_offline_entities';
  static const _usersKey = 'users';
  static const _productsKey = 'products';
  static const _recordsKey = 'records';

  static Box<dynamic>? _box;

  static Future<void> init() async {
    final key = await DeviceLocalKeyService.getOrCreateHiveEncryptionKey();
    final cipher = HiveAesCipher(key);
    _box = await Hive.openBox<dynamic>(_boxName, encryptionCipher: cipher);
  }

  static Box<dynamic> get _b {
    final b = _box;
    if (b == null) {
      throw StateError('OfflineEntityStore.init() chaqirilmagan');
    }
    return b;
  }

  static List<Map<String, dynamic>> _readList(String key) {
    final raw = _b.get(key);
    if (raw is! List) return [];
    return raw
        .map(
          (e) => Map<String, dynamic>.from(
            (e as Map).map((k, v) => MapEntry(k.toString(), v)),
          ),
        )
        .toList();
  }

  static Future<void> _writeList(String key, List<Map<String, dynamic>> list) async {
    await _b.put(key, list);
  }

  static String _newId(String prefix) =>
      '${prefix}_${DateTime.now().toUtc().microsecondsSinceEpoch}';

  static Future<List<User>> users() async =>
      _readList(_usersKey).map(User.fromJson).toList();

  static Future<List<Product>> products() async =>
      _readList(_productsKey).map(Product.fromJson).toList();

  static Future<List<Record>> records() async =>
      _readList(_recordsKey).map(Record.fromJson).toList();

  static Future<User> createUser({
    required String firstName,
    required String lastName,
  }) async {
    final list = _readList(_usersKey);
    final now = DateTime.now().toUtc().toIso8601String();
    final u = <String, dynamic>{
      'id': _newId('u'),
      'firstName': firstName,
      'lastName': lastName,
      'createdAt': now,
    };
    list.add(u);
    await _writeList(_usersKey, list);
    return User.fromJson(u);
  }

  static Future<User> updateUser({
    required String id,
    required String firstName,
    required String lastName,
  }) async {
    final list = _readList(_usersKey);
    final i = list.indexWhere((e) => e['id'] == id);
    if (i < 0) throw StateError('User topilmadi');
    list[i] = {
      ...list[i],
      'firstName': firstName,
      'lastName': lastName,
    };
    await _writeList(_usersKey, list);
    return User.fromJson(list[i]);
  }

  static Future<void> deleteUser(String id) async {
    final users = _readList(_usersKey)..removeWhere((e) => e['id'] == id);
    await _writeList(_usersKey, users);
    final recs = _readList(_recordsKey)
      ..removeWhere((e) {
        final u = e['user'];
        return u is Map && u['id'] == id;
      });
    await _writeList(_recordsKey, recs);
  }

  static Future<Product> createProduct({
    required String name,
    required double price,
  }) async {
    final list = _readList(_productsKey);
    final now = DateTime.now().toUtc().toIso8601String();
    final p = <String, dynamic>{
      'id': _newId('p'),
      'name': name,
      'price': price,
      'createdAt': now,
    };
    list.add(p);
    await _writeList(_productsKey, list);
    return Product.fromJson(p);
  }

  static Future<Product> updateProduct({
    required String id,
    required String name,
    required double price,
  }) async {
    final list = _readList(_productsKey);
    final i = list.indexWhere((e) => e['id'] == id);
    if (i < 0) throw StateError('Mahsulot topilmadi');
    list[i] = {
      ...list[i],
      'name': name,
      'price': price,
    };
    await _writeList(_productsKey, list);
    return Product.fromJson(list[i]);
  }

  static Future<void> addRecordsForUser({
    required User user,
    required Map<String, double> productIdToQuantity,
    required List<Product> allProducts,
  }) async {
    if (productIdToQuantity.isEmpty) return;
    final list = _readList(_recordsKey);
    final now = DateTime.now().toUtc().toIso8601String();
    for (final e in productIdToQuantity.entries) {
      if (e.value <= 0) continue;
      Product? p;
      for (final x in allProducts) {
        if (x.id == e.key) {
          p = x;
          break;
        }
      }
      if (p == null) continue;
      list.add({
        'id': _newId('r'),
        'user': {
          'id': user.id,
          'firstName': user.firstName,
          'lastName': user.lastName,
          'createdAt': user.createdAt,
        },
        'product': {
          'id': p.id,
          'name': p.name,
          'price': p.price,
          'createdAt': p.createdAt,
        },
        'quantity': e.value,
        'createdAt': now,
      });
    }
    await _writeList(_recordsKey, list);
  }

  static Map<String, dynamic> snapshotForBackup() {
    return {
      _usersKey: _readList(_usersKey),
      _productsKey: _readList(_productsKey),
      _recordsKey: _readList(_recordsKey),
    };
  }

  static Future<void> restoreFromSnapshot(Map<String, dynamic> raw) async {
    Future<void> put(String key, dynamic val) async {
      if (val is! List) {
        await _writeList(key, []);
        return;
      }
      final out = <Map<String, dynamic>>[];
      for (final e in val) {
        if (e is Map) {
          out.add(
            Map<String, dynamic>.from(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ),
          );
        }
      }
      await _writeList(key, out);
    }

    await put(_usersKey, raw[_usersKey]);
    await put(_productsKey, raw[_productsKey]);
    await put(_recordsKey, raw[_recordsKey]);
  }
}
