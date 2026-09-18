// =======================================================
// Enum for the transaction type
// =======================================================
enum TransactionType { income, expense }

TransactionType _transactionTypeFromString(String type) {
  switch (type.toLowerCase()) {
    case 'income':
      return TransactionType.income;
    case 'expense':
    default:
      return TransactionType.expense;
  }
}

// =======================================================
// Main entity: Transaction
// =======================================================
class Transaction {
  final String id;
  final String accountId;
  final String? accountName;
  final String paymentMethodId;
  final String? paymentMethodName;
  final String businessId;
  final String? saleId;
  final double amount;
  final TransactionType type;
  final String? description;
  final DateTime createdAt;

  Transaction({
    required this.id,
    required this.accountId,
    this.accountName,
    required this.paymentMethodId,
    this.paymentMethodName,
    required this.businessId,
    this.saleId,
    required this.amount,
    required this.type,
    this.description,
    required this.createdAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      accountId: json['accountId'] as String,
      accountName: json['accountName'] as String?,
      paymentMethodId: json['paymentMethodId'] as String,
      paymentMethodName: json['paymentMethodName'] as String?,
      businessId: json['businessId'] as String,
      saleId: json['saleId'] as String?,
      // Convert to double using .toDouble() in case the API sends an int (e.g., 500 instead of 500.0)
      amount: (json['amount'] as num).toDouble(),
      type: _transactionTypeFromString(json['type'] as String),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
    );
  }
}

// =======================================================
// Totals summary: Summary
// =======================================================
class TransactionSummary {
  final double totalIncome;
  final double totalExpense;
  final double balance;

  TransactionSummary({required this.totalIncome, required this.totalExpense, required this.balance});

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    return TransactionSummary(
      totalIncome: (json['totalIncome'] as num).toDouble(),
      totalExpense: (json['totalExpense'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
    );
  }
}

// =======================================================
// Pagination metadata: Meta
// =======================================================
class PaginationMeta {
  final int totalItems;
  final int itemCount;
  final int itemsPerPage;
  final int totalPages;
  final int currentPage;

  PaginationMeta({required this.totalItems, required this.itemCount, required this.itemsPerPage, required this.totalPages, required this.currentPage});

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      totalItems: json['totalItems'] as int,
      itemCount: json['itemCount'] as int,
      itemsPerPage: json['itemsPerPage'] as int,
      totalPages: json['totalPages'] as int,
      currentPage: json['currentPage'] as int,
    );
  }
}

// =======================================================
// Global response (What the endpoint returns)
// =======================================================
class PaginatedTransactionsResponse {
  final List<Transaction> data;
  final TransactionSummary summary;
  final PaginationMeta meta;

  PaginatedTransactionsResponse({required this.data, required this.summary, required this.meta});

  factory PaginatedTransactionsResponse.fromJson(Map<String, dynamic> json) {
    var dataList = json['data'] as List;
    List<Transaction> transactionsList = dataList.map((txJson) => Transaction.fromJson(txJson as Map<String, dynamic>)).toList();

    return PaginatedTransactionsResponse(
      data: transactionsList,
      summary: TransactionSummary.fromJson(json['summary'] as Map<String, dynamic>),
      meta: PaginationMeta.fromJson(json['meta'] as Map<String, dynamic>),
    );
  }
}
