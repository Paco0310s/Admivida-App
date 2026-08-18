import 'package:admivida/business/features/sales/models/sale_model.dart';

class SalesPageModel {
  final List<SaleModel> sales;
  final int totalItems;
  final int itemCount;
  final int itemsPerPage;
  final int totalPages;
  final int currentPage;

  SalesPageModel({
    required this.sales,
    required this.totalItems,
    required this.itemCount,
    required this.itemsPerPage,
    required this.totalPages,
    required this.currentPage,
  });

  factory SalesPageModel.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final data = json['data'] as List<dynamic>? ?? [];

    return SalesPageModel(
      sales: data.map((item) => SaleModel.fromJson(item as Map<String, dynamic>)).toList(),
      totalItems: (meta['totalItems'] as num? ?? 0).toInt(),
      itemCount: (meta['itemCount'] as num? ?? 0).toInt(),
      itemsPerPage: (meta['itemsPerPage'] as num? ?? 0).toInt(),
      totalPages: (meta['totalPages'] as num? ?? 0).toInt(),
      currentPage: (meta['currentPage'] as num? ?? 1).toInt(),
    );
  }
}
