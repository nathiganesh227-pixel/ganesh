import 'package:flutter/foundation.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

class PlazaUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String tier;
  final String membershipId;
  final int rewardPoints;

  const PlazaUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.tier,
    required this.membershipId,
    this.rewardPoints = 2480,
  });

  factory PlazaUser.fromJson(Map<String, dynamic> json) {
    return PlazaUser(
      id: json['id'] as String? ?? 'usr_default_1',
      name: json['name'] as String? ?? 'Gopi Ganesh',
      email: json['email'] as String? ?? 'gopi.ganesh@plaza.club',
      phone: json['phone'] as String? ?? '+91 98765 43210',
      tier: json['tier'] as String? ?? 'PLAZA Black Tier',
      membershipId: json['membershipId'] as String? ?? 'PLZ-BLK-88210',
      rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 2480,
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
  };
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
  );
  String? _authToken;

  PlazaUser? get currentUser => _currentUser;
  bool get isAuthenticated => _authToken != null || _currentUser != null;
  String? get authToken => _authToken;

  Future<bool> login({required String email, required String password}) async {
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
        return true;
      }
    } catch (_) {}
    return false;
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
}
