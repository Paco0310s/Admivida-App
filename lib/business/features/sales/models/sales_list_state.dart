import 'package:admivida/business/features/sales/models/sale_model.dart';

class SalesListState {
  final List<SaleModel> sales;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final String searchQuery;
  final String? statusFilter;
  final DateTime? startDate;
  final DateTime? endDate;

  const SalesListState({
    required this.sales,
    required this.page,
    required this.hasMore,
    required this.isLoadingMore,
    this.searchQuery = '',
    this.statusFilter,
    this.startDate,
    this.endDate,
  });

  bool get hasActiveFilters => searchQuery.trim().isNotEmpty || statusFilter != null || startDate != null || endDate != null;

  SalesListState copyWith({
    List<SaleModel>? sales,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    String? searchQuery,
    String? statusFilter,
    bool clearStatusFilter = false,
    DateTime? startDate,
    DateTime? endDate,
    bool clearDateRange = false,
  }) {
    return SalesListState(
      sales: sales ?? this.sales,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      startDate: clearDateRange ? null : (startDate ?? this.startDate),
      endDate: clearDateRange ? null : (endDate ?? this.endDate),
    );
  }
}
