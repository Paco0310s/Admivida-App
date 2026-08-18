import 'package:admivida/business/features/transactions/models/paginated_transactions_model.dart';

class TransactionsListState {
  final List<Transaction> transactions;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final TransactionSummary summary;

  const TransactionsListState({required this.transactions, required this.page, required this.hasMore, required this.isLoadingMore, required this.summary});

  TransactionsListState copyWith({List<Transaction>? transactions, int? page, bool? hasMore, bool? isLoadingMore, TransactionSummary? summary}) {
    return TransactionsListState(
      transactions: transactions ?? this.transactions,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      summary: summary ?? this.summary,
    );
  }
}
