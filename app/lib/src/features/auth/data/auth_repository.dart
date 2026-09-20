import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_providers.dart';
import '../domain/auth_user.dart';

const _tokenKey = 'vidyapd.auth.token';

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<AuthResult> register(String email, String password, String? fullName) async =>
      AuthResult.fromJson(await _api.post<Map<String, dynamic>>('/auth/register', body: {
        'email': email,
        'password': password,
        if (fullName != null && fullName.isNotEmpty) 'fullName': fullName,
      }));

  Future<AuthResult> login(String email, String password) async =>
      AuthResult.fromJson(await _api.post<Map<String, dynamic>>('/auth/login', body: {
        'email': email,
        'password': password,
      }));

  Future<AuthUser> me() async =>
      AuthUser.fromJson(await _api.get<Map<String, dynamic>>('/auth/me'));

  Future<String?> readToken() async =>
      (await SharedPreferences.getInstance()).getString(_tokenKey);

  Future<void> writeToken(String? token) async {
    final prefs = await SharedPreferences.getInstance();
    if (token == null) {
      await prefs.remove(_tokenKey);
    } else {
      await prefs.setString(_tokenKey, token);
    }
  }
}

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.watch(apiClientProvider)));
