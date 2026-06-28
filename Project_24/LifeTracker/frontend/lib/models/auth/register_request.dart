class RegisterRequest {
  const RegisterRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.houseKey,
  });

  final String email;
  final String password;
  final String firstName;
  final String houseKey;

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'firstName': firstName.trim(),
        'houseKey': houseKey.trim(),
      };
}
