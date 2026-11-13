class InventoryMovementModel {
  final String id;
  final String variantId;
  final String? variantName;
  final String? sku;
  final String type; // 'IN' | 'OUT'
  final String reason; // SALE, PURCHASE, ADJUSTMENT, WASTE, MANUFACTURE, RETURN
  final double quantity;
  final double previousStock;
  final double newStock;
  final String? reference;
  final String? notes;
  final DateTime createdAt;

  const InventoryMovementModel({
    required this.id,
    required this.variantId,
    this.variantName,
    this.sku,
    required this.type,
    required this.reason,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.reference,
    this.notes,
    required this.createdAt,
  });

  bool get isEntry => type.toUpperCase() == 'IN';

  String get reasonLabel {
    switch (reason.toUpperCase()) {
      case 'SALE':
        return 'Venta';
      case 'PURCHASE':
        return 'Surtido / Compra';
      case 'MANUFACTURE':
        return 'Producción';
      case 'RETURN':
        return 'Devolución';
      case 'WASTE':
        return 'Merma / Caducidad';
      case 'ADJUSTMENT':
      default:
        return 'Ajuste manual';
    }
  }

  factory InventoryMovementModel.fromJson(Map<String, dynamic> json) {
    return InventoryMovementModel(
      id: json['id'] as String? ?? '',
      variantId: json['variantId'] as String? ?? '',
      variantName: json['variantName'] as String?,
      sku: json['sku'] as String?,
      type: json['type'] as String? ?? 'IN',
      reason: json['reason'] as String? ?? 'ADJUSTMENT',
      quantity: (json['quantity'] as num? ?? 0).toDouble(),
      previousStock: (json['previousStock'] as num? ?? 0).toDouble(),
      newStock: (json['newStock'] as num? ?? 0).toDouble(),
      reference: json['reference'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
    );
  }
}
