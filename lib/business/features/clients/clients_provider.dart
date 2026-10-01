import 'package:admivida/business/features/clients/clients_service.dart';
import 'package:admivida/business/features/clients/models/client_debt_model.dart';
import 'package:admivida/business/features/clients/models/client_payment_response.dart';
import 'package:admivida/business/features/clients/models/create_client_dto_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:math';

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

    // Show the bottom loader without losing the current list.
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

class PaymentDistributionState {
  final List<PendingSaleModel> sales;
  final double totalAmount;
  final Map<String, double> distributions;

  PaymentDistributionState({required this.sales, required this.totalAmount, required this.distributions});

  PaymentDistributionState copyWith({List<PendingSaleModel>? sales, double? totalAmount, Map<String, double>? distributions}) {
    return PaymentDistributionState(
      sales: sales ?? this.sales,
      totalAmount: totalAmount ?? this.totalAmount,
      distributions: distributions ?? this.distributions,
    );
  }
}

@riverpod
class PaymentDistribution extends _$PaymentDistribution {
  @override
  PaymentDistributionState build({required String businessId, required String clientId}) {
    final salesAsync = ref.watch(pendingSalesProvider(businessId: businessId, clientId: clientId));

    final sales = salesAsync.value ?? [];

    return PaymentDistributionState(sales: sales, totalAmount: 0.0, distributions: {});
  }

  /// Automatic distribution (FIFO): called when the user enters a value in the "Total to Pay" field.
  void distributeTotal(double newTotal) {
    if (newTotal < 0) return;

    double remaining = newTotal;
    Map<String, double> newDist = {};

    for (var sale in state.sales) {
      if (remaining <= 0) {
        newDist[sale.id] = 0.0;
      } else {
        double amountToApply = min(remaining, sale.pendingBalance);
        newDist[sale.id] = amountToApply;
        remaining -= amountToApply;
      }
    }

    state = state.copyWith(totalAmount: newTotal, distributions: newDist);
  }

  /// Manual distribution: called when the user edits a specific sale in the list.
  void updateManualDistribution(String saleId, double newAmount) {
    final currentDist = state.distributions;
    final oldAmount = currentDist[saleId] ?? 0.0;

    // Skip calculations when the value has not actually changed.
    if (newAmount == oldAmount) return;

    // Prevent paying more than the amount owed on the sale.
    final sale = state.sales.firstWhere((s) => s.id == saleId);
    if (newAmount > sale.pendingBalance) {
      newAmount = sale.pendingBalance;
    }

    final diff = newAmount - oldAmount;
    Map<String, double> newDist = Map.from(currentDist);
    newDist[saleId] = newAmount;

    if (diff > 0) {
      // The user INCREASED the payment for this sale.
      // Take the difference from other sales (reverse FIFO: start with the newest).
      double needed = diff;
      for (int i = state.sales.length - 1; i >= 0; i--) {
        if (needed <= 0) break;
        final currentSale = state.sales[i];
        if (currentSale.id == saleId) continue;

        double allocated = newDist[currentSale.id] ?? 0.0;
        if (allocated > 0) {
          double amountToTake = min(allocated, needed);
          newDist[currentSale.id] = allocated - amountToTake;
          needed -= amountToTake;
        }
      }
    } else {
      // The user DECREASED the payment for this sale.
      // Redistribute the extra amount to other sales (FIFO: fill the oldest first).
      double extra = -diff;
      for (int i = 0; i < state.sales.length; i++) {
        if (extra <= 0) break;
        final currentSale = state.sales[i];
        if (currentSale.id == saleId) continue;

        double allocated = newDist[currentSale.id] ?? 0.0;
        double spaceLeft = currentSale.pendingBalance - allocated;

        if (spaceLeft > 0) {
          double amountToGive = min(spaceLeft, extra);
          newDist[currentSale.id] = allocated + amountToGive;
          extra -= amountToGive;
        }
      }
    }

    state = state.copyWith(distributions: newDist);
  }
}

@riverpod
class ProcessClientPayment extends _$ProcessClientPayment {
  @override
  AsyncValue<ClientPaymentResponse?> build() {
    return const AsyncValue.data(null);
  }

  Future<ClientPaymentResponse?> submit({required String businessId, required String clientId, required Map<String, dynamic> payload}) async {
    state = const AsyncValue.loading();

    final result = await ClientsService.processClientPayment(businessId: businessId, clientId: clientId, payload: payload);

    state = result.when((failure) => AsyncValue.error(failure, StackTrace.current), (data) => AsyncValue.data(data));

    return result.when((failure) => null, (data) => data);
  }
}

@riverpod
class CreateClient extends _$CreateClient {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> submit({required String businessId, required CreateClientDto dto}) async {
    state = const AsyncValue.loading();

    final result = await ClientsService.createClient(dto, businessId);

    state = result.when((failure) => AsyncValue.error(failure, StackTrace.current), (data) => const AsyncValue.data(null));
  }
}
