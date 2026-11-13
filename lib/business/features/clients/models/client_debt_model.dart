class ClientDebtPageModel {
  final List<ClientWithDebtModel> data;
  final Map<String, dynamic> meta;

  ClientDebtPageModel({required this.data, required this.meta});

  factory ClientDebtPageModel.fromJson(Map<String, dynamic> json) {
    return ClientDebtPageModel(data: (json['data'] as List).map((item) => ClientWithDebtModel.fromJson(item)).toList(), meta: json['meta'] ?? {});
  }
}

class ClientWithDebtModel {
  final String id;
  final String fullName;
  final String? phone;
  final String? email;
  final ClientDebtBreakdownModel debt;

  ClientWithDebtModel({required this.id, required this.fullName, this.phone, this.email, required this.debt});

  factory ClientWithDebtModel.fromJson(Map<String, dynamic> json) {
    return ClientWithDebtModel(
      id: json['id'],
      fullName: json['fullName'],
      phone: json['phone'],
      email: json['email'],
      debt: ClientDebtBreakdownModel.fromJson(json['debt']),
    );
  }
}

class ClientDebtBreakdownModel {
  final double total;
  final double credit;
  final double layaway;

  ClientDebtBreakdownModel({required this.total, required this.credit, required this.layaway});

  factory ClientDebtBreakdownModel.fromJson(Map<String, dynamic> json) {
    return ClientDebtBreakdownModel(
      total: (json['total'] as num).toDouble(),
      credit: (json['credit'] as num).toDouble(),
      layaway: (json['layaway'] as num).toDouble(),
    );
  }
}

// --- Modelo para las Ventas Pendientes del Cliente ---

class PendingSaleItemModel {
  final String productName;
  final double quantity;
  final double unitPrice;

  const PendingSaleItemModel({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  factory PendingSaleItemModel.fromJson(Map<String, dynamic> json) {
    return PendingSaleItemModel(
      productName: json['productName'] as String? ?? 'Producto',
      quantity: (json['quantity'] as num? ?? 0).toDouble(),
      unitPrice: (json['unitPrice'] as num? ?? 0).toDouble(),
    );
  }
}

class PendingSalePaymentHistoryModel {
  final double amount;
  final DateTime date;
  final String paymentMethodName;
  final String? description;

  const PendingSalePaymentHistoryModel({
    required this.amount,
    required this.date,
    required this.paymentMethodName,
    this.description,
  });

  factory PendingSalePaymentHistoryModel.fromJson(Map<String, dynamic> json) {
    return PendingSalePaymentHistoryModel(
      amount: (json['amount'] as num? ?? 0).toDouble(),
      date: DateTime.tryParse(json['date']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      paymentMethodName: json['paymentMethodName'] as String? ?? 'Pago',
      description: json['description'] as String?,
    );
  }
}

class PendingSaleModel {
  final String id;
  final String status;
  final double total;
  final double paidAmount;
  final double pendingBalance;
  final DateTime date;
  final List<PendingSaleItemModel> items;
  final List<PendingSalePaymentHistoryModel> paymentHistory;

  PendingSaleModel({
    required this.id,
    required this.status,
    required this.total,
    this.paidAmount = 0.0,
    required this.pendingBalance,
    required this.date,
    this.items = const [],
    this.paymentHistory = const [],
  });

  factory PendingSaleModel.fromJson(Map<String, dynamic> json) {
    final total = (json['total'] as num? ?? 0).toDouble();
    final pendingBalance = (json['pendingBalance'] as num? ?? 0).toDouble();
    final paidAmount = json['paidAmount'] != null
        ? (json['paidAmount'] as num).toDouble()
        : (total - pendingBalance).clamp(0.0, double.infinity);

    return PendingSaleModel(
      id: json['id'] as String,
      status: json['status'] as String,
      total: total,
      paidAmount: paidAmount,
      pendingBalance: pendingBalance,
      date: DateTime.parse(json['date'].toString()).toLocal(),
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => PendingSaleItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
      paymentHistory: (json['paymentHistory'] as List<dynamic>?)
              ?.map((e) => PendingSalePaymentHistoryModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }
}
