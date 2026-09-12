class CommissionPaymentSummaryModel {
  final double totalCalculatedAmount;
  final double totalPaidAmount;
  final double totalPendingAmount;
  final int totalPaymentsCount;
  final int totalPendingCount;

  CommissionPaymentSummaryModel({
    required this.totalCalculatedAmount,
    required this.totalPaidAmount,
    required this.totalPendingAmount,
    required this.totalPaymentsCount,
    required this.totalPendingCount,
  });

  factory CommissionPaymentSummaryModel.fromJson(Map<String, dynamic> json) {
    return CommissionPaymentSummaryModel(
      totalCalculatedAmount: (json['totalCalculatedAmount'] as num).toDouble(),
      totalPaidAmount: (json['totalPaidAmount'] as num).toDouble(),
      totalPendingAmount: (json['totalPendingAmount'] as num).toDouble(),
      totalPaymentsCount: json['totalPaymentsCount'] as int,
      totalPendingCount: json['totalPendingCount'] as int,
    );
  }
}

class CommissionPaymentDetailModel {
  final String saleDetailId;
  final String saleId;
  final String productVariantId;
  final String productName;
  final double quantity;
  final double commission;
  final DateTime soldAt;

  CommissionPaymentDetailModel({
    required this.saleDetailId,
    required this.saleId,
    required this.productVariantId,
    required this.productName,
    required this.quantity,
    required this.commission,
    required this.soldAt,
  });

  factory CommissionPaymentDetailModel.fromJson(Map<String, dynamic> json) {
    return CommissionPaymentDetailModel(
      saleDetailId: json['saleDetailId'] as String,
      saleId: json['saleId'] as String,
      productVariantId: json['productVariantId'] as String,
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      commission: (json['commission'] as num).toDouble(),
      soldAt: DateTime.parse(json['soldAt'] as String),
    );
  }
}

class CommissionPaymentItemModel {
  final String id;
  final String businessId;
  final String sellerUserId;
  final String sellerName;
  final double calculatedTotalAmount;
  final double paidAmount;
  final String? expenseTransactionId;
  final String? incomeTransactionId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CommissionPaymentDetailModel> details;

  CommissionPaymentItemModel({
    required this.id,
    required this.businessId,
    required this.sellerUserId,
    required this.sellerName,
    required this.calculatedTotalAmount,
    required this.paidAmount,
    this.expenseTransactionId,
    this.incomeTransactionId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.details,
  });

  factory CommissionPaymentItemModel.fromJson(Map<String, dynamic> json) {
    return CommissionPaymentItemModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      sellerUserId: json['sellerUserId'] as String,
      sellerName: json['sellerName'] as String,
      calculatedTotalAmount: (json['calculatedTotalAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      expenseTransactionId: json['expenseTransactionId'] as String?,
      incomeTransactionId: json['incomeTransactionId'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      details: (json['details'] as List<dynamic>).map((item) => CommissionPaymentDetailModel.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}

class CommissionPaymentHistoryResponseModel {
  final CommissionPaymentSummaryModel summary;
  final List<CommissionPaymentItemModel> payments;

  CommissionPaymentHistoryResponseModel({required this.summary, required this.payments});

  factory CommissionPaymentHistoryResponseModel.fromJson(Map<String, dynamic> json) {
    return CommissionPaymentHistoryResponseModel(
      summary: CommissionPaymentSummaryModel.fromJson(json['summary'] as Map<String, dynamic>),
      payments: (json['payments'] as List<dynamic>).map((item) => CommissionPaymentItemModel.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }
}
