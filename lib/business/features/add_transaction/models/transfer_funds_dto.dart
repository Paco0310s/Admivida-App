class TransferFundsDto {
  final double amount;
  final String description;
  final String fromAccountId;
  final String toAccountId;
  final String? businessId;

  TransferFundsDto({
    required this.amount,
    required this.description,
    required this.fromAccountId,
    required this.toAccountId,
    this.businessId,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'description': description,
      'fromAccountId': fromAccountId,
      'toAccountId': toAccountId,
      if (businessId != null && businessId!.isNotEmpty) 'businessId': businessId,
    };
  }
}
