class EmployeePaymentResponseModel {
  final String id;
  final String businessId;
  final String employeeUserId;
  final double amount;
  final String? notes;
  final String? expenseTransactionId;
  final String? incomeTransactionId;
  final DateTime? createdAt;

  EmployeePaymentResponseModel({
    required this.id,
    required this.businessId,
    required this.employeeUserId,
    required this.amount,
    this.notes,
    this.expenseTransactionId,
    this.incomeTransactionId,
    this.createdAt,
  });

  factory EmployeePaymentResponseModel.fromJson(Map<String, dynamic> json) {
    return EmployeePaymentResponseModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      employeeUserId: json['employeeUserId'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      expenseTransactionId: json['expenseTransactionId'] as String?,
      incomeTransactionId: json['incomeTransactionId'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}
