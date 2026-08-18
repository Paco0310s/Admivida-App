import 'dart:convert';

/// Model representing a product variant (e.g., specific size, flavor, or SKU).
class ProductVariantModel {
  final String id;
  final String productId;
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
  final List<ProductImageModel> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductVariantModel({
    required this.id,
    required this.productId,
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
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      id: json['id'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      name: json['name'] as String?,
      purchasePrice: _toDoubleOrNull(json['purchasePrice']),
      salePrice: _toDouble(json['salePrice']),
      wholesalePrice: _toDoubleOrNull(json['wholesalePrice']),
      wholesaleQuantity: _toDoubleOrNull(json['wholesaleQuantity']),
      stockQuantity: _toDoubleOrNull(json['stockQuantity']),
      minimumStock: _toDoubleOrNull(json['minimumStock']),
      maximumStock: _toDoubleOrNull(json['maximumStock']),
      attributes: json['attributes'] is Map<String, dynamic> ? Map<String, dynamic>.from(json['attributes']) : null,
      images: (json['images'] as List<dynamic>?)?.map((i) => ProductImageModel.fromJson(i as Map<String, dynamic>)).toList() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'sku': sku,
      'barcode': barcode,
      'name': name,
      'purchasePrice': purchasePrice,
      'salePrice': salePrice,
      'wholesalePrice': wholesalePrice,
      'wholesaleQuantity': wholesaleQuantity,
      'stockQuantity': stockQuantity,
      'minimumStock': minimumStock,
      'maximumStock': maximumStock,
      'attributes': attributes,
      'images': images.map((i) => i.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Model representing an image associated with a product.
class ProductImageModel {
  final String id;
  final String url;
  final String? blurHash;
  final bool main;

  const ProductImageModel({required this.id, required this.url, this.blurHash, this.main = false});

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: json['id'] as String? ?? '',
      url: json['url'] as String? ?? '',
      blurHash: json['blurHash'] as String?,
      main: json['main'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'url': url, 'blurHash': blurHash, 'main': main};
  }
}

/// Pagination Metadata Model
class ProductsMetaModel {
  final int totalItems;
  final int itemCount;
  final int itemsPerPage;
  final int totalPages;
  final int currentPage;

  const ProductsMetaModel({required this.totalItems, required this.itemCount, required this.itemsPerPage, required this.totalPages, required this.currentPage});

  factory ProductsMetaModel.fromJson(Map<String, dynamic> json) {
    return ProductsMetaModel(
      totalItems: json['totalItems'] as int? ?? 0,
      itemCount: json['itemCount'] as int? ?? 0,
      itemsPerPage: json['itemsPerPage'] as int? ?? 0,
      totalPages: json['totalPages'] as int? ?? 0,
      currentPage: json['currentPage'] as int? ?? 0,
    );
  }
}

/// Paginated Products Wrapper
class ProductsPageModel {
  final List<ProductModel> data;
  final ProductsMetaModel? meta;

  const ProductsPageModel({required this.data, this.meta});

  factory ProductsPageModel.fromRawJson(String str) => ProductsPageModel.fromJson(json.decode(str));

  factory ProductsPageModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] as List<dynamic>? ?? const [];
    return ProductsPageModel(
      data: rawData.map((item) => ProductModel.fromJson(item as Map<String, dynamic>)).toList(),
      meta: json['meta'] != null ? ProductsMetaModel.fromJson(json['meta'] as Map<String, dynamic>) : null,
    );
  }
}

/// Root Model representing a Product in the catalog
class ProductModel {
  final String id;
  final String businessId;
  final String productTypeId;
  final String? productCategoryId;
  final String? productCategoryName;
  final String name;
  final String? description;
  final String unitOfMeasure;
  final bool isActive;
  final List<ProductVariantModel> variants;
  final List<ProductImageModel> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductModel({
    required this.id,
    required this.businessId,
    required this.productTypeId,
    this.productCategoryId,
    this.productCategoryName,
    required this.name,
    this.description,
    required this.unitOfMeasure,
    required this.isActive,
    required this.variants,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String? ?? '',
      businessId: json['businessId'] as String? ?? '',
      productTypeId: json['productTypeId'] as String? ?? '',
      productCategoryId: json['productCategoryId'] as String?,
      productCategoryName: json['productCategoryName'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      unitOfMeasure: json['unitOfMeasure'] as String? ?? 'PZ',
      isActive: json['isActive'] as bool? ?? true,
      variants: (json['variants'] as List<dynamic>?)?.map((v) => ProductVariantModel.fromJson(v as Map<String, dynamic>)).toList() ?? [],
      images: (json['images'] as List<dynamic>?)?.map((i) => ProductImageModel.fromJson(i as Map<String, dynamic>)).toList() ?? [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'productTypeId': productTypeId,
      'productCategoryId': productCategoryId,
      'productCategoryName': productCategoryName,
      'name': name,
      'description': description,
      'unitOfMeasure': unitOfMeasure,
      'isActive': isActive,
      'variants': variants.map((v) => v.toJson()).toList(),
      'images': images.map((i) => i.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // 💡 GETTERS AUXILIARES PARA LA UI

  String? get mainImageUrl {
    if (images.isNotEmpty) {
      final mainImage = images.firstWhere((img) => img.main, orElse: () => images.first);
      return mainImage.url;
    }
    // Si la variante tiene imagen propia
    if (defaultVariant != null && defaultVariant!.images.isNotEmpty) {
      return defaultVariant!.images.first.url;
    }
    return null;
  }

  ProductVariantModel? get defaultVariant {
    return variants.isNotEmpty ? variants.first : null;
  }

  double get defaultPrice {
    return defaultVariant?.salePrice ?? 0.0;
  }
}
