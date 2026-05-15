import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Per-tablet device credentials (the Admin/Manager who paired the tablet).
class DeviceCredentials {
  const DeviceCredentials({
    required this.token,
    required this.userId,
    required this.role,
    required this.restaurantId,
    required this.restaurantName,
    required this.storeId,
  });

  final String token;
  final String userId;
  final String role;
  final String restaurantId;
  final String restaurantName;
  final String storeId;
}

/// Display info shown on a cashier tile in the user picker. The JWT lives
/// encrypted under [_StoreKeys.cashierBlob] and is only decrypted when the
/// cashier enters their PIN.
class CashierEntry {
  const CashierEntry({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
  });

  final String userId;
  final String fullName;
  final String email;
  final String role;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'userId': userId,
        'fullName': fullName,
        'email': email,
        'role': role,
      };

  static CashierEntry fromJson(Map<String, dynamic> j) => CashierEntry(
        userId: j['userId'] as String,
        fullName: j['fullName'] as String,
        email: j['email'] as String,
        role: j['role'] as String,
      );
}

class _StoreKeys {
  static const String deviceToken = 'device.token';
  static const String deviceUserId = 'device.user_id';
  static const String deviceRole = 'device.role';
  static const String deviceRestaurantId = 'device.restaurant_id';
  static const String deviceRestaurantName = 'device.restaurant_name';
  static const String deviceStoreId = 'device.store_id';

  static const String cashierIndex = 'cashier.index';
  static String cashierMeta(String userId) => 'cashier.$userId.meta';
  static String cashierSalt(String userId) => 'cashier.$userId.salt';
  static String cashierNonce(String userId) => 'cashier.$userId.nonce';
  static String cashierBlob(String userId) => 'cashier.$userId.blob';
  static String cashierAttempts(String userId) => 'cashier.$userId.attempts';
}

/// Thin wrapper around flutter_secure_storage that owns:
/// * one device-level JWT + paired-store id (admin/manager who paired)
/// * a list of cashier entries, each with a PIN-encrypted JWT
///
/// Crypto: PBKDF2-HMAC-SHA256 (200k iterations) over `pin` + per-cashier salt
/// derives a 256-bit AES-GCM key; the JWT bytes are sealed under that key with
/// a fresh 12-byte nonce. The PIN itself is never stored — a wrong PIN simply
/// fails the GCM auth tag.
class SecureCredentialsService {
  SecureCredentialsService([FlutterSecureStorage? storage])
      : _store = storage ?? const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _store;
  static const int _pbkdf2Iterations = 200000;
  static final Pbkdf2 _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: _pbkdf2Iterations,
    bits: 256,
  );
  static final AesGcm _aes = AesGcm.with256bits();

  // ---------- device-level ----------

  Future<void> saveDevice(DeviceCredentials d) async {
    await Future.wait<void>(<Future<void>>[
      _store.write(key: _StoreKeys.deviceToken, value: d.token),
      _store.write(key: _StoreKeys.deviceUserId, value: d.userId),
      _store.write(key: _StoreKeys.deviceRole, value: d.role),
      _store.write(key: _StoreKeys.deviceRestaurantId, value: d.restaurantId),
      _store.write(key: _StoreKeys.deviceRestaurantName, value: d.restaurantName),
      _store.write(key: _StoreKeys.deviceStoreId, value: d.storeId),
    ]);
  }

  Future<DeviceCredentials?> readDevice() async {
    final String? token = await _store.read(key: _StoreKeys.deviceToken);
    if (token == null) return null;
    return DeviceCredentials(
      token: token,
      userId: (await _store.read(key: _StoreKeys.deviceUserId)) ?? '',
      role: (await _store.read(key: _StoreKeys.deviceRole)) ?? '',
      restaurantId: (await _store.read(key: _StoreKeys.deviceRestaurantId)) ?? '',
      restaurantName:
          (await _store.read(key: _StoreKeys.deviceRestaurantName)) ?? '',
      storeId: (await _store.read(key: _StoreKeys.deviceStoreId)) ?? '',
    );
  }

  Future<void> wipeDevice() async {
    await _store.deleteAll();
  }

  // ---------- cashiers ----------

  Future<List<CashierEntry>> listCashiers() async {
    final String? raw = await _store.read(key: _StoreKeys.cashierIndex);
    if (raw == null || raw.isEmpty) return <CashierEntry>[];
    final List<String> ids = (jsonDecode(raw) as List<dynamic>).cast<String>();
    final List<CashierEntry> out = <CashierEntry>[];
    for (final String id in ids) {
      final String? metaRaw = await _store.read(key: _StoreKeys.cashierMeta(id));
      if (metaRaw == null) continue;
      out.add(CashierEntry.fromJson(jsonDecode(metaRaw) as Map<String, dynamic>));
    }
    return out;
  }

  /// Encrypts [jwt] with a key derived from [pin] and persists everything
  /// needed to later prompt the cashier with their tile.
  Future<void> addCashier({
    required CashierEntry entry,
    required String jwt,
    required String pin,
  }) async {
    final List<int> salt = _randomBytes(16);
    final SecretKey key = await _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    final List<int> nonce = _randomBytes(12);
    final SecretBox box = await _aes.encrypt(
      utf8.encode(jwt),
      secretKey: key,
      nonce: nonce,
    );
    // SecretBox.concatenation is `nonce || cipherText || mac`. We store the
    // raw nonce separately to keep it inspectable, so the blob = cipherText||mac.
    final List<int> blob = <int>[...box.cipherText, ...box.mac.bytes];

    await Future.wait<void>(<Future<void>>[
      _store.write(
        key: _StoreKeys.cashierMeta(entry.userId),
        value: jsonEncode(entry.toJson()),
      ),
      _store.write(
        key: _StoreKeys.cashierSalt(entry.userId),
        value: base64Encode(salt),
      ),
      _store.write(
        key: _StoreKeys.cashierNonce(entry.userId),
        value: base64Encode(nonce),
      ),
      _store.write(
        key: _StoreKeys.cashierBlob(entry.userId),
        value: base64Encode(blob),
      ),
      _store.delete(key: _StoreKeys.cashierAttempts(entry.userId)),
    ]);

    final List<CashierEntry> existing = await listCashiers();
    final List<String> ids = <String>[
      ...existing.where((CashierEntry e) => e.userId != entry.userId).map((CashierEntry e) => e.userId),
      entry.userId,
    ];
    await _store.write(key: _StoreKeys.cashierIndex, value: jsonEncode(ids));
  }

  Future<void> removeCashier(String userId) async {
    final List<CashierEntry> existing = await listCashiers();
    final List<String> ids = existing
        .where((CashierEntry e) => e.userId != userId)
        .map((CashierEntry e) => e.userId)
        .toList();
    await Future.wait<void>(<Future<void>>[
      _store.delete(key: _StoreKeys.cashierMeta(userId)),
      _store.delete(key: _StoreKeys.cashierSalt(userId)),
      _store.delete(key: _StoreKeys.cashierNonce(userId)),
      _store.delete(key: _StoreKeys.cashierBlob(userId)),
      _store.delete(key: _StoreKeys.cashierAttempts(userId)),
      _store.write(key: _StoreKeys.cashierIndex, value: jsonEncode(ids)),
    ]);
  }

  /// Returns the decrypted JWT, or null if the PIN was wrong (auth tag fails).
  Future<String?> unlockJwt({required String userId, required String pin}) async {
    final String? saltB64 = await _store.read(key: _StoreKeys.cashierSalt(userId));
    final String? nonceB64 = await _store.read(key: _StoreKeys.cashierNonce(userId));
    final String? blobB64 = await _store.read(key: _StoreKeys.cashierBlob(userId));
    if (saltB64 == null || nonceB64 == null || blobB64 == null) return null;

    final List<int> blob = base64Decode(blobB64);
    // AES-GCM tag is 16 bytes (128 bits).
    if (blob.length < 16) return null;
    final List<int> cipherText = blob.sublist(0, blob.length - 16);
    final Mac mac = Mac(blob.sublist(blob.length - 16));

    final SecretKey key = await _kdf.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: base64Decode(saltB64),
    );
    try {
      final List<int> plain = await _aes.decrypt(
        SecretBox(cipherText, nonce: base64Decode(nonceB64), mac: mac),
        secretKey: key,
      );
      await _store.delete(key: _StoreKeys.cashierAttempts(userId));
      return utf8.decode(plain);
    } on SecretBoxAuthenticationError {
      final int prev =
          int.tryParse((await _store.read(key: _StoreKeys.cashierAttempts(userId))) ?? '0') ?? 0;
      await _store.write(
        key: _StoreKeys.cashierAttempts(userId),
        value: '${prev + 1}',
      );
      return null;
    }
  }

  Future<int> failedAttempts(String userId) async {
    final String? raw =
        await _store.read(key: _StoreKeys.cashierAttempts(userId));
    return int.tryParse(raw ?? '0') ?? 0;
  }

  // ---------- crypto helpers ----------

  static final Random _rng = Random.secure();

  static List<int> _randomBytes(int len) {
    final Uint8List out = Uint8List(len);
    for (int i = 0; i < len; i++) {
      out[i] = _rng.nextInt(256);
    }
    return out;
  }
}
