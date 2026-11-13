import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/business/features/sales/models/sales_list_state.dart';
import 'package:admivida/business/features/sales/sales_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sales_provider.g.dart';

@riverpod
class SalesList extends _$SalesList {
  static const int _pageSize = 15;
  String _searchQuery = '';
  String? _statusFilter;
  DateTime? _startDate;
  DateTime? _endDate;

  /// Initial fetch triggered for the specified businessId.
  @override
  Future<SalesListState> build(String businessId) async {
    return _fetchPage(page: 1, currentSales: []);
  }

  /// Internal method to request sales for a specific page with active filters.
  Future<SalesListState> _fetchPage({required int page, required List<SaleModel> currentSales}) async {
    final result = await SalesService.getTenantSales(
      page: page,
      limit: _pageSize,
      businessId: businessId,
      search: _searchQuery,
      status: _statusFilter,
      startDate: _startDate,
      endDate: _endDate,
    );

    return result.when((failure) => throw failure, (pageModel) {
      final newSales = pageModel.sales;
      final hasMorePages = pageModel.currentPage < pageModel.totalPages;

      return SalesListState(
        sales: [...currentSales, ...newSales],
        page: page,
        hasMore: hasMorePages,
        isLoadingMore: false,
        searchQuery: _searchQuery,
        statusFilter: _statusFilter,
        startDate: _startDate,
        endDate: _endDate,
      );
    });
  }

  Future<void> _reloadFromFirstPage() async {
    state = const AsyncValue.loading();
    try {
      final firstPage = await _fetchPage(page: 1, currentSales: []);
      state = AsyncValue.data(firstPage);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> setSearchQuery(String query) async {
    if (_searchQuery == query.trim()) return;
    _searchQuery = query.trim();
    await _reloadFromFirstPage();
  }

  Future<void> setStatusFilter(String? status) async {
    if (_statusFilter == status) return;
    _statusFilter = status;
    await _reloadFromFirstPage();
  }

  Future<void> setDateRange(DateTime? start, DateTime? end) async {
    _startDate = start != null ? DateTime(start.year, start.month, start.day, 0, 0, 0) : null;
    _endDate = end != null ? DateTime(end.year, end.month, end.day, 23, 59, 59, 999) : null;
    await _reloadFromFirstPage();
  }

  Future<void> clearFilters() async {
    _searchQuery = '';
    _statusFilter = null;
    _startDate = null;
    _endDate = null;
    await _reloadFromFirstPage();
  }

  /// Fetches the next page when the user scrolls near the bottom.
  Future<void> fetchNextPage() async {
    final currentState = state.value;

    // Guard: Prevent duplicate requests or fetching when no more items exist
    if (currentState == null || currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    // Set bottom loader state without overriding existing sales
    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    final nextPage = currentState.page + 1;

    try {
      final updatedState = await _fetchPage(page: nextPage, currentSales: currentState.sales);
      state = AsyncValue.data(updatedState);
    } catch (error) {
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: false));
    }
  }

  /// Fully refreshes the list back to page 1 keeping current filters.
  Future<void> refresh() async {
    await _reloadFromFirstPage();
  }
}
