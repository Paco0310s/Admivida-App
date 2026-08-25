class TransactionModel {
  final String id;
  final String accountId;
  final String? accountName;
  final String paymentMethodId;
  final String? paymentMethodName;
  final String? businessId;
  final String? saleId;
  final double amount;
  final String type; // 'INCOME' o 'EXPENSE'
  final String? description;
  final DateTime createdAt;

  TransactionModel({
    required this.id,
    required this.accountId,
    this.accountName,
    required this.paymentMethodId,
    this.paymentMethodName,
    this.businessId,
    this.saleId,
    required this.amount,
    required this.type,
    this.description,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      accountName: json['accountName'] as String?,
      paymentMethodId: json['paymentMethodId'] as String,
      paymentMethodName: json['paymentMethodName'] as String?,
      businessId: json['businessId'] as String?,
      saleId: json['saleId'] as String?,
      // Usamos (json['amount'] as num).toDouble() para evitar errores si el JSON manda un entero (ej. 10 en vez de 10.0)
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
      description: json['description'] as String?,
      // Parseamos el string de fecha que manda NestJS a un objeto DateTime de Dart
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accountId': accountId,
      'accountName': accountName,
      'paymentMethodId': paymentMethodId,
      'paymentMethodName': paymentMethodName,
      'businessId': businessId,
      'saleId': saleId,
      'amount': amount,
      'type': type,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
