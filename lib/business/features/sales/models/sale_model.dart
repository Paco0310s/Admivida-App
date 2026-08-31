class SaleDetailModel {
  final String id;
  final String saleId;
  final String productVariantId;
  final String productNameSnapshot;
  final double quantity;
  final double originalPriceSnapshot;
  final double productPriceSnapshot;
  final double? productCostSnapshot;
  final String priceType;
  final String? commentary;
  final bool isPaid;
  final double sellerComissionSnapshot;
  final bool isComissionPaid;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? productId;

  // Campos extra para la UI
  final double subtotal;
  final String? imageUrl;

  const SaleDetailModel({
    required this.id,
    required this.saleId,
    required this.productVariantId,
    required this.productId,
    required this.productNameSnapshot,
    required this.quantity,
    required this.originalPriceSnapshot,
    required this.productPriceSnapshot,
    this.productCostSnapshot,
    required this.priceType,
    this.commentary,
    required this.isPaid,
    required this.sellerComissionSnapshot,
    required this.isComissionPaid,
    required this.createdAt,
    required this.updatedAt,
    required this.subtotal,
    this.imageUrl,
  });

  factory SaleDetailModel.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num? ?? 0).toDouble();
    final price = (json['productPriceSnapshot'] as num? ?? 0).toDouble();

    return SaleDetailModel(
      id: json['id'] as String? ?? '',
      saleId: json['saleId'] as String? ?? '',
      productVariantId: json['productVariantId'] as String? ?? '',
      productId: json['productId'] as String?,
      productNameSnapshot: json['productNameSnapshot'] as String? ?? '',
      quantity: qty,
      originalPriceSnapshot: (json['originalPriceSnapshot'] as num? ?? 0).toDouble(),
      productPriceSnapshot: price,
      productCostSnapshot: (json['productCostSnapshot'] as num?)?.toDouble(),
      priceType: json['priceType'] as String? ?? '',
      commentary: json['commentary'] as String?,
      isPaid: json['isPaid'] as bool? ?? false,
      sellerComissionSnapshot: (json['sellerComissionSnapshot'] as num? ?? 0).toDouble(),
      isComissionPaid: json['isComissionPaid'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
      // Si el JSON trae subtotal lo usa, si no, lo calcula automáticamente
      subtotal: json['subtotal'] != null ? (json['subtotal'] as num).toDouble() : (qty * price),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'saleId': saleId,
      'productVariantId': productVariantId,
      'productId': productId,
      'productNameSnapshot': productNameSnapshot,
      'quantity': quantity,
      'originalPriceSnapshot': originalPriceSnapshot,
      'productPriceSnapshot': productPriceSnapshot,
      'productCostSnapshot': productCostSnapshot,
      'priceType': priceType,
      'commentary': commentary,
      'isPaid': isPaid,
      'sellerComissionSnapshot': sellerComissionSnapshot,
      'isComissionPaid': isComissionPaid,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'subtotal': subtotal,
      'imageUrl': imageUrl,
    };
  }
}

class SaleModel {
  final String id;
  final String businessId;
  final String sellerUserId;
  final String? sellerName;
  final String? clientUserId;
  final String clientNameSnapshot;
  final String status;
  final double discountAmount;
  final double? amountPaid;
  final double? changeGiven;
  final double totalPriceSnapshot;
  final String? notes;
  final double? latitude;
  final double? longitude;
  final List<SaleDetailModel> details;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SaleModel({
    required this.id,
    required this.businessId,
    required this.sellerUserId,
    this.sellerName,
    this.clientUserId,
    required this.clientNameSnapshot,
    required this.status,
    required this.discountAmount,
    this.amountPaid,
    this.changeGiven,
    required this.totalPriceSnapshot,
    this.notes,
    this.latitude,
    this.longitude,
    required this.details,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SaleModel.fromJson(Map<String, dynamic> json) {
    return SaleModel(
      id: json['id'] as String? ?? '',
      businessId: json['businessId'] as String? ?? '',
      sellerUserId: json['sellerUserId'] as String? ?? '',
      sellerName: json['sellerName'] as String?,
      clientUserId: json['clientUserId'] as String?,
      clientNameSnapshot: json['clientNameSnapshot'] as String? ?? 'Público General',
      status: json['status'] as String? ?? '',
      discountAmount: (json['discountAmount'] as num? ?? 0).toDouble(),
      amountPaid: (json['amountPaid'] as num?)?.toDouble(),
      changeGiven: (json['changeGiven'] as num?)?.toDouble(),
      totalPriceSnapshot: (json['totalPriceSnapshot'] as num? ?? 0).toDouble(),
      notes: json['notes'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      details: (json['details'] as List<dynamic>?)?.map((item) => SaleDetailModel.fromJson(item as Map<String, dynamic>)).toList() ?? [],
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'sellerUserId': sellerUserId,
      'sellerName': sellerName,
      'clientUserId': clientUserId,
      'clientNameSnapshot': clientNameSnapshot,
      'status': status,
      'discountAmount': discountAmount,
      'amountPaid': amountPaid,
      'changeGiven': changeGiven,
      'totalPriceSnapshot': totalPriceSnapshot,
      'notes': notes,
      'latitude': latitude,
      'longitude': longitude,
      'details': details.map((d) => d.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
