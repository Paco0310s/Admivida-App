import 'dart:convert';

class CreateUserDto {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final DateTime birthdate;
  final Map<String, dynamic> metadata;

  CreateUserDto({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.birthdate,
    required this.metadata,
  });

  factory CreateUserDto.fromRawJson(String str) => CreateUserDto.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory CreateUserDto.fromJson(Map<String, dynamic> json) => CreateUserDto(
    firstName: json["firstName"],
    lastName: json["lastName"],
    email: json["email"],
    phone: json["phone"],
    password: json["password"],
    birthdate: DateTime.parse(json["birthdate"]),
    metadata: json["metadata"] ?? {},
  );

  Map<String, dynamic> toJson() => {
    "firstName": firstName,
    "lastName": lastName,
    "email": email,
    "phone": phone,
    "password": password,
    "birthdate": "${birthdate.year.toString().padLeft(4, '0')}-${birthdate.month.toString().padLeft(2, '0')}-${birthdate.day.toString().padLeft(2, '0')}",
    "metadata": metadata,
  };
}
