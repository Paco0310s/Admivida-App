import 'package:admivida/business/features/add_sale/add_sale_service.dart';
import 'package:admivida/business/features/add_sale/pos_catalog/models/pos_catalog_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pos_catalog_provider.g.dart';

@riverpod
class PosCatalogNotifier extends _$PosCatalogNotifier {
  @override
  PosCatalogState build(String businessId) {
    Future.microtask(() => fetchProducts());
    return const PosCatalogState(isLoading: true);
  }

  Future<void> fetchProducts({int? page, String? query}) async {
    final targetPage = page ?? state.currentPage;
    final targetQuery = query ?? state.searchQuery;

    state = state.copyWith(isLoading: true, errorMessage: null, currentPage: targetPage, searchQuery: targetQuery);

    final result = await AddSaleService.getTenantProducts(businessId, page: targetPage, limit: 12, nameOrSku: targetQuery);

    result.when(
      (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
      },
      (pageResponse) {
        state = state.copyWith(isLoading: false, pageModel: pageResponse);
      },
    );
  }

  void nextPage() {
    final meta = state.pageModel?.meta;
    if (meta != null && state.currentPage < meta.totalPages) {
      fetchProducts(page: state.currentPage + 1);
    }
  }

  void previousPage() {
    if (state.currentPage > 1) {
      fetchProducts(page: state.currentPage - 1);
    }
  }

  void setSearchQuery(String query) {
    fetchProducts(page: 1, query: query);
  }
}
