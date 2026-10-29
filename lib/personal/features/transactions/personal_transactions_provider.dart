import 'package:admivida/business/features/transactions/models/account_model.dart';
import 'package:admivida/business/features/transactions/models/paginated_transactions_model.dart';
import 'package:admivida/business/features/transactions/models/transactions_list_state.dart';
import 'package:admivida/business/features/transactions/transactions_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'personal_transactions_provider.g.dart';

@riverpod
class PersonalTransactionsList extends _$PersonalTransactionsList {
  static const int _pageSize = 15;

  String? _accountId;
  String _category = 'REAL';

  @override
  Future<TransactionsListState> build(String? accountId, {String category = 'REAL'}) async {
    _accountId = accountId;
    _category = category;

    return _fetchPage(page: 1, currentTransactions: []);
  }

  Future<TransactionsListState> _fetchPage({
    required int page,
    required List<Transaction> currentTransactions,
  }) async {
    final result = await TransactionsService.getPersonalTransactions(
      page: page,
      limit: _pageSize,
      accountId: _accountId,
      category: _category,
    );

    return result.when((failure) => throw failure, (pageResponse) {
      final newTransactions = pageResponse.data;
      final hasMorePages = pageResponse.meta.currentPage < pageResponse.meta.totalPages;

      return TransactionsListState(
        transactions: [...currentTransactions, ...newTransactions],
        page: page,
        hasMore: hasMorePages,
        isLoadingMore: false,
        summary: pageResponse.summary,
      );
    });
  }

  Future<void> fetchNextPage() async {
    final currentState = state.value;

    if (currentState == null || currentState.isLoadingMore || !currentState.hasMore) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    final nextPage = currentState.page + 1;

    try {
      final updatedState = await _fetchPage(page: nextPage, currentTransactions: currentState.transactions);
      state = AsyncValue.data(updatedState);
    } catch (_) {
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
Future<List<AccountModel>> personalAccounts(Ref ref) async {
  final result = await TransactionsService.getPersonalAccounts();

  return result.when((failure) => throw failure, (accounts) => accounts);
}
