import 'dart:convert';

class LoginUserDto {
  final String emailOrPhone;
  final String password;
  final String? fcmToken;
  final String? deviceInfo;
  final String? appVersion;

  LoginUserDto({
    required this.emailOrPhone,
    required this.password,
    this.fcmToken,
    this.deviceInfo,
    this.appVersion,
  });

  factory LoginUserDto.fromRawJson(String str) => LoginUserDto.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory LoginUserDto.fromJson(Map<String, dynamic> json) => LoginUserDto(
        emailOrPhone: json["emailOrPhone"],
        password: json["password"],
        fcmToken: json["fcmToken"],
        deviceInfo: json["deviceInfo"],
        appVersion: json["appVersion"],
      );

  Map<String, dynamic> toJson() => {
        "emailOrPhone": emailOrPhone,
        "password": password,
        if (fcmToken != null && fcmToken!.isNotEmpty) "fcmToken": fcmToken,
        if (deviceInfo != null && deviceInfo!.isNotEmpty) "deviceInfo": deviceInfo,
        if (appVersion != null && appVersion!.isNotEmpty) "appVersion": appVersion,
      };
}
