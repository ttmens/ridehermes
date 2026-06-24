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
    required this.status,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      phone: json['phone'] as String,
      nickname: json['nickname'] as String,
      role: json['role'] as int,
      status: (json['status'] as int?) ?? 1,
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
    required this.expiresIn,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: json['expires_in'] as int,
    );
  }
}
