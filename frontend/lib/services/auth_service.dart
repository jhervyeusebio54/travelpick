import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _StoredAccount {
  _StoredAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  final String id;
  final String name;
  final String email;
  final String password;

  AuthUser toUser() => AuthUser(id: id, name: name, email: email);
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _keyUserId = 'user_id';
  static const _keyEmail = 'email';
  static const _keyName = 'name';
  static const _keySaveAccount = 'save_account';
  static const _keyAccounts = 'mock_accounts';

  SharedPreferences? _prefs;
  final Map<String, _StoredAccount> _accountsByEmail = {};
  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isGuest => _currentUser?.isGuest ?? false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadAccounts();
    _seedDemoAccount();
  }

  Future<AuthUser?> tryRestoreSession() async {
    final prefs = _prefs;
    if (prefs == null || prefs.getBool(_keySaveAccount) != true) {
      return null;
    }

    final userId = prefs.getString(_keyUserId);
    final email = prefs.getString(_keyEmail);
    if (userId == null || email == null) {
      return null;
    }

    final account = _accountsByEmail[email.toLowerCase()];
    if (account == null || account.id != userId) {
      return null;
    }

    _currentUser = account.toUser();
    return _currentUser;
  }

  Future<AuthUser> signIn({
    required String email,
    required String password,
    required bool saveAccount,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    final normalizedEmail = email.trim().toLowerCase();
    final account = _accountsByEmail[normalizedEmail];

    if (account == null || account.password != password) {
      throw AuthException('Invalid email or password.');
    }

    _currentUser = account.toUser();
    if (saveAccount) {
      await _persistSession(_currentUser!);
    } else {
      await _clearPersistedSession();
    }
    return _currentUser!;
  }

  Future<AuthUser> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 520));
    final normalizedEmail = email.trim().toLowerCase();

    if (_accountsByEmail.containsKey(normalizedEmail)) {
      throw AuthException('An account with this email already exists.');
    }

    final account = _StoredAccount(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: normalizedEmail,
      password: password,
    );
    _accountsByEmail[normalizedEmail] = account;
    await _saveAccounts();
    return account.toUser();
  }

  Future<AuthUser> continueAsGuest() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    _currentUser = AuthUser(
      id: 'guest-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Explorer',
      email: '',
      isGuest: true,
    );
    await _clearPersistedSession();
    return _currentUser!;
  }

  void setCurrentUser(AuthUser user) {
    _currentUser = user;
  }

  Future<void> logout() async {
    _currentUser = null;
    await _clearPersistedSession();
  }

  Future<void> _persistSession(AuthUser user) async {
    final prefs = _prefs;
    if (prefs == null || user.isGuest) {
      return;
    }

    await prefs.setString(_keyUserId, user.id);
    await prefs.setString(_keyEmail, user.email);
    await prefs.setString(_keyName, user.name);
    await prefs.setBool(_keySaveAccount, true);
  }

  Future<void> _clearPersistedSession() async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }

    await prefs.remove(_keyUserId);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyName);
    await prefs.setBool(_keySaveAccount, false);
  }

  void _seedDemoAccount() {
    const email = 'demo@travelpick.com';
    if (_accountsByEmail.containsKey(email)) {
      return;
    }

    _accountsByEmail[email] = _StoredAccount(
      id: 'user-demo',
      name: 'Demo Traveler',
      email: email,
      password: 'demo123',
    );
    _saveAccounts();
  }

  Future<void> _loadAccounts() async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }

    final raw = prefs.getString(_keyAccounts);
    if (raw == null || raw.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      for (final entry in decoded) {
        final map = entry as Map<String, dynamic>;
        final account = _StoredAccount(
          id: map['id'] as String,
          name: map['name'] as String,
          email: map['email'] as String,
          password: map['password'] as String,
        );
        _accountsByEmail[account.email] = account;
      }
    } catch (_) {
      // Ignore corrupt storage and re-seed on next save.
    }
  }

  Future<void> _saveAccounts() async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }

    final payload = _accountsByEmail.values
        .map(
          (account) => {
            'id': account.id,
            'name': account.name,
            'email': account.email,
            'password': account.password,
          },
        )
        .toList(growable: false);

    await prefs.setString(_keyAccounts, jsonEncode(payload));
  }
}
