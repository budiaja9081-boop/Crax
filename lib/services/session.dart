import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static const _usersKey = 'crax_users';
  static const _sessionKey = 'crax_session';

  Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  Future<Map<String, dynamic>> _users() async {
    final raw = (await _p).getString(_usersKey);
    return raw == null ? <String, dynamic>{} : Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<void> _saveUsers(Map<String, dynamic> users) async {
    (await _p).setString(_usersKey, jsonEncode(users));
  }

  String _hash(String salt, String pass) =>
      sha256.convert(utf8.encode('$salt:$pass')).toString();

  String _salt() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  Future<String?> register(String user, String pass, String name) async {
    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(user)) {
      return 'Username 3-20 karakter (huruf, angka, underscore)';
    }
    if (pass.length < 6) return 'Password minimal 6 karakter';
    final users = await _users();
    if (users.containsKey(user)) return 'Username sudah dipakai';
    final salt = _salt();
    users[user] = {
      'salt': salt,
      'hash': _hash(salt, pass),
      'name': name.isEmpty ? user : name,
    };
    await _saveUsers(users);
    return null;
  }

  Future<String?> login(String user, String pass) async {
    final users = await _users();
    final u = users[user];
    if (u is! Map) return 'Username atau password salah';
    if (_hash(u['salt'] as String, pass) != u['hash']) {
      return 'Username atau password salah';
    }
    (await _p).setString(_sessionKey, user);
    return null;
  }

  Future<String?> currentUser() async => (await _p).getString(_sessionKey);

  Future<void> logout() async => (await _p).remove(_sessionKey);

  Future<Map<String, String>> profile(String user) async {
    final u = (await _users())[user];
    final name = (u is Map ? u['name'] : null) as String?;
    return {'name': name ?? user};
  }

  Future<String?> updateProfile(
    String user, {
    String? name,
    String? currentPass,
    String? newPass,
  }) async {
    final users = await _users();
    final u = Map<String, dynamic>.from(users[user] as Map);
    if (newPass != null && newPass.isNotEmpty) {
      if (currentPass == null || _hash(u['salt'] as String, currentPass) != u['hash']) {
        return 'Password lama salah';
      }
      if (newPass.length < 6) return 'Password baru minimal 6 karakter';
      final salt = _salt();
      u['salt'] = salt;
      u['hash'] = _hash(salt, newPass);
    }
    if (name != null && name.trim().isNotEmpty) {
      u['name'] = name.trim();
    }
    users[user] = u;
    await _saveUsers(users);
    return null;
  }

  Future<String?> getWallpaper(String key) async =>
      (await _p).getString('crax_wall_$key');

  Future<void> setWallpaper(String key, String? path) async {
    final p = await _p;
    if (path == null) {
      await p.remove('crax_wall_$key');
    } else {
      await p.setString('crax_wall_$key', path);
    }
  }
}
