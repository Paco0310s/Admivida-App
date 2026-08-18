import 'package:admivida/business/features/products/models/product_model.dart';

class ProductsListState {
  final List<ProductModel> products;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  const ProductsListState({this.products = const [], this.page = 1, this.hasMore = true, this.isLoadingMore = false});

  ProductsListState copyWith({List<ProductModel>? products, int? page, bool? hasMore, bool? isLoadingMore}) {
    return ProductsListState(
      products: products ?? this.products,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}
