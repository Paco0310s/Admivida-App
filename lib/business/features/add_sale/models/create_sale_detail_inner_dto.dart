import 'package:uuid/uuid.dart';

class CreateSaleDetailInnerDto {
  static const String commonProductPlaceholderVariantId = '00000000-0000-4000-8000-000000000001';

  // --------------------------------------------------------
  // 1. FIELDS FOR THE BACKEND (Included in toJson)
  // --------------------------------------------------------
  final String productVariantId;
  final double quantity;
  final double unitPrice; // Corresponds to productPriceSnapshot
  final String? commentary;
  final String productNameSnapshot;
  final double originalPriceSnapshot;
  final String priceType; // 'RETAIL', 'WHOLESALE', 'CUSTOM'
  final bool isPaid; // Flag to indicate if the individual item has been paid

  // --------------------------------------------------------
  // 2. FIELDS FOR UI ONLY (Not sent to NestJS)
  // --------------------------------------------------------
  final String id; // Unique temporary ID for the cart list
  final String? imageUrl;
  final double subtotal;
  final bool allowFractions; // False = solo piezas enteras; True = granel o producto común
  final double? availableStock; // Stock disponible en inventario (null = ilimitado / producto común)

  bool get isCommonProduct => productVariantId == commonProductPlaceholderVariantId;

  CreateSaleDetailInnerDto({
    String? id,
    required this.productVariantId,
    required this.quantity,
    required this.unitPrice,
    this.commentary,
    required this.productNameSnapshot,
    required this.originalPriceSnapshot,
    required this.priceType,
    this.isPaid = true, // Default to true
    this.imageUrl,
    required this.subtotal,
    this.allowFractions = false,
    this.availableStock,
  }) : id = id ?? const Uuid().v4(); // Generates an automatic ID if none is passed

  /// Allows Riverpod to update quantity while keeping immutability
  CreateSaleDetailInnerDto copyWith({
    String? id,
    String? productVariantId,
    double? quantity,
    double? unitPrice,
    String? commentary,
    String? productNameSnapshot,
    double? originalPriceSnapshot,
    String? priceType,
    bool? isPaid,
    String? imageUrl,
    double? subtotal,
    bool? allowFractions,
    double? availableStock,
  }) {
    return CreateSaleDetailInnerDto(
      id: id ?? this.id,
      productVariantId: productVariantId ?? this.productVariantId,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      commentary: commentary ?? this.commentary,
      productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
      originalPriceSnapshot: originalPriceSnapshot ?? this.originalPriceSnapshot,
      priceType: priceType ?? this.priceType,
      isPaid: isPaid ?? this.isPaid,
      imageUrl: imageUrl ?? this.imageUrl,
      subtotal: subtotal ?? this.subtotal,
      allowFractions: allowFractions ?? this.allowFractions,
      availableStock: availableStock ?? this.availableStock,
    );
  }

  /// Cleans and formats data to send to NestJS
  Map<String, dynamic> toJson() {
    return {
      'productVariantId': productVariantId,
      'quantity': quantity,
      'productPriceSnapshot': unitPrice, // Mapped correctly for NestJS backend expectation
      'originalPriceSnapshot': originalPriceSnapshot,
      'productNameSnapshot': productNameSnapshot,
      'priceType': priceType,
      'isPaid': isPaid,
      if (commentary != null && commentary!.trim().isNotEmpty) 'commentary': commentary!.trim(),
    };
  }

  /// Includes UI fields (`id`, `imageUrl`, `subtotal`) for local Isar persistence (offline queue / held tickets)
  Map<String, dynamic> toLocalJson() {
    return {
      ...toJson(),
      'id': id,
      'imageUrl': imageUrl,
      'subtotal': subtotal,
      'allowFractions': allowFractions,
      if (availableStock != null) 'availableStock': availableStock,
    };
  }

  factory CreateSaleDetailInnerDto.fromJson(Map<String, dynamic> json) {
    final qty = (json['quantity'] as num? ?? 1).toDouble();
    final price = (json['productPriceSnapshot'] as num? ?? json['unitPrice'] as num? ?? 0).toDouble();
    final origPrice = (json['originalPriceSnapshot'] as num? ?? price).toDouble();
    final variantId = json['productVariantId'] as String? ?? '';
    return CreateSaleDetailInnerDto(
      id: json['id'] as String?,
      productVariantId: variantId,
      quantity: qty,
      unitPrice: price,
      commentary: json['commentary'] as String?,
      productNameSnapshot: json['productNameSnapshot'] as String? ?? '',
      originalPriceSnapshot: origPrice,
      priceType: json['priceType'] as String? ?? 'RETAIL',
      isPaid: json['isPaid'] as bool? ?? true,
      imageUrl: json['imageUrl'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? (qty * price),
      allowFractions: json['allowFractions'] as bool? ?? (variantId == commonProductPlaceholderVariantId || qty != qty.roundToDouble()),
      availableStock: (json['availableStock'] as num?)?.toDouble(),
    );
  }
}
