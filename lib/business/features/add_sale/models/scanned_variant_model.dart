class ScannedVariantModel {
  final String id;
  final String productId;
  final String sku;
  final String? barcode;
  final String? name;
  final double purchasePrice;
  final double salePrice;
  final double? wholesalePrice;
  final double? wholesaleQuantity;
  final double stockQuantity;
  final double? minimumStock;
  final double? maximumStock;
  final dynamic attributes;
  final List<String> images;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ScannedVariantModel({
    required this.id,
    required this.productId,
    required this.sku,
    this.barcode,
    this.name,
    required this.purchasePrice,
    required this.salePrice,
    this.wholesalePrice,
    this.wholesaleQuantity,
    required this.stockQuantity,
    this.minimumStock,
    this.maximumStock,
    this.attributes,
    required this.images,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor to create an instance from a JSON map
  factory ScannedVariantModel.fromJson(Map<String, dynamic> json) {
    return ScannedVariantModel(
      id: json['id'] as String,
      productId: json['productId'] as String,
      sku: json['sku'] as String,
      barcode: json['barcode'] as String?,
      name: json['name'] as String?,
      // Safely parsing numeric values to double
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0.0,
      wholesalePrice: (json['wholesalePrice'] as num?)?.toDouble(),
      wholesaleQuantity: (json['wholesaleQuantity'] as num?)?.toDouble(),
      stockQuantity: (json['stockQuantity'] as num?)?.toDouble() ?? 0.0,
      minimumStock: (json['minimumStock'] as num?)?.toDouble(),
      maximumStock: (json['maximumStock'] as num?)?.toDouble(),
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
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }
}
