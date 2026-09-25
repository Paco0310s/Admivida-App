import 'package:admivida/business/features/clients/clients_service.dart';
import 'package:admivida/business/features/clients/models/client_debt_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'clients_provider.g.dart';

class ClientsDebtListState {
  final List<ClientWithDebtModel> clients;
  final bool isLoadingMore;
  final int currentPage;
  final bool hasReachedMax;
  final String searchQuery;

  ClientsDebtListState({required this.clients, this.isLoadingMore = false, this.currentPage = 1, this.hasReachedMax = false, this.searchQuery = ''});

  ClientsDebtListState copyWith({List<ClientWithDebtModel>? clients, bool? isLoadingMore, int? currentPage, bool? hasReachedMax, String? searchQuery}) {
    return ClientsDebtListState(
      clients: clients ?? this.clients,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

@riverpod
class ClientsDebtList extends _$ClientsDebtList {
  final int _limit = 15;

  @override
  FutureOr<ClientsDebtListState> build(String businessId) async {
    return _fetchInitialPage();
  }

  Future<ClientsDebtListState> _fetchInitialPage({String searchQuery = ''}) async {
    final result = await ClientsService.getClientsWithDebt(businessId: businessId, page: 1, limit: _limit, search: searchQuery);

    return result.when(
      (failure) => throw failure,
      (pageData) => ClientsDebtListState(clients: pageData.data, currentPage: 1, hasReachedMax: pageData.data.length < _limit, searchQuery: searchQuery),
    );
  }

  Future<void> fetchNextPage() async {
    if (state.isLoading || state.hasError) return;

    final currentState = state.value;
    if (currentState == null || currentState.hasReachedMax || currentState.isLoadingMore) return;

    // Activamos el loader inferior sin perder la lista actual
    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    final nextPage = currentState.currentPage + 1;

    final result = await ClientsService.getClientsWithDebt(businessId: businessId, page: nextPage, limit: _limit, search: currentState.searchQuery);

    result.when(
      (failure) {
        state = AsyncValue.data(currentState.copyWith(isLoadingMore: false));
      },
      (pageData) {
        state = AsyncValue.data(
          currentState.copyWith(
            clients: [...currentState.clients, ...pageData.data],
            currentPage: nextPage,
            isLoadingMore: false,
            hasReachedMax: pageData.data.length < _limit,
          ),
        );
      },
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final currentState = state.value;
    final query = currentState?.searchQuery ?? '';
    state = await AsyncValue.guard(() => _fetchInitialPage(searchQuery: query));
  }

  void setSearchQuery(String query) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchInitialPage(searchQuery: query));
  }
}

@riverpod
class PendingSales extends _$PendingSales {
  @override
  Future<List<PendingSaleModel>> build({required String businessId, required String clientId}) async {
    final result = await ClientsService.getPendingSales(businessId: businessId, clientId: clientId);

    return result.when((failure) => throw failure, (sales) => sales);
  }
}
