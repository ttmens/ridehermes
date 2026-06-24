class User {
  final int id;
  final String phone;
  final String nickname;
  final int role;
  final int status;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.phone,
    required this.nickname,
    required this.role,
    this.status = 1,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      role: (json['role'] as num?)?.toInt() ?? 3,
      status: (json['status'] as num?)?.toInt() ?? 1,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn = 7200,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? '',
      expiresIn: (json['expires_in'] as num?)?.toInt() ?? 7200,
    );
  }
}
