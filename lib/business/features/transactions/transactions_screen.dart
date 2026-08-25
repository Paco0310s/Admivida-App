import 'package:admivida/business/features/transactions/models/paginated_transactions_model.dart';
import 'package:admivida/business/features/transactions/transactions_provider.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key, required this.businessId});

  final String businessId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Movimientos',
      appBar: AppBar(
        title: const AppText('Movimientos', color: AppColors.kNeutral100),
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
      ),
      mobile: TransactionsListView(businessId: businessId),
      tablet: TransactionsListView(businessId: businessId),
      desktop: TransactionsListView(businessId: businessId),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          NavigationService.navigateTo(context, Routes.addTransaction, arguments: businessId);
        },
        backgroundColor: AppColors.kPrimaryColor,
        child: const Icon(Icons.add, color: AppColors.kNeutral100),
      ),
    );
  }
}

class TransactionsListView extends ConsumerStatefulWidget {
  const TransactionsListView({super.key, required this.businessId});

  final String businessId;

  @override
  ConsumerState<TransactionsListView> createState() => _TransactionsListViewState();
}

class _TransactionsListViewState extends ConsumerState<TransactionsListView> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.extentAfter < 300) {
      ref.read(transactionsListProvider(widget.businessId, _selectedAccountId).notifier).fetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsListProvider(widget.businessId, _selectedAccountId));
    final accountsAsync = ref.watch(accountsProvider(businessId: widget.businessId));

    final accountOptions = <String, String>{};

    for (final tx in transactionsAsync.value?.transactions ?? const <Transaction>[]) {
      final accountName = tx.accountName?.trim().isNotEmpty == true ? tx.accountName! : tx.accountId;
      accountOptions.putIfAbsent(tx.accountId, () => accountName);
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(transactionsListProvider(widget.businessId, _selectedAccountId).notifier).refresh(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText('Balance de la cuenta', fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
                  const Gap(8),
                  transactionsAsync.when(
                    loading: () => const SizedBox(height: 36, child: Center(child: CircularProgressIndicator())),
                    error: (error, stackTrace) => AppText('No se pudo cargar el balance', color: Colors.red),
                    data: (state) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText('\$${state.summary.balance.toStringAsFixed(2)}', fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
                        const Gap(10),
                        Row(
                          children: [
                            AppText('Ingresos: ', color: AppColors.kNeutral600),
                            AppText('\$${state.summary.totalIncome.toStringAsFixed(2)}', color: AppColors.kSuccess),
                            const Spacer(),
                            AppText('Egresos: ', color: AppColors.kNeutral600),
                            AppText('\$${state.summary.totalExpense.toStringAsFixed(2)}', color: AppColors.kWarning),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(12),

            // Recuerda leer tu provider al inicio de tu método build():
            // final accountsAsync = ref.watch(accountsProvider(businessId: widget.businessId));
            AppCard(
              padding: const EdgeInsets.all(12),
              child: accountsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => Text('Error al cargar cuentas', style: const TextStyle(color: Colors.red)),
                data: (accounts) {
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedAccountId ?? '',
                    decoration: InputDecoration(
                      labelText: 'Cuenta',
                      filled: true,
                      fillColor: AppColors.kNeutral50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [
                      // 1. La opción por defecto (Todas) hasta arriba
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('Todas las cuentas', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      // 2. Mapeamos las cuentas reales obtenidas de tu backend
                      ...accounts.map((acc) => DropdownMenuItem<String>(value: acc.id, child: Text(acc.name))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        // Si elige 'Todas' (valor vacío), lo pasamos a null
                        _selectedAccountId = (value == null || value.isEmpty) ? null : value;

                        // Invalidamos el provider de transacciones para que vuelva a disparar el GET
                        // con o sin el accountId según corresponda
                        ref.invalidate(transactionsListProvider(widget.businessId, _selectedAccountId));
                      });
                    },
                  );
                },
              ),
            ),
            const Gap(12),
            Expanded(
              child: transactionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: AppText('Error loading transactions: $error', color: Colors.red)),
                data: (listState) {
                  final transactions = listState.transactions;

                  if (transactions.isEmpty) {
                    return Center(child: AppText(AppTexts.noData, color: AppColors.kNeutral600));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: transactions.length + (listState.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == transactions.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final transaction = transactions[index];
                      final isIncome = transaction.type == TransactionType.income;

                      return AppCard(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isIncome ? AppColors.kSuccess.withValues(alpha: 0.12) : AppColors.kWarning.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                color: isIncome ? AppColors.kSuccess : AppColors.kWarning,
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(transaction.accountName ?? transaction.accountId, fontWeight: FontWeight.bold, color: AppColors.kNeutral900),
                                  const Gap(4),
                                  AppText(
                                    transaction.description?.isNotEmpty == true
                                        ? transaction.description!
                                        : '${transaction.type.name} · ${transaction.paymentMethodName ?? transaction.paymentMethodId}',
                                    color: AppColors.kNeutral600,
                                    fontSize: 12,
                                  ),
                                  const Gap(8),
                                  Row(
                                    children: [
                                      AppText(
                                        '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
                                        color: isIncome ? AppColors.kSuccess : AppColors.kWarning,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      const Spacer(),
                                      AppText(
                                        '${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year}',
                                        color: AppColors.kNeutral500,
                                        fontSize: 12,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
