class PrintableRow {
  final double quantity;
  final String description;
  final double price;
  final double total;

  const PrintableRow({required this.quantity, required this.description, required this.price, required this.total});
}

class ObjectToPrint {
  // Cabecera
  final String businessName; // Nombre de la sucursal o empresa
  final String ticketId; // Folio
  final DateTime date; // Fecha y hora
  final String cashierName; // Vendedor
  final String customerName; // Cliente

  // Cuerpo
  final List<PrintableRow> rows;

  // Totales
  final double subtotal;
  final double discount;
  final double total;
  final double amountPaid;
  final double changeGiven;

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
    this.openDrawer = true,
  });
}
