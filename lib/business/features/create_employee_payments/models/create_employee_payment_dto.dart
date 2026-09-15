class CreateEmployeePaymentDto {
  final String employeeUserId;
  final double amount;
  final String? notes;
  final String sourceAccountId;
  final String destinationAccountId;
  final String paymentMethodId;

  CreateEmployeePaymentDto({
    required this.employeeUserId,
    required this.amount,
    this.notes,
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.paymentMethodId,
  });

  Map<String, dynamic> toJson() {
    return {
      'employeeUserId': employeeUserId,
      'amount': amount,
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      'sourceAccountId': sourceAccountId,
      'destinationAccountId': destinationAccountId,
      'paymentMethodId': paymentMethodId,
    };
  }
}
