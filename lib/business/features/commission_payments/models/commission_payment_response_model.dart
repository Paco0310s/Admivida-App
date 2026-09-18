class CommissionPaymentDetailModel {
  final String saleDetailId;
  final String saleId;
  final String productName;
  final double quantity;
  final double commission;
  final DateTime soldAt;

  CommissionPaymentDetailModel({
    required this.saleDetailId,
    required this.saleId,
    required this.productName,
    required this.quantity,
    required this.commission,
    required this.soldAt,
  });

  factory CommissionPaymentDetailModel.fromJson(Map<String, dynamic> json) {
    return CommissionPaymentDetailModel(
      saleDetailId: json['saleDetailId'] as String,
      saleId: json['saleId'] as String,
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      commission: (json['commission'] as num).toDouble(),
      soldAt: DateTime.parse(json['soldAt'] as String).toLocal(),
    );
  }
}

class CommissionPaymentResponseModel {
  final String id;
  final String businessId;
  final String sellerUserId;
  final double calculatedTotalAmount;
  final double paidAmount;
  final String? expenseTransactionId;
  final String? incomeTransactionId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CommissionPaymentDetailModel> details;

  CommissionPaymentResponseModel({
    required this.id,
    required this.businessId,
    required this.sellerUserId,
    required this.calculatedTotalAmount,
    required this.paidAmount,
    this.expenseTransactionId,
    this.incomeTransactionId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.details,
  });

  factory CommissionPaymentResponseModel.fromJson(Map<String, dynamic> json) {
    return CommissionPaymentResponseModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      sellerUserId: json['sellerUserId'] as String,
      calculatedTotalAmount: (json['calculatedTotalAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      expenseTransactionId: json['expenseTransactionId'] as String?,
      incomeTransactionId: json['incomeTransactionId'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      details: (json['details'] as List<dynamic>).map((item) => CommissionPaymentDetailModel.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}
