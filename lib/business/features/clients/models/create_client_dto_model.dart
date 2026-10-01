class CreateClientDto {
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;

  CreateClientDto({required this.firstName, required this.lastName, this.email, this.phone});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {"firstName": firstName, "lastName": lastName};

    if (email != null && email!.isNotEmpty) data["email"] = email;
    if (phone != null && phone!.isNotEmpty) data["phone"] = phone;

    return data;
  }
}
