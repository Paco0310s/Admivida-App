class ScannedVariantModel {
  final String id;
  final String productId;
  final String? sku;
  final String? barcode;
  final String? name;
  final double purchasePrice;
  final double salePrice;
  final double? wholesalePrice;
  final double? wholesaleQuantity;
  final double stockQuantity;
  final double? minimumStock;
  final double? maximumStock;
  final DateTime? expirationDate;
  final dynamic attributes;
  final List<String> images;
  final bool allowFractions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ScannedVariantModel({
    required this.id,
    required this.productId,
    this.sku,
    this.barcode,
    this.name,
    required this.purchasePrice,
    required this.salePrice,
    this.wholesalePrice,
    this.wholesaleQuantity,
    required this.stockQuantity,
    this.minimumStock,
    this.maximumStock,
    this.expirationDate,
    this.attributes,
    required this.images,
    this.allowFractions = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to create an instance from a JSON map
  factory ScannedVariantModel.fromJson(Map<String, dynamic> json) {
    final productMap = json['product'] is Map<String, dynamic> ? json['product'] as Map<String, dynamic> : null;
    final unitOfMeasure = (productMap?['unitOfMeasure'] as String? ?? 'PZ').trim().toUpperCase();
    final productAllowFractions = productMap?['allowFractions'] as bool? ??
        (productMap?['productType'] is Map<String, dynamic> ? productMap!['productType']['allowFractions'] as bool? : null) ??
        (unitOfMeasure != 'PZ' && unitOfMeasure != 'PZA' && unitOfMeasure != 'PIEZA');

    return ScannedVariantModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      name: json['name'] as String?,
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0.0,
      wholesalePrice: (json['wholesalePrice'] as num?)?.toDouble(),
      wholesaleQuantity: (json['wholesaleQuantity'] as num?)?.toDouble(),
      stockQuantity: (json['stockQuantity'] as num?)?.toDouble() ?? 0.0,
      minimumStock: (json['minimumStock'] as num?)?.toDouble(),
      maximumStock: (json['maximumStock'] as num?)?.toDouble(),
      expirationDate: json['expirationDate'] != null ? DateTime.tryParse(json['expirationDate'] as String)?.toLocal() : null,
      attributes: json['attributes'],
      images:
          (json['images'] as List<dynamic>?)
              ?.map((e) {
                if (e is Map<String, dynamic> && e['url'] != null) {
                  return e['url'].toString();
                }
                return null;
              })
              .whereType<String>()
              .toList() ??
          [],
      allowFractions: (json['allowFractions'] as bool?) ?? productAllowFractions,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String)?.toLocal() : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String)?.toLocal() : null,
    );
  }
}
