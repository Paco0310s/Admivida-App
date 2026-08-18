/// DTO representing an image entry when attaching uploaded files to a product or variant.
class CreateProductImageDto {
  final String fileId;
  final bool main;

  const CreateProductImageDto({required this.fileId, this.main = false});

  Map<String, dynamic> toJson() {
    return {'fileId': fileId, 'main': main};
  }
}

/// DTO representing a product variant payload when creating a new product.
class CreateProductVariantDto {
  final String? productId;
  final String? sku;
  final String? barcode;
  final String? name;
  final double? purchasePrice;
  final double salePrice;
  final double? wholesalePrice;
  final double? wholesaleQuantity;
  final double? stockQuantity;
  final double? minimumStock;
  final double? maximumStock;
  final Map<String, dynamic>? attributes;
  final List<CreateProductImageDto> images; // 👈 Agregado soporte de imágenes por variante

  const CreateProductVariantDto({
    this.productId,
    this.sku,
    this.barcode,
    this.name,
    this.purchasePrice,
    required this.salePrice,
    this.wholesalePrice,
    this.wholesaleQuantity,
    this.stockQuantity,
    this.minimumStock,
    this.maximumStock,
    this.attributes,
    this.images = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      if (productId != null && productId!.isNotEmpty) 'productId': productId,
      if (sku != null && sku!.isNotEmpty) 'sku': sku,
      if (barcode != null && barcode!.isNotEmpty) 'barcode': barcode,
      if (name != null && name!.isNotEmpty) 'name': name,
      if (purchasePrice != null) 'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      if (wholesalePrice != null) 'wholesalePrice': wholesalePrice,
      if (wholesaleQuantity != null) 'wholesaleQuantity': wholesaleQuantity,
      if (stockQuantity != null) 'stockQuantity': stockQuantity,
      if (minimumStock != null) 'minimumStock': minimumStock,
      if (maximumStock != null) 'maximumStock': maximumStock,
      if (attributes != null && attributes!.isNotEmpty) 'attributes': attributes,
      if (images.isNotEmpty) 'images': images.map((i) => i.toJson()).toList(),
    };
  }
}

/// Root DTO required by NestJS to create a new Product.
class CreateProductDto {
  final String businessId;
  final String productTypeId;
  final String? productCategoryId;
  final String name;
  final String? description;
  final String unitOfMeasure; // Allowed values: 'PZ', 'KG', 'LT', 'ML'
  final bool isActive;
  final List<CreateProductVariantDto> variants;
  final List<CreateProductImageDto> images; // Imágenes generales del producto

  const CreateProductDto({
    required this.businessId,
    required this.productTypeId,
    this.productCategoryId,
    required this.name,
    this.description,
    this.unitOfMeasure = 'PZ',
    this.isActive = true,
    required this.variants,
    this.images = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'productTypeId': productTypeId,
      if (productCategoryId != null && productCategoryId!.isNotEmpty) 'productCategoryId': productCategoryId,
      'name': name,
      if (description != null && description!.isNotEmpty) 'description': description,
      'unitOfMeasure': unitOfMeasure,
      'isActive': isActive,
      'variants': variants.map((v) => v.toJson()).toList(),
      if (images.isNotEmpty) 'images': images.map((i) => i.toJson()).toList(),
    };
  }
}
