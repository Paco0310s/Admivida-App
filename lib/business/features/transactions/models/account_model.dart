class AccountModel {
  final String id;
  final String name;
  final String? description;
  final String accountTypeId;
  final String accountTypeName;

  AccountModel({required this.id, required this.name, this.description, required this.accountTypeId, required this.accountTypeName});

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      accountTypeId: json['accountTypeId'] as String,
      accountTypeName: json['accountTypeName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description, 'accountTypeId': accountTypeId, 'accountTypeName': accountTypeName};
  }
}
