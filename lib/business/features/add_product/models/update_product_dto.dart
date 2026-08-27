class UpdateProductImageDto {
  final String? id;
  final String fileId;
  final bool main;

  const UpdateProductImageDto({this.id, required this.fileId, this.main = false});

  Map<String, dynamic> toJson() {
    return {if (id != null && id!.isNotEmpty) 'id': id, 'fileId': fileId, 'main': main};
  }
}

class UpdateProductVariantDto {
  final String? id; // Si es null, NestJS creará la variante
  final String? sku;
  final String? barcode;
  final String? name;
  final double? purchasePrice;
  final double? salePrice;
  final double? wholesalePrice;
  final double? wholesaleQuantity;
  final double? stockQuantity;
  final double? minimumStock;
  final double? maximumStock;
  final Map<String, dynamic>? attributes;
  final List<UpdateProductImageDto>? images;

  UpdateProductVariantDto({
    this.id,
    this.sku,
    this.barcode,
    this.name,
    this.purchasePrice,
    this.salePrice,
    this.wholesalePrice,
    this.wholesaleQuantity,
    this.stockQuantity,
    this.minimumStock,
    this.maximumStock,
    this.attributes,
    this.images,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null && id!.isNotEmpty) 'id': id,
      if (sku != null && sku!.isNotEmpty) 'sku': sku,
      if (barcode != null && barcode!.isNotEmpty) 'barcode': barcode,
      if (name != null && name!.isNotEmpty) 'name': name,
      if (purchasePrice != null) 'purchasePrice': purchasePrice,
      if (salePrice != null) 'salePrice': salePrice,
      if (wholesalePrice != null) 'wholesalePrice': wholesalePrice,
      if (wholesaleQuantity != null) 'wholesaleQuantity': wholesaleQuantity,
      if (stockQuantity != null) 'stockQuantity': stockQuantity,
      if (minimumStock != null) 'minimumStock': minimumStock,
      if (maximumStock != null) 'maximumStock': maximumStock,
      if (attributes != null && attributes!.isNotEmpty) 'attributes': attributes,
      if (images != null && images!.isNotEmpty) 'images': images!.map((i) => i.toJson()).toList(),
    };
  }
}

class UpdateProductDto {
  final String? name;
  final String? description;
  final String? unitOfMeasure;
  final bool? isActive;
  final String? productTypeId;
  final String? productCategoryId;
  final List<UpdateProductVariantDto>? variants;
  final List<UpdateProductImageDto>? images;

  UpdateProductDto({this.name, this.description, this.unitOfMeasure, this.isActive, this.productTypeId, this.productCategoryId, this.variants, this.images});

  Map<String, dynamic> toJson() {
    return {
      if (name != null && name!.isNotEmpty) 'name': name,
      if (description != null && description!.isNotEmpty) 'description': description,
      if (unitOfMeasure != null && unitOfMeasure!.isNotEmpty) 'unitOfMeasure': unitOfMeasure,
      if (isActive != null) 'isActive': isActive,
      if (productTypeId != null && productTypeId!.isNotEmpty) 'productTypeId': productTypeId,
      if (productCategoryId != null && productCategoryId!.isNotEmpty) 'productCategoryId': productCategoryId,
      if (variants != null && variants!.isNotEmpty) 'variants': variants!.map((v) => v.toJson()).toList(),
      if (images != null && images!.isNotEmpty) 'images': images!.map((i) => i.toJson()).toList(),
    };
  }
}
