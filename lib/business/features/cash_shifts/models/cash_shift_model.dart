class CashMovementModel {
  final String id;
  final String shiftId;
  final String type; // 'IN' | 'OUT'
  final double amount;
  final String concept;
  final DateTime createdAt;
  final String? createdBy;

  const CashMovementModel({
    required this.id,
    required this.shiftId,
    required this.type,
    required this.amount,
    required this.concept,
    required this.createdAt,
    this.createdBy,
  });

  bool get isIn => type.toUpperCase() == 'IN';

  factory CashMovementModel.fromJson(Map<String, dynamic> json) {
    return CashMovementModel(
      id: (json['id'] ?? '').toString(),
      shiftId: (json['shiftId'] ?? '').toString(),
      type: (json['type'] ?? 'IN').toString(),
      amount: _toDouble(json['amount']),
      concept: (json['concept'] ?? '').toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString()).toLocal()
          : DateTime.now(),
      createdBy: json['createdBy']?.toString(),
    );
  }
}

class CashShiftSaleItemModel {
  final String id;
  final String clientName;
  final double total;
  final double discountAmount;
  final String status;
  final DateTime soldAt;
  final String paymentMethodName;
  final String paymentMethodCode;

  const CashShiftSaleItemModel({
    required this.id,
    required this.clientName,
    required this.total,
    required this.discountAmount,
    required this.status,
    required this.soldAt,
    required this.paymentMethodName,
    required this.paymentMethodCode,
  });

  bool get isCancelled =>
      status.toUpperCase() == 'CANCELLED' || status.toUpperCase() == 'REFUNDED';

  factory CashShiftSaleItemModel.fromJson(Map<String, dynamic> json) {
    return CashShiftSaleItemModel(
      id: (json['id'] ?? '').toString(),
      clientName: (json['clientName'] ?? 'Público General').toString(),
      total: _toDouble(json['total']),
      discountAmount: _toDouble(json['discountAmount']),
      status: (json['status'] ?? 'COMPLETED').toString(),
      soldAt: json['soldAt'] != null
          ? DateTime.parse(json['soldAt'].toString()).toLocal()
          : DateTime.now(),
      paymentMethodName: (json['paymentMethodName'] ?? 'Efectivo').toString(),
      paymentMethodCode: (json['paymentMethodCode'] ?? 'CASH').toString(),
    );
  }
}

class CashShiftModel {
  final String id;
  final String businessId;
  final String userId;
  final String? cashierName;
  final String? accountId;
  final String? accountName;
  final String status; // 'OPEN' | 'CLOSED'
  final bool isBlindMode;
  final double openingAmount;
  final double? cashSales;
  final double? cardSales;
  final double? transferSales;
  final double manualIn;
  final double manualOut;
  final double? expectedCash;
  final double? expectedCard;
  final double? expectedTransfer;
  final double? actualCash;
  final double? difference;
  final int salesCount;
  final int? clientPaymentsCount;
  final double? clientPaymentsTotal;
  final int? discountSalesCount;
  final double? discountTotal;
  final int? cancelledSalesCount;
  final double? cancelledSalesTotal;
  final double? previousShiftActualCash;
  final double? openingDiscrepancy;
  final DateTime openedAt;
  final DateTime? closedAt;
  final String? notes;
  final List<CashMovementModel> movements;
  final List<CashShiftSaleItemModel> sales;

  const CashShiftModel({
    required this.id,
    required this.businessId,
    required this.userId,
    this.cashierName,
    this.accountId,
    this.accountName,
    required this.status,
    this.isBlindMode = false,
    required this.openingAmount,
    this.cashSales,
    this.cardSales,
    this.transferSales,
    required this.manualIn,
    required this.manualOut,
    this.expectedCash,
    this.expectedCard,
    this.expectedTransfer,
    this.actualCash,
    this.difference,
    required this.salesCount,
    this.clientPaymentsCount,
    this.clientPaymentsTotal,
    this.discountSalesCount,
    this.discountTotal,
    this.cancelledSalesCount,
    this.cancelledSalesTotal,
    this.previousShiftActualCash,
    this.openingDiscrepancy,
    required this.openedAt,
    this.closedAt,
    this.notes,
    this.movements = const [],
    this.sales = const [],
  });

  bool get isOpen => status.toUpperCase() == 'OPEN';

  /// True if the shift has any audit warning for the business owner (shortage/surplus, discounts, cancellations, manual withdrawals, or opening discrepancy).
  bool get hasAuditAlerts {
    if (isBlindMode) return false;
    final hasDiff = difference != null && difference!.abs() >= 0.01;
    final hasDiscounts = (discountTotal ?? 0) > 0;
    final hasCancelled = (cancelledSalesCount ?? 0) > 0;
    final hasManualOut = manualOut > 0;
    final hasOpeningDiff =
        openingDiscrepancy != null && openingDiscrepancy!.abs() >= 0.01;
    return hasDiff || hasDiscounts || hasCancelled || hasManualOut || hasOpeningDiff;
  }

  factory CashShiftModel.fromJson(Map<String, dynamic> json) {
    final rawMovements = json['movements'] as List<dynamic>? ?? [];
    final rawSales = json['sales'] as List<dynamic>? ?? [];
    return CashShiftModel(
      id: (json['id'] ?? '').toString(),
      businessId: (json['businessId'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
      cashierName: json['cashierName']?.toString(),
      accountId: json['accountId']?.toString(),
      accountName: json['accountName']?.toString(),
      status: (json['status'] ?? 'OPEN').toString(),
      isBlindMode: json['isBlindMode'] == true,
      openingAmount: _toDouble(json['openingAmount']),
      cashSales: json['cashSales'] != null ? _toDouble(json['cashSales']) : null,
      cardSales: json['cardSales'] != null ? _toDouble(json['cardSales']) : null,
      transferSales:
          json['transferSales'] != null ? _toDouble(json['transferSales']) : null,
      manualIn: _toDouble(json['manualIn']),
      manualOut: _toDouble(json['manualOut']),
      expectedCash:
          json['expectedCash'] != null ? _toDouble(json['expectedCash']) : null,
      expectedCard:
          json['expectedCard'] != null ? _toDouble(json['expectedCard']) : null,
      expectedTransfer: json['expectedTransfer'] != null
          ? _toDouble(json['expectedTransfer'])
          : null,
      actualCash:
          json['actualCash'] != null ? _toDouble(json['actualCash']) : null,
      difference:
          json['difference'] != null ? _toDouble(json['difference']) : null,
      salesCount: int.tryParse((json['salesCount'] ?? '0').toString()) ?? 0,
      clientPaymentsCount: json['clientPaymentsCount'] != null
          ? int.tryParse(json['clientPaymentsCount'].toString())
          : null,
      clientPaymentsTotal: json['clientPaymentsTotal'] != null
          ? _toDouble(json['clientPaymentsTotal'])
          : null,
      discountSalesCount: json['discountSalesCount'] != null
          ? int.tryParse(json['discountSalesCount'].toString())
          : null,
      discountTotal:
          json['discountTotal'] != null ? _toDouble(json['discountTotal']) : null,
      cancelledSalesCount: json['cancelledSalesCount'] != null
          ? int.tryParse(json['cancelledSalesCount'].toString())
          : null,
      cancelledSalesTotal: json['cancelledSalesTotal'] != null
          ? _toDouble(json['cancelledSalesTotal'])
          : null,
      previousShiftActualCash: json['previousShiftActualCash'] != null
          ? _toDouble(json['previousShiftActualCash'])
          : null,
      openingDiscrepancy: json['openingDiscrepancy'] != null
          ? _toDouble(json['openingDiscrepancy'])
          : null,
      openedAt: json['openedAt'] != null
          ? DateTime.parse(json['openedAt'].toString()).toLocal()
          : DateTime.now(),
      closedAt: json['closedAt'] != null
          ? DateTime.parse(json['closedAt'].toString()).toLocal()
          : null,
      notes: json['notes']?.toString(),
      movements: rawMovements
          .map((e) => CashMovementModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      sales: rawSales
          .map((e) => CashShiftSaleItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

class ActiveCashShiftResponse {
  final CashShiftModel? shift;

  const ActiveCashShiftResponse({this.shift});

  factory ActiveCashShiftResponse.fromJson(Map<String, dynamic> json) {
    final shiftData = json['shift'];
    return ActiveCashShiftResponse(
      shift: shiftData is Map<String, dynamic>
          ? CashShiftModel.fromJson(shiftData)
          : null,
    );
  }
}

class PaginatedCashShiftsModel {
  final List<CashShiftModel> data;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  const PaginatedCashShiftsModel({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginatedCashShiftsModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['data'] as List<dynamic>? ?? [];
    return PaginatedCashShiftsModel(
      data: rawList
          .map((e) => CashShiftModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: int.tryParse((json['total'] ?? '0').toString()) ?? 0,
      page: int.tryParse((json['page'] ?? '1').toString()) ?? 1,
      limit: int.tryParse((json['limit'] ?? '20').toString()) ?? 20,
      totalPages: int.tryParse((json['totalPages'] ?? '1').toString()) ?? 1,
    );
  }
}
