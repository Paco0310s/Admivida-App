class PrintableRow {
  final double quantity;
  final String description;
  final double price; // Precio final cobrado unitario
  final double total; // Subtotal de la fila (quantity * price)
  final double? originalPrice; // Precio unitario de lista original antes de descuento manual

  const PrintableRow({
    required this.quantity,
    required this.description,
    required this.price,
    required this.total,
    this.originalPrice,
  });

  /// Indica si el producto tuvo un descuento manual
  bool get hasDiscount => originalPrice != null && originalPrice! > (price + 0.001);

  /// Monto unitario descontado
  double get unitDiscount => hasDiscount ? (originalPrice! - price) : 0.0;

  /// Monto total descontado para esta fila
  double get totalDiscount => unitDiscount * quantity;
}

class PrintablePayment {
  final String methodName;
  final double amount;

  const PrintablePayment({
    required this.methodName,
    required this.amount,
  });
}

class PrintableShiftLine {
  final String label;
  final String value;
  final bool isBold;
  final bool hrAfter;

  const PrintableShiftLine({
    required this.label,
    required this.value,
    this.isBold = false,
    this.hrAfter = false,
  });
}

class ObjectToPrint {
  // Cabecera
  final String businessName; // Nombre de la sucursal o empresa
  final String ticketId; // Folio
  final DateTime date; // Fecha y hora
  final String cashierName; // Vendedor / Cajero
  final String customerName; // Cliente (o Nombre de Caja en Corte)

  // Cuerpo
  final List<PrintableRow> rows;

  // Totales
  final double subtotal;
  final double discount;
  final double total;
  final double amountPaid;
  final double changeGiven;
  final List<PrintablePayment> payments;

  // Modo recibo de abono (opcional; por defecto imprime ticket de venta normal)
  final bool isPaymentReceipt;
  final double? previousBalance;
  final double? remainingBalance;

  // Modo Corte de Caja (Ticket X/Z)
  final bool isShiftCutReceipt;
  final String? shiftHeaderTitle;
  final List<PrintableShiftLine> shiftLines;

  final String footerMessage;

  // Configuración de hardware
  final bool openDrawer;

  const ObjectToPrint({
    required this.businessName,
    required this.ticketId,
    required this.date,
    required this.cashierName,
    required this.customerName,
    required this.rows,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.amountPaid,
    required this.changeGiven,
    this.payments = const [],
    this.isPaymentReceipt = false,
    this.previousBalance,
    this.remainingBalance,
    this.isShiftCutReceipt = false,
    this.shiftHeaderTitle,
    this.shiftLines = const [],
    this.footerMessage = '¡Gracias por su compra!',
    this.openDrawer = false,
  });

  /// Total acumulado de descuentos otorgados por cambio manual de precio en productos
  double get itemDiscountsTotal => rows.fold(0.0, (sum, r) => sum + r.totalDiscount);

  /// Subtotal que se habría cobrado sumando el precio regular de lista de los productos
  double get regularSubtotal => subtotal + itemDiscountsTotal;

  /// Total que se habría cobrado antes de aplicar el descuento global
  double get regularTotalBeforeGlobalDiscount => total + discount;

  /// Ahorro total acumulado para el cliente (descuentos en productos + descuento global)
  double get totalSavings => itemDiscountsTotal + discount;
}
