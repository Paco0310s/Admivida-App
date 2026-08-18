import 'package:admivida/business/features/products/models/product_model.dart';

class PosCatalogState {
  final bool isLoading;
  final String? errorMessage;
  final ProductsPageModel? pageModel;
  final int currentPage;
  final String searchQuery;

  const PosCatalogState({this.isLoading = false, this.errorMessage, this.pageModel, this.currentPage = 1, this.searchQuery = ''});

  PosCatalogState copyWith({bool? isLoading, String? errorMessage, ProductsPageModel? pageModel, int? currentPage, String? searchQuery}) {
    return PosCatalogState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      pageModel: pageModel ?? this.pageModel,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
