import 'package:uuid/uuid.dart';

class CreateSaleDetailInnerDto {
  // --------------------------------------------------------
  // 1. CAMPOS PARA EL BACKEND (Se incluyen en el toJson)
  // --------------------------------------------------------
  final String productVariantId;
  final double quantity;
  final double unitPrice; // Corresponde al productPriceSnapshot
  final String? commentary;
  final String productNameSnapshot;
  final double originalPriceSnapshot;
  final String priceType; // 'RETAIL', 'WHOLESALE', 'CUSTOM'

  // --------------------------------------------------------
  // 2. CAMPOS SOLO PARA LA UI (No se envían a NestJS)
  // --------------------------------------------------------
  final String id; // ID único temporal para el listado del carrito
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
    this.imageUrl,
    required this.subtotal,
  }) : id = id ?? const Uuid().v4(); // Genera un ID automático si no se le pasa

  /// Permite a Riverpod actualizar la cantidad manteniendo inmutabilidad
  CreateSaleDetailInnerDto copyWith({
    String? id,
    String? productVariantId,
    double? quantity,
    double? unitPrice,
    String? commentary,
    String? productNameSnapshot,
    double? originalPriceSnapshot,
    String? priceType,
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
      imageUrl: imageUrl ?? this.imageUrl,
      subtotal: subtotal ?? this.subtotal,
    );
  }

  /// Limpia los datos para enviar a NestJS
  Map<String, dynamic> toJson() {
    return {
      'productVariantId': productVariantId,
      'quantity': quantity,
      'unitPrice': unitPrice, // En NestJS podrías mapearlo a productPriceSnapshot
      'originalPriceSnapshot': originalPriceSnapshot,
      'productNameSnapshot': productNameSnapshot,
      'priceType': priceType,
      if (commentary != null && commentary!.trim().isNotEmpty) 'commentary': commentary!.trim(),
    };
  }
}

class CreateSaleDto {
  final String clientNameSnapshot;
  final double? latitude;
  final double? longitude;
  final String? clientUserId;
  final String sellerUserId;
  final String businessId;
  final String accountId;
  final String paymentMethodId;
  final String paymentMethodCode;
  final List<CreateSaleDetailInnerDto> items;

  CreateSaleDto({
    this.clientNameSnapshot = 'Público General',
    this.latitude,
    this.longitude,
    this.clientUserId,
    required this.sellerUserId,
    required this.businessId,
    required this.accountId,
    required this.paymentMethodId,
    required this.paymentMethodCode,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'clientNameSnapshot': clientNameSnapshot.isEmpty ? 'Público General' : clientNameSnapshot,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (clientUserId != null) 'clientUserId': clientUserId,
      'sellerUserId': sellerUserId,
      'businessId': businessId,
      'accountId': accountId,
      'paymentMethodId': paymentMethodId,
      'paymentMethodCode': paymentMethodCode,
      // Gracias a que nuestro DTO filtra los datos de UI, esto manda el payload perfecto
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
