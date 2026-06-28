class UserResponse {
  const UserResponse({
    required this.id,
    required this.uuid,
    required this.email,
    required this.firstName,
    required this.houseKey,
  });

  final int id;
  final String uuid;
  final String email;
  final String firstName;
  final String houseKey;

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: _toInt(json['id']) ?? 0,
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
