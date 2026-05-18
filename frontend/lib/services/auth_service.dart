import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';
import 'api_service.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Session state only — credentials and profiles live in backend users.json.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _keyUserId = 'user_id';
  static const _keySaveAccount = 'save_account';

  SharedPreferences? _prefs;
  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isGuest => _currentUser?.isGuest ?? false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<AuthUser?> tryRestoreSession() async {
    final prefs = _prefs;
    if (prefs == null || prefs.getBool(_keySaveAccount) != true) {
      return null;
    }

    final userId = prefs.getString(_keyUserId);
    if (userId == null) {
      return null;
    }

    final parsedId = int.tryParse(userId);
    if (parsedId == null) {
      return null;
    }

    try {
      _currentUser = await _loadProfileFromBackend(parsedId);
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<AuthUser> signIn({
    required String email,
    required String password,
    required bool saveAccount,
  }) async {
    try {
      final profile = await ApiService.instance.login(
        email: email.trim(),
        password: password,
      );
      _currentUser = await _hydrateUserProfile(AuthUser.fromProfile(profile));
    } on StateError catch (error) {
      throw AuthException(error.message);
    } catch (_) {
      throw AuthException('Invalid email or password.');
    }

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
    String? groupCode,
    bool saveAccount = true,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final trimmedName = name.trim();

    if (trimmedName.isEmpty || normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw AuthException('Invalid input');
    }
    if (password.length < 6) {
      throw AuthException('Invalid input');
    }

    try {
      final profile = await ApiService.instance.registerAccount(
        name: trimmedName,
        email: normalizedEmail,
        password: password,
        groupCode: groupCode,
      );
      _currentUser = await _hydrateUserProfile(AuthUser.fromProfile(profile));
    } on StateError catch (error) {
      if (_isSignupBusinessError(error.message)) {
        throw AuthException(_friendlySignupError(error.message));
      }
      throw AuthException('Unable to create account. Is the backend running?');
    } catch (error) {
      if (error is AuthException) {
        rethrow;
      }
      throw AuthException('Unable to create account. Is the backend running?');
    }

    if (saveAccount) {
      await _persistSession(_currentUser!);
    } else {
      await _clearPersistedSession();
    }
    return _currentUser!;
  }

  Future<void> updateProfileGroup({
    int? groupId,
    String? groupCode,
    String? groupName,
    String? groupRole,
  }) async {
    final user = _currentUser;
    if (user == null || user.isGuest) {
      return;
    }

    _currentUser = user.copyWith(
      groupId: groupId,
      groupCode: groupCode,
      groupName: groupName,
      groupRole: groupRole,
    );

    if (_prefs?.getBool(_keySaveAccount) == true && _currentUser != null) {
      await _persistSession(_currentUser!);
    }
  }

  Future<void> refreshFromBackend() async {
    final user = _currentUser;
    if (user == null || user.isGuest) {
      return;
    }
    final userId = int.tryParse(user.id);
    if (userId == null) {
      return;
    }
    try {
      _currentUser = await _loadProfileFromBackend(userId);
      if (_prefs?.getBool(_keySaveAccount) == true && _currentUser != null) {
        await _persistSession(_currentUser!);
      }
    } catch (_) {
      // Keep last known session if API is temporarily unavailable.
    }
  }

  Future<AuthUser> continueAsGuest() async {
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
    await prefs.setBool(_keySaveAccount, true);
  }

  Future<void> _clearPersistedSession() async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    await prefs.remove(_keyUserId);
    await prefs.setBool(_keySaveAccount, false);
  }

  Future<AuthUser> _loadProfileFromBackend(int userId) async {
    final profile = await ApiService.instance.fetchUserProfile(userId);
    return _hydrateUserProfile(AuthUser.fromProfile(profile));
  }

  Future<AuthUser> _hydrateUserProfile(AuthUser user) async {
    if (user.groupId == null) {
      return user;
    }
    try {
      final group = await ApiService.instance.fetchGroupById(user.groupId!);
      if (group == null) {
        return user;
      }
      return user.copyWith(
        groupCode: group['code'] as String? ?? user.groupCode,
        groupName: group['name'] as String? ?? user.groupName,
      );
    } catch (_) {
      return user;
    }
  }

  static bool _isSignupBusinessError(String message) {
    return message.contains('User already exists') ||
        message.contains('Group not found') ||
        message.contains('Invalid input') ||
        message.contains('already assigned');
  }

  static String _friendlySignupError(String message) {
    if (message.contains('User already exists')) {
      return 'User already exists';
    }
    if (message.contains('Group not found')) {
      return 'Group not found';
    }
    if (message.contains('already assigned')) {
      return 'You are already assigned to another group';
    }
    if (message.contains('Invalid input')) {
      return 'Invalid input';
    }
    return message;
  }
}
