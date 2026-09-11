class PendingCommissionItem {
  final String saleDetailId;
  final String saleId;
  final String productName;
  final double quantity;
  final double commission;
  final DateTime soldAt;

  PendingCommissionItem({
    required this.saleDetailId,
    required this.saleId,
    required this.productName,
    required this.quantity,
    required this.commission,
    required this.soldAt,
  });

  factory PendingCommissionItem.fromJson(Map<String, dynamic> json) {
    return PendingCommissionItem(
      saleDetailId: json['saleDetailId'] as String,
      saleId: json['saleId'] as String,
      productName: json['productName'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      commission: (json['commission'] as num).toDouble(),
      soldAt: DateTime.parse(json['soldAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'saleDetailId': saleDetailId,
      'saleId': saleId,
      'productName': productName,
      'quantity': quantity,
      'commission': commission,
      'soldAt': soldAt.toIso8601String(),
    };
  }
}
