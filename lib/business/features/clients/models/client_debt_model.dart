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

class PendingSaleModel {
  final String id;
  final String status;
  final double total;
  final double pendingBalance;
  final DateTime date;

  PendingSaleModel({required this.id, required this.status, required this.total, required this.pendingBalance, required this.date});

  factory PendingSaleModel.fromJson(Map<String, dynamic> json) {
    return PendingSaleModel(
      id: json['id'],
      status: json['status'],
      total: (json['total'] as num).toDouble(),
      pendingBalance: (json['pendingBalance'] as num).toDouble(),
      date: DateTime.parse(json['date']),
    );
  }
}
