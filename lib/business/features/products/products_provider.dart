import 'package:admivida/business/features/products/models/product_model.dart';
import 'package:admivida/business/features/products/models/products_list_state.dart';
import 'package:admivida/business/features/products/products_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'products_provider.g.dart';

@riverpod
class ProductsList extends _$ProductsList {
  static const int _pageSize = 10;
  String _searchQuery = '';

  /// Initial fetch triggered for the specified businessId.
  @override
  Future<ProductsListState> build(String businessId) async {
    _searchQuery = '';
    return _fetchPage(page: 1, currentProducts: [], search: _searchQuery);
  }

  /// Internal method to request products for a specific page.
  Future<ProductsListState> _fetchPage({required int page, required List<ProductModel> currentProducts, String? search}) async {
    final normalizedSearch = search ?? _searchQuery;
    final result = await ProductsService.getTenantProducts(page: page, limit: _pageSize, businessId: businessId, search: normalizedSearch);

    return result.when((failure) => throw failure, (pageModel) {
      final newProducts = pageModel.data;
      final meta = pageModel.meta;
      final hasMorePages = meta != null && meta.currentPage < meta.totalPages;

      return ProductsListState(products: [...currentProducts, ...newProducts], page: page, hasMore: hasMorePages, isLoadingMore: false);
    });
  }

  /// Fetches the next page when the user scrolls near the bottom.
  Future<void> fetchNextPage() async {
    final currentState = state.value;

    // Guard: Prevent duplicate requests or fetching when no more items exist
    if (currentState == null || currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    // Set bottom loader state without overriding existing products
    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    final nextPage = currentState.page + 1;

    try {
      final updatedState = await _fetchPage(page: nextPage, currentProducts: currentState.products, search: _searchQuery);
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

  Future<void> setSearchQuery(String search) async {
    final normalizedSearch = search.trim();
    _searchQuery = normalizedSearch;

    state = const AsyncLoading();

    try {
      final initialState = await _fetchPage(page: 1, currentProducts: [], search: normalizedSearch);
      state = AsyncValue.data(initialState);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
