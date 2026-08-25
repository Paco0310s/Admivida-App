class CreateTransactionDto {
  final String type;
  final double amount;
  final String description;
  final String paymentMethodId;
  final String accountId;
  final String? businessId;
  final String? saleId;

  CreateTransactionDto({
    required this.type,
    required this.amount,
    required this.description,
    required this.paymentMethodId,
    required this.accountId,
    this.businessId,
    this.saleId,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'amount': amount,
      'description': description,
      'paymentMethodId': paymentMethodId,
      'accountId': accountId,
      if (businessId != null) 'businessId': businessId,
      if (saleId != null) 'saleId': saleId,
    };
  }
}
