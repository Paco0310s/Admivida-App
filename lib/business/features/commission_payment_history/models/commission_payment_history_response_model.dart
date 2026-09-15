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

  /// Factory constructor to parse the detailed summary JSON from the backend
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

  /// Factory constructor to parse individual sale detail items for commissions
  factory CommissionPaymentDetailModel.fromJson(Map<String, dynamic> json) {
    return CommissionPaymentDetailModel(
      saleDetailId: json['saleDetailId'] as String,
      saleId: json['saleId'] as String,
      productVariantId: json['productVariantId'] as String,
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      commission: (json['commission'] as num).toDouble(),
      // Converting UTC date from backend to device's local timezone
      soldAt: DateTime.parse(json['soldAt'] as String).toLocal(),
    );
  }
}

class CommissionPaymentItemModel {
  final String id;
  final String businessId;
  final String employeeUserId;
  final String employeeName;
  final String type; // Identifier: 'COMMISSION' or 'FREE_PAYMENT'
  final double calculatedTotalAmount;
  final double paidAmount;
  final String? expenseTransactionId;
  final String? incomeTransactionId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<CommissionPaymentDetailModel> details; // Empty list [] for free payments

  CommissionPaymentItemModel({
    required this.id,
    required this.businessId,
    required this.employeeUserId,
    required this.employeeName,
    required this.type,
    required this.calculatedTotalAmount,
    required this.paidAmount,
    this.expenseTransactionId,
    this.incomeTransactionId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.details,
  });

  /// Factory constructor to parse unified payment items (commissions or free payments)
  factory CommissionPaymentItemModel.fromJson(Map<String, dynamic> json) {
    return CommissionPaymentItemModel(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      employeeUserId: json['employeeUserId'] as String,
      employeeName: json['employeeName'] as String,
      type: json['type'] as String? ?? 'COMMISSION', // Fallback safety for legacy records
      calculatedTotalAmount: (json['calculatedTotalAmount'] as num).toDouble(),
      paidAmount: (json['paidAmount'] as num).toDouble(),
      expenseTransactionId: json['expenseTransactionId'] as String?,
      incomeTransactionId: json['incomeTransactionId'] as String?,
      notes: json['notes'] as String?,
      // Converting UTC dates from backend to device's local timezone
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updatedAt'] as String).toLocal(),
      details:
          (json['details'] as List<dynamic>?)?.map((item) => CommissionPaymentDetailModel.fromJson(item as Map<String, dynamic>)).toList() ??
          [], // Safely handles empty or null details for free payments
    );
  }
}

class CommissionPaymentHistoryResponseModel {
  final CommissionPaymentSummaryModel summary;
  final List<CommissionPaymentItemModel> payments;

  CommissionPaymentHistoryResponseModel({required this.summary, required this.payments});

  /// Factory constructor to parse the complete unified history response from the backend
  factory CommissionPaymentHistoryResponseModel.fromJson(Map<String, dynamic> json) {
    return CommissionPaymentHistoryResponseModel(
      // Accessing the nested 'summary' object
      summary: CommissionPaymentSummaryModel.fromJson(json['summary'] as Map<String, dynamic>),
      payments: (json['payments'] as List<dynamic>?)?.map((item) => CommissionPaymentItemModel.fromJson(item as Map<String, dynamic>)).toList() ?? [],
    );
  }
}
