class AccountModel {
  final String id;
  final String name;
  final String? description;
  final String accountTypeId;
  final String accountTypeName;
  final String? accountTypeCode;
  final bool isDefault;
  final double balance;
  final double? creditLimit;
  final double debt;
  final double? availableCredit;

  AccountModel({
    required this.id,
    required this.name,
    this.description,
    required this.accountTypeId,
    required this.accountTypeName,
    this.accountTypeCode,
    this.isDefault = false,
    this.balance = 0.0,
    this.creditLimit,
    this.debt = 0.0,
    this.availableCredit,
  });

  bool get isCreditOrLoan => accountTypeCode == 'BANK_CREDIT';

  bool get isDebitOrBank =>
      accountTypeCode == 'BANK_DEBIT' ||
      accountTypeName.toLowerCase().contains('débito') ||
      accountTypeName.toLowerCase().contains('banco');

  bool get hasCreditLimit => creditLimit != null && creditLimit! > 0;

  double get effectiveDebt =>
      isCreditOrLoan ? (debt > 0 ? debt : (balance < 0 ? -balance : 0.0)) : 0.0;

  double? get effectiveAvailableCredit {
    if (!isCreditOrLoan || !hasCreditLimit) return null;
    if (availableCredit != null) return availableCredit;
    final remaining = creditLimit! - effectiveDebt;
    return remaining < 0 ? 0.0 : remaining;
  }

  double get creditUsageRatio {
    if (!hasCreditLimit || creditLimit! <= 0) return 0.0;
    final ratio = effectiveDebt / creditLimit!;
    if (ratio < 0) return 0.0;
    if (ratio > 1) return 1.0;
    return ratio;
  }

  String get dropdownLabel {
    if (isCreditOrLoan) {
      if (hasCreditLimit) {
        return '$name (Debes: \$${effectiveDebt.toStringAsFixed(2)} · Disp: \$${effectiveAvailableCredit!.toStringAsFixed(2)})';
      }
      return '$name (Deuda: \$${effectiveDebt.toStringAsFixed(2)})';
    }
    return '$name (\$${balance.toStringAsFixed(2)})';
  }

  static double _parseDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw) ?? 0.0;
    return 0.0;
  }

  static double? _parseNullableDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      accountTypeId: (json['accountTypeId'] as String?) ?? '',
      accountTypeName: (json['accountTypeName'] as String?) ?? 'Efectivo',
      accountTypeCode: json['accountTypeCode'] as String?,
      isDefault: json['isDefault'] == true || json['is_default'] == true || json['isDefault'] == 1,
      balance: _parseDouble(json['balance']),
      creditLimit: _parseNullableDouble(json['creditLimit']),
      debt: _parseDouble(json['debt']),
      availableCredit: _parseNullableDouble(json['availableCredit']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'accountTypeId': accountTypeId,
      'accountTypeName': accountTypeName,
      if (accountTypeCode != null) 'accountTypeCode': accountTypeCode,
      'isDefault': isDefault,
      'balance': balance,
      if (creditLimit != null) 'creditLimit': creditLimit,
      'debt': debt,
      if (availableCredit != null) 'availableCredit': availableCredit,
    };
  }
}
