// filepath: Mobile/lib/services/secure_storage_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'accessToken';
  static const _refreshTokenKey = 'refreshToken'; // If you implement refresh tokens

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    // Also delete refresh token if used
    await _storage.delete(key: _refreshTokenKey);
  }

  // Add methods for refresh token if needed
  // Future<void> saveRefreshToken(String token) async { ... }
  // Future<String?> getRefreshToken() async { ... }
}
