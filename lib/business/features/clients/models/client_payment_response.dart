import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/common/models/object_to_print.dart';

class AppliedTicketPaymentModel {
  final String saleId;
  final double previousBalance;
  final double amountPaid;
  final double remainingBalance;
  final String status;

  const AppliedTicketPaymentModel({
    required this.saleId,
    required this.previousBalance,
    required this.amountPaid,
    required this.remainingBalance,
    required this.status,
  });

  factory AppliedTicketPaymentModel.fromJson(Map<String, dynamic> json) {
    return AppliedTicketPaymentModel(
      saleId: json['saleId'] as String? ?? '',
      previousBalance: (json['previousBalance'] as num? ?? 0).toDouble(),
      amountPaid: (json['amountPaid'] as num? ?? 0).toDouble(),
      remainingBalance: (json['remainingBalance'] as num? ?? 0).toDouble(),
      status: json['status'] as String? ?? 'CREDIT',
    );
  }
}

class ClientPaymentResponse {
  final String message;
  final String receiptId;
  final DateTime paidAt;
  final String? accountName;
  final double previousTotalDebt;
  final double totalPaid;
  final double remainingTotalDebt;
  final int ticketsImpacted;
  final List<SalePaymentModel> payments;
  final List<AppliedTicketPaymentModel> appliedTickets;

  ClientPaymentResponse({
    required this.message,
    this.receiptId = '',
    DateTime? paidAt,
    this.accountName,
    this.previousTotalDebt = 0.0,
    required this.totalPaid,
    this.remainingTotalDebt = 0.0,
    required this.ticketsImpacted,
    this.payments = const [],
    this.appliedTickets = const [],
  }) : paidAt = paidAt ?? DateTime.now();

  factory ClientPaymentResponse.fromJson(Map<String, dynamic> json) {
    return ClientPaymentResponse(
      message: json['message'] as String? ?? '',
      receiptId: json['receiptId'] as String? ?? 'ABONO',
      paidAt: DateTime.tryParse(json['paidAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      accountName: json['accountName'] as String?,
      previousTotalDebt: (json['previousTotalDebt'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['totalPaid'] as num?)?.toDouble() ?? 0.0,
      remainingTotalDebt: (json['remainingTotalDebt'] as num?)?.toDouble() ?? 0.0,
      ticketsImpacted: json['ticketsImpacted'] as int? ?? 0,
      payments: (json['payments'] as List<dynamic>?)
              ?.map((e) => SalePaymentModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      appliedTickets: (json['appliedTickets'] as List<dynamic>?)
              ?.map((e) => AppliedTicketPaymentModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }

  ObjectToPrint toObjectToPrint({
    required String businessName,
    required String clientName,
    required String cashierName,
    bool openDrawer = false,
  }) {
    final rows = appliedTickets.map((t) {
      final shortId = t.saleId.length >= 8 ? t.saleId.substring(0, 8).toUpperCase() : t.saleId;
      final statusTag = t.remainingBalance <= 0.01 ? 'Liquidado' : 'Resta \$${t.remainingBalance.toStringAsFixed(2)}';
      return PrintableRow(
        quantity: 1,
        description: 'Abono Ticket #$shortId ($statusTag)',
        price: t.amountPaid,
        total: t.amountPaid,
      );
    }).toList();

    return ObjectToPrint(
      businessName: businessName,
      ticketId: receiptId.isNotEmpty ? receiptId : 'ABONO',
      date: paidAt,
      cashierName: cashierName,
      customerName: clientName,
      rows: rows.isNotEmpty
          ? rows
          : [
              PrintableRow(
                quantity: 1,
                description: 'Abono a cuenta ($ticketsImpacted ticket(s))',
                price: totalPaid,
                total: totalPaid,
              ),
            ],
      subtotal: totalPaid,
      discount: 0.0,
      total: totalPaid,
      amountPaid: totalPaid,
      changeGiven: 0.0,
      payments: payments
          .map((p) => PrintablePayment(methodName: p.paymentMethodName, amount: p.amount))
          .toList(),
      isPaymentReceipt: true,
      previousBalance: previousTotalDebt,
      remainingBalance: remainingTotalDebt,
      footerMessage: remainingTotalDebt <= 0.01 ? '¡Cuenta liquidada! Gracias por su abono.' : '¡Gracias por su abono!',
      openDrawer: openDrawer,
    );
  }
}
