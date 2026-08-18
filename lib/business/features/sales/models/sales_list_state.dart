import 'package:admivida/business/features/sales/models/sale_model.dart';

class SalesListState {
  final List<SaleModel> sales;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  const SalesListState({required this.sales, required this.page, required this.hasMore, required this.isLoadingMore});

  SalesListState copyWith({List<SaleModel>? sales, int? page, bool? hasMore, bool? isLoadingMore}) {
    return SalesListState(
      sales: sales ?? this.sales,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
