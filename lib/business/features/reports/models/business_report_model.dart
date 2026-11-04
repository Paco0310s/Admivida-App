class SalesSummaryReport {
  final double totalSales;
  final double totalCost;
  final double grossProfit;
  final double profitMarginPercentage;
  final int salesCount;
  final double averageTicket;
  final double totalItemsSold;

  const SalesSummaryReport({
    required this.totalSales,
    required this.totalCost,
    required this.grossProfit,
    required this.profitMarginPercentage,
    required this.salesCount,
    required this.averageTicket,
    required this.totalItemsSold,
  });

  factory SalesSummaryReport.fromJson(Map<String, dynamic> json) {
    return SalesSummaryReport(
      totalSales: (json['totalSales'] as num?)?.toDouble() ?? 0.0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
      grossProfit: (json['grossProfit'] as num?)?.toDouble() ?? 0.0,
      profitMarginPercentage: (json['profitMarginPercentage'] as num?)?.toDouble() ?? 0.0,
      salesCount: (json['salesCount'] as num?)?.toInt() ?? 0,
      averageTicket: (json['averageTicket'] as num?)?.toDouble() ?? 0.0,
      totalItemsSold: (json['totalItemsSold'] as num?)?.toDouble() ?? 0.0,
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

  const InventoryValuationReport({
    required this.totalCostValue,
    required this.totalSaleValue,
    required this.expectedProfit,
    required this.expectedMarginPercentage,
    required this.totalStockPieces,
    required this.totalActiveProducts,
    required this.lowStockVariantsCount,
  });

  factory InventoryValuationReport.fromJson(Map<String, dynamic> json) {
    return InventoryValuationReport(
      totalCostValue: (json['totalCostValue'] as num?)?.toDouble() ?? 0.0,
      totalSaleValue: (json['totalSaleValue'] as num?)?.toDouble() ?? 0.0,
      expectedProfit: (json['expectedProfit'] as num?)?.toDouble() ?? 0.0,
      expectedMarginPercentage: (json['expectedMarginPercentage'] as num?)?.toDouble() ?? 0.0,
      totalStockPieces: (json['totalStockPieces'] as num?)?.toDouble() ?? 0.0,
      totalActiveProducts: (json['totalActiveProducts'] as num?)?.toInt() ?? 0,
      lowStockVariantsCount: (json['lowStockVariantsCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class CashFlowReport {
  final double totalIncome;
  final double totalExpenses;
  final double netCashFlow;
  final double pendingReceivablesDebt;

  const CashFlowReport({
    required this.totalIncome,
    required this.totalExpenses,
    required this.netCashFlow,
    required this.pendingReceivablesDebt,
  });

  factory CashFlowReport.fromJson(Map<String, dynamic> json) {
    return CashFlowReport(
      totalIncome: (json['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpenses: (json['totalExpenses'] as num?)?.toDouble() ?? 0.0,
      netCashFlow: (json['netCashFlow'] as num?)?.toDouble() ?? 0.0,
      pendingReceivablesDebt: (json['pendingReceivablesDebt'] as num?)?.toDouble() ?? 0.0,
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
      sales: (json['sales'] as num?)?.toDouble() ?? 0.0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      profit: (json['profit'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
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
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class TopProductReportItem {
  final String productId;
  final String variantId;
  final String name;
  final double unitsSold;
  final double totalRevenue;
  final double totalProfit;

  const TopProductReportItem({
    required this.productId,
    required this.variantId,
    required this.name,
    required this.unitsSold,
    required this.totalRevenue,
    required this.totalProfit,
  });

  factory TopProductReportItem.fromJson(Map<String, dynamic> json) {
    return TopProductReportItem(
      productId: json['productId']?.toString() ?? '',
      variantId: json['variantId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      unitsSold: (json['unitsSold'] as num?)?.toDouble() ?? 0.0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (json['totalProfit'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class TopSellerReportItem {
  final String sellerId;
  final String name;
  final int salesCount;
  final double totalRevenue;

  const TopSellerReportItem({
    required this.sellerId,
    required this.name,
    required this.salesCount,
    required this.totalRevenue,
  });

  factory TopSellerReportItem.fromJson(Map<String, dynamic> json) {
    return TopSellerReportItem(
      sellerId: json['sellerId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Vendedor',
      salesCount: (json['salesCount'] as num?)?.toInt() ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BusinessReportModel {
  final String startDate;
  final String endDate;
  final SalesSummaryReport salesSummary;
  final InventoryValuationReport inventoryValuation;
  final CashFlowReport cashFlow;
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

