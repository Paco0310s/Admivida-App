// create_commission_payment_dto.dart

class CommissionPaymentItemDto {
  final String saleDetailId;
  final double amountToPay;

  CommissionPaymentItemDto({required this.saleDetailId, required this.amountToPay});

  Map<String, dynamic> toJson() {
    return {'saleDetailId': saleDetailId, 'amountToPay': amountToPay};
  }
}

class CreateCommissionPaymentDto {
  final String sellerUserId;
  final String? notes;
  final List<CommissionPaymentItemDto> items;
  final String sourceAccountId;
  final String destinationAccountId;
  final String paymentMethodId;
  final double paidAmount;

  CreateCommissionPaymentDto({
    required this.sellerUserId,
    this.notes,
    required this.items,
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.paymentMethodId,
    required this.paidAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'sellerUserId': sellerUserId,
      'notes': notes,
      'items': items.map((item) => item.toJson()).toList(),
      'sourceAccountId': sourceAccountId,
      'destinationAccountId': destinationAccountId,
      'paymentMethodId': paymentMethodId,
      'paidAmount': paidAmount,
    };
  }
}
