class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    this.refreshToken,
    required this.tokenType,
    this.expiresIn,
    required this.userId,
    required this.uuid,
    required this.email,
    required this.firstName,
    required this.houseKey,
  });

  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int? expiresIn;
  final int userId;
  final String uuid;
  final String email;
  final String firstName;
  final String houseKey;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String?,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: _toInt(json['expiresIn']),
      userId: _toInt(json['userId']) ?? 0,
      uuid: json['uuid']?.toString() ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName']?.toString() ?? json['displayName']?.toString() ?? '',
      houseKey: json['houseKey']?.toString() ?? 'stark',
    );
  }

  static int? _toInt(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
