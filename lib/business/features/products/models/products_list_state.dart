import 'package:admivida/business/features/products/models/product_model.dart';

class ProductsListState {
  final List<ProductModel> products;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final String? selectedCategoryId;
  final bool? isActiveFilter;
  final String? stockStatusFilter; // 'LOW' | 'OUT'

  const ProductsListState({
    this.products = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.selectedCategoryId,
    this.isActiveFilter,
    this.stockStatusFilter,
  });

  bool get hasActiveFilters =>
      selectedCategoryId != null || isActiveFilter != null || stockStatusFilter != null;

  ProductsListState copyWith({
    List<ProductModel>? products,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    String? selectedCategoryId,
    bool clearCategory = false,
    bool? isActiveFilter,
    bool clearIsActive = false,
    String? stockStatusFilter,
    bool clearStockStatus = false,
  }) {
    return ProductsListState(
      products: products ?? this.products,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      isActiveFilter: clearIsActive ? null : (isActiveFilter ?? this.isActiveFilter),
      stockStatusFilter: clearStockStatus ? null : (stockStatusFilter ?? this.stockStatusFilter),
    );
  }
}
