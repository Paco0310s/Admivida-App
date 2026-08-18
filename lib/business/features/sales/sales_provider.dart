import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/business/features/sales/models/sales_list_state.dart';
import 'package:admivida/business/features/sales/sales_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sales_provider.g.dart';

@riverpod
class SalesList extends _$SalesList {
  static const int _pageSize = 10;

  /// Initial fetch triggered for the specified businessId.
  @override
  Future<SalesListState> build(String businessId) async {
    return _fetchPage(page: 1, currentSales: []);
  }

  /// Internal method to request sales for a specific page.
  Future<SalesListState> _fetchPage({required int page, required List<SaleModel> currentSales}) async {
    final result = await SalesService.getTenantSales(page: page, limit: _pageSize, businessId: businessId);

    return result.when((failure) => throw failure, (pageModel) {
      final newSales = pageModel.sales;
      final hasMorePages = pageModel.currentPage < pageModel.totalPages;

      return SalesListState(sales: [...currentSales, ...newSales], page: page, hasMore: hasMorePages, isLoadingMore: false);
    });
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

  /// Fully refreshes the list back to page 1.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
