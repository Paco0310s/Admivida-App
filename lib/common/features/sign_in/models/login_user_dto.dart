import 'dart:convert';

class LoginUserDto {
  final String emailOrPhone;
  final String password;

  LoginUserDto({required this.emailOrPhone, required this.password});

  factory LoginUserDto.fromRawJson(String str) => LoginUserDto.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory LoginUserDto.fromJson(Map<String, dynamic> json) => LoginUserDto(emailOrPhone: json["emailOrPhone"], password: json["password"]);

  Map<String, dynamic> toJson() => {"emailOrPhone": emailOrPhone, "password": password};
}
