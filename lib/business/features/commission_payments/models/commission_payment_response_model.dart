// commission_payment_response_model.dart

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
      soldAt: DateTime.parse(json['soldAt'] as String),
    );
  }
}

class CommissionPaymentResponseModel {
  final String id;
  final String businessId;
  final String sellerUserId;
  final double totalAmount;
  final String? transactionId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CommissionPaymentDetailModel> details;

  CommissionPaymentResponseModel({
    required this.id,
    required this.businessId,
    required this.sellerUserId,
    required this.totalAmount,
    this.transactionId,
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
      totalAmount: (json['totalAmount'] as num).toDouble(),
      transactionId: json['transactionId'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      details: (json['details'] as List<dynamic>).map((item) => CommissionPaymentDetailModel.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}
