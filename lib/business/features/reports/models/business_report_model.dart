double _numToDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

int _numToInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

class SalesSummaryReport {
  final double totalSales;
  final double completedSalesTotal;
  final int completedSalesCount;
  final double creditLayawaySalesTotal;
  final int creditLayawaySalesCount;
  final double totalDiscounts;
  final double totalCost;
  final double grossProfit;
  final double totalCommissions;
  final double netProfitAfterCommissions;
  final double profitMarginPercentage;
  final int salesCount;
  final double averageTicket;
  final double totalItemsSold;
  final int itemsWithoutCostCount;

  const SalesSummaryReport({
    required this.totalSales,
    this.completedSalesTotal = 0.0,
    this.completedSalesCount = 0,
    this.creditLayawaySalesTotal = 0.0,
    this.creditLayawaySalesCount = 0,
    this.totalDiscounts = 0.0,
    required this.totalCost,
    required this.grossProfit,
    this.totalCommissions = 0.0,
    this.netProfitAfterCommissions = 0.0,
    required this.profitMarginPercentage,
    required this.salesCount,
    required this.averageTicket,
    required this.totalItemsSold,
    this.itemsWithoutCostCount = 0,
  });

  factory SalesSummaryReport.fromJson(Map<String, dynamic> json) {
    final grossProfit = _numToDouble(json['grossProfit']);
    final totalCommissions = _numToDouble(json['totalCommissions']);
    return SalesSummaryReport(
      totalSales: _numToDouble(json['totalSales']),
      completedSalesTotal: _numToDouble(json['completedSalesTotal']),
      completedSalesCount: _numToInt(json['completedSalesCount']),
      creditLayawaySalesTotal: _numToDouble(json['creditLayawaySalesTotal']),
      creditLayawaySalesCount: _numToInt(json['creditLayawaySalesCount']),
      totalDiscounts: _numToDouble(json['totalDiscounts']),
      totalCost: _numToDouble(json['totalCost']),
      grossProfit: grossProfit,
      totalCommissions: totalCommissions,
      netProfitAfterCommissions: json['netProfitAfterCommissions'] != null
          ? _numToDouble(json['netProfitAfterCommissions'])
          : (grossProfit - totalCommissions),
      profitMarginPercentage: _numToDouble(json['profitMarginPercentage']),
      salesCount: _numToInt(json['salesCount']),
      averageTicket: _numToDouble(json['averageTicket']),
      totalItemsSold: _numToDouble(json['totalItemsSold']),
      itemsWithoutCostCount: _numToInt(json['itemsWithoutCostCount']),
    );
  }
}

class InventoryValuationReport {
  final double totalCostValue;
  final double totalSaleValue;
  final double expectedProfit;
  final double expectedMarginPercentage;
  final double totalStockPieces;
  final int totalActiveProducts;
  final int lowStockVariantsCount;
  final int outOfStockVariantsCount;
  final int variantsWithoutCostCount;

  const InventoryValuationReport({
    required this.totalCostValue,
    required this.totalSaleValue,
    required this.expectedProfit,
    required this.expectedMarginPercentage,
    required this.totalStockPieces,
    required this.totalActiveProducts,
    required this.lowStockVariantsCount,
    this.outOfStockVariantsCount = 0,
    this.variantsWithoutCostCount = 0,
  });

  factory InventoryValuationReport.fromJson(Map<String, dynamic> json) {
    return InventoryValuationReport(
      totalCostValue: _numToDouble(json['totalCostValue']),
      totalSaleValue: _numToDouble(json['totalSaleValue']),
      expectedProfit: _numToDouble(json['expectedProfit']),
      expectedMarginPercentage: _numToDouble(json['expectedMarginPercentage']),
      totalStockPieces: _numToDouble(json['totalStockPieces']),
      totalActiveProducts: _numToInt(json['totalActiveProducts']),
      lowStockVariantsCount: _numToInt(json['lowStockVariantsCount']),
      outOfStockVariantsCount: _numToInt(json['outOfStockVariantsCount']),
      variantsWithoutCostCount: _numToInt(json['variantsWithoutCostCount']),
    );
  }
}

class CashFlowReport {
  final double totalIncome;
  final double salesIncome;
  final double manualIncome;
  final double totalExpenses;
  final double netCashFlow;
  final double pendingReceivablesDebt;
  final double totalAvailableInAccounts;

  const CashFlowReport({
    required this.totalIncome,
    this.salesIncome = 0.0,
    this.manualIncome = 0.0,
    required this.totalExpenses,
    required this.netCashFlow,
    required this.pendingReceivablesDebt,
    this.totalAvailableInAccounts = 0.0,
  });

  factory CashFlowReport.fromJson(Map<String, dynamic> json) {
    final totalIncome = _numToDouble(json['totalIncome']);
    return CashFlowReport(
      totalIncome: totalIncome,
      salesIncome: json['salesIncome'] != null ? _numToDouble(json['salesIncome']) : totalIncome,
      manualIncome: _numToDouble(json['manualIncome']),
      totalExpenses: _numToDouble(json['totalExpenses']),
      netCashFlow: _numToDouble(json['netCashFlow']),
      pendingReceivablesDebt: _numToDouble(json['pendingReceivablesDebt']),
      totalAvailableInAccounts: _numToDouble(json['totalAvailableInAccounts']),
    );
  }
}

class AccountBalanceReportItem {
  final String accountId;
  final String name;
  final String typeCode;
  final String typeName;
  final bool isDefault;
  final double currentBalance;
  final double periodIncome;
  final double periodExpense;

  const AccountBalanceReportItem({
    required this.accountId,
    required this.name,
    required this.typeCode,
    required this.typeName,
    required this.isDefault,
    required this.currentBalance,
    required this.periodIncome,
    required this.periodExpense,
  });

  factory AccountBalanceReportItem.fromJson(Map<String, dynamic> json) {
    return AccountBalanceReportItem(
      accountId: json['accountId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Caja',
      typeCode: json['typeCode']?.toString() ?? 'CASH',
      typeName: json['typeName']?.toString() ?? 'Efectivo',
      isDefault: json['isDefault'] == true,
      currentBalance: _numToDouble(json['currentBalance']),
      periodIncome: _numToDouble(json['periodIncome']),
      periodExpense: _numToDouble(json['periodExpense']),
    );
  }
}

class TimelineReportItem {
  final String date;
  final double sales;
  final double cost;
  final double profit;
  final int count;

  const TimelineReportItem({
    required this.date,
    required this.sales,
    required this.cost,
    required this.profit,
    required this.count,
  });

  factory TimelineReportItem.fromJson(Map<String, dynamic> json) {
    return TimelineReportItem(
      date: json['date']?.toString() ?? '',
      sales: _numToDouble(json['sales']),
      cost: _numToDouble(json['cost']),
      profit: _numToDouble(json['profit']),
      count: _numToInt(json['count']),
    );
  }
}

class PaymentMethodReportItem {
  final String name;
  final String code;
  final double total;
  final double percentage;
  final int count;

  const PaymentMethodReportItem({
    required this.name,
    required this.code,
    required this.total,
    required this.percentage,
    required this.count,
  });

  factory PaymentMethodReportItem.fromJson(Map<String, dynamic> json) {
    return PaymentMethodReportItem(
      name: json['name']?.toString() ?? 'Efectivo',
      code: json['code']?.toString() ?? 'CASH',
      total: _numToDouble(json['total']),
      percentage: _numToDouble(json['percentage']),
      count: _numToInt(json['count']),
    );
  }
}

class TopProductReportItem {
  final String productId;
  final String variantId;
  final String name;
  final double unitsSold;
  final double totalRevenue;
  final double totalCost;
  final double totalProfit;

  const TopProductReportItem({
    required this.productId,
    required this.variantId,
    required this.name,
    required this.unitsSold,
    required this.totalRevenue,
    this.totalCost = 0.0,
    required this.totalProfit,
  });

  factory TopProductReportItem.fromJson(Map<String, dynamic> json) {
    return TopProductReportItem(
      productId: json['productId']?.toString() ?? '',
      variantId: json['variantId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      unitsSold: _numToDouble(json['unitsSold']),
      totalRevenue: _numToDouble(json['totalRevenue']),
      totalCost: _numToDouble(json['totalCost']),
      totalProfit: _numToDouble(json['totalProfit']),
    );
  }
}

class TopSellerReportItem {
  final String sellerId;
  final String name;
  final int salesCount;
  final double totalRevenue;
  final double totalProfit;
  final double totalCommission;

  const TopSellerReportItem({
    required this.sellerId,
    required this.name,
    required this.salesCount,
    required this.totalRevenue,
    this.totalProfit = 0.0,
    this.totalCommission = 0.0,
  });

  factory TopSellerReportItem.fromJson(Map<String, dynamic> json) {
    return TopSellerReportItem(
      sellerId: json['sellerId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Vendedor',
      salesCount: _numToInt(json['salesCount']),
      totalRevenue: _numToDouble(json['totalRevenue']),
      totalProfit: _numToDouble(json['totalProfit']),
      totalCommission: _numToDouble(json['totalCommission']),
    );
  }
}

class BusinessReportModel {
  final String startDate;
  final String endDate;
  final SalesSummaryReport salesSummary;
  final InventoryValuationReport inventoryValuation;
  final CashFlowReport cashFlow;
  final List<AccountBalanceReportItem> accountsBreakdown;
  final List<TimelineReportItem> timeline;
  final List<PaymentMethodReportItem> paymentMethods;
  final List<TopProductReportItem> topProducts;
  final List<TopSellerReportItem> topSellers;

  const BusinessReportModel({
    required this.startDate,
    required this.endDate,
    required this.salesSummary,
    required this.inventoryValuation,
    required this.cashFlow,
    this.accountsBreakdown = const [],
    required this.timeline,
    required this.paymentMethods,
    required this.topProducts,
    required this.topSellers,
  });

  factory BusinessReportModel.fromJson(Map<String, dynamic> json) {
    final period = json['period'] as Map<String, dynamic>? ?? {};
    return BusinessReportModel(
      startDate: period['startDate']?.toString() ?? '',
      endDate: period['endDate']?.toString() ?? '',
      salesSummary: SalesSummaryReport.fromJson(json['salesSummary'] as Map<String, dynamic>? ?? {}),
      inventoryValuation: InventoryValuationReport.fromJson(json['inventoryValuation'] as Map<String, dynamic>? ?? {}),
      cashFlow: CashFlowReport.fromJson(json['cashFlow'] as Map<String, dynamic>? ?? {}),
      accountsBreakdown: ((json['accountsBreakdown'] as List<dynamic>?) ?? [])
          .map((item) => AccountBalanceReportItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      timeline: ((json['timeline'] as List<dynamic>?) ?? [])
          .map((item) => TimelineReportItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      paymentMethods: ((json['paymentMethods'] as List<dynamic>?) ?? [])
          .map((item) => PaymentMethodReportItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      topProducts: ((json['topProducts'] as List<dynamic>?) ?? [])
          .map((item) => TopProductReportItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      topSellers: ((json['topSellers'] as List<dynamic>?) ?? [])
          .map((item) => TopSellerReportItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

