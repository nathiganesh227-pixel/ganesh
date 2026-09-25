import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

enum UserRole {
  user,
  admin;

  static UserRole fromString(String? role) {
    if (role == null) return UserRole.user;
    final r = role.toLowerCase().trim();
    if (r == 'admin') return UserRole.admin;
    return UserRole.user;
  }
}

class PlazaUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String tier;
  final String membershipId;
  final int rewardPoints;
  final UserRole role;

  const PlazaUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '+91 98765 43210',
    this.tier = 'PLAZA Black Tier',
    this.membershipId = 'PLZ-BLK-88210',
    this.rewardPoints = 2480,
    this.role = UserRole.user,
  });

  bool get isAdmin => role == UserRole.admin;

  factory PlazaUser.fromJson(Map<String, dynamic> json) {
    final roleStr = (json['role'] as String?)?.toLowerCase();
    return PlazaUser(
      id: json['id'] as String? ?? 'usr_default_1',
      name: json['name'] as String? ?? 'Gopi Ganesh',
      email: json['email'] as String? ?? 'gopi.ganesh@plaza.club',
      phone: json['phone'] as String? ?? '+91 98765 43210',
      tier: json['tier'] as String? ?? 'PLAZA Black Tier',
      membershipId: json['membershipId'] as String? ?? 'PLZ-BLK-88210',
      rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 2480,
      role: roleStr == 'admin' ? UserRole.admin : UserRole.user,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'tier': tier,
    'membershipId': membershipId,
    'rewardPoints': rewardPoints,
    'role': role.name,
  };
}

class AuthResult {
  final bool success;
  final PlazaUser? user;
  final String? errorMessage;

  const AuthResult({required this.success, this.user, this.errorMessage});
}

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  final ApiClient _client = ApiClient();
  PlazaUser? _currentUser = const PlazaUser(
    id: 'usr_default_1',
    name: 'Gopi Ganesh',
    email: 'gopi.ganesh@plaza.club',
    phone: '+91 98765 43210',
    tier: 'PLAZA Black Tier',
    membershipId: 'PLZ-BLK-88210',
    rewardPoints: 2480,
    role: UserRole.user,
  );
  String? _authToken;

  PlazaUser? get currentUser => _currentUser;
  bool get isAuthenticated => _authToken != null || _currentUser != null;
  String? get authToken => _authToken;

  Future<AuthResult> loginWithResult({required String email, required String password}) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '${ApiEndpoints.auth}/login',
        body: {'email': email, 'password': password},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        _authToken = data['token'] as String?;
        if (_authToken != null) {
          _client.setAuthToken(_authToken);
        }
        if (data['user'] != null) {
          _currentUser = PlazaUser.fromJson(data['user'] as Map<String, dynamic>);
        }
        notifyListeners();
        return AuthResult(success: true, user: _currentUser);
      } else {
        return AuthResult(
          success: false,
          errorMessage: response.message ?? 'Invalid credentials.',
        );
      }
    } catch (e) {
      return AuthResult(success: false, errorMessage: e.toString());
    }
  }

  Future<bool> login({required String email, required String password}) async {
    final result = await loginWithResult(email: email, password: password);
    return result.success;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final body = <String, dynamic>{
        'name': name,
        'email': email,
        'password': password,
      };
      if (phone != null) {
        body['phone'] = phone;
      }

      final response = await _client.post<Map<String, dynamic>>(
        '${ApiEndpoints.auth}/register',
        body: body,
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        _authToken = data['token'] as String?;
        if (_authToken != null) {
          _client.setAuthToken(_authToken);
        }
        if (data['user'] != null) {
          _currentUser = PlazaUser.fromJson(data['user'] as Map<String, dynamic>);
        }
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> demoLogin() async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '${ApiEndpoints.auth}/demo-login',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.success && response.data != null) {
        final data = response.data!;
        _authToken = data['token'] as String?;
        if (_authToken != null) {
          _client.setAuthToken(_authToken);
        }
        if (data['user'] != null) {
          _currentUser = PlazaUser.fromJson(data['user'] as Map<String, dynamic>);
        }
        notifyListeners();
        return true;
      }
    } catch (_) {}

    // Fallback to default local user if offline
    _currentUser = const PlazaUser(
      id: 'usr_default_1',
      name: 'Gopi Ganesh',
      email: 'gopi.ganesh@plaza.club',
      phone: '+91 98765 43210',
      tier: 'PLAZA Black Tier',
      membershipId: 'PLZ-BLK-88210',
      rewardPoints: 2480,
    );
    notifyListeners();
    return true;
  }

  Future<PlazaUser?> getProfile() async {
    try {
      final response = await _client.get<PlazaUser?>(
        '${ApiEndpoints.auth}/me',
        fromJson: (json) =>
            json != null ? PlazaUser.fromJson(json as Map<String, dynamic>) : null,
      );

      if (response.success && response.data != null) {
        _currentUser = response.data;
        notifyListeners();
        return _currentUser;
      }
    } catch (_) {}
    return _currentUser;
  }

  void logout() {
    _authToken = null;
    _currentUser = null;
    _client.setAuthToken(null);
    notifyListeners();
  }

  void signOut() => logout();

  void setMockUser(PlazaUser? user, [String? token]) {
    _currentUser = user;
    _authToken = token;
    _client.setAuthToken(token);
    notifyListeners();
  }
}
