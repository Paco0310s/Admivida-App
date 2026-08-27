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

  void updateProductStockLocal(String productId, String variantId, double newStock) {
    final currentState = state.value;
    if (currentState == null) return;

    final updatedProducts = currentState.products.map((product) {
      // 1. Look for the product that matches the given productId
      if (product.id == productId) {
        // 2. Update the stock quantity for the specific variant
        final updatedVariants = product.variants.map((variant) {
          if (variant.id == variantId) {
            return variant.copyWith(stockQuantity: newStock);
          }
          return variant;
        }).toList();

        // 3. Return a new product instance with the updated variants
        return product.copyWith(variants: updatedVariants);
      }
      return product;
    }).toList();

    // 4. Update the state of the complete list (this refreshes the UI without losing scroll position)
    state = AsyncValue.data(currentState.copyWith(products: updatedProducts));
  }
}

@Riverpod(keepAlive: true)
class StockAdjustment extends _$StockAdjustment {
  @override
  FutureOr<void> build() {}

  Future<void> adjustStock({
    required String businessId,
    required String productId,
    required String variantId,
    required double currentStock,
    required double adjustment,
  }) async {
    final newStock = currentStock + adjustment;
    if (newStock < 0) return;

    state = const AsyncValue.loading();

    final result = await ProductsService.updateStock(businessId, variantId, newStock);

    result.when((failure) => state = AsyncValue.error(failure, StackTrace.current), (success) {
      state = const AsyncValue.data(null);

      ref.read(productsListProvider(businessId).notifier).updateProductStockLocal(productId, variantId, newStock);
    });
  }
}

@riverpod
Future<ProductModel> productDetail(Ref ref, {required String businessId, required String productId}) async {
  final result = await ProductsService.getProductById(businessId: businessId, productId: productId);

  return result.when((failure) => throw failure, (product) => product);
}
