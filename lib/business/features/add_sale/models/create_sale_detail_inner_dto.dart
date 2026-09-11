import 'package:uuid/uuid.dart';

class CreateSaleDetailInnerDto {
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
}
