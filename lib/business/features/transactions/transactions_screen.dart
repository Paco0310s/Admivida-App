import 'package:admivida/business/features/transactions/models/account_model.dart';
import 'package:admivida/business/features/transactions/models/paginated_transactions_model.dart';
import 'package:admivida/business/features/transactions/models/transactions_list_state.dart';
import 'package:admivida/business/features/transactions/transactions_provider.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/services/printer_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/create_account_dialog.dart';
import 'package:admivida/common/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key, required this.businessId});

  final String businessId;

  Future<void> _handlePrinterToggle(BuildContext context, WidgetRef ref, bool hasPrinter) async {
    if (hasPrinter) {
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const AppText('Eliminar impresora seleccionada', fontWeight: FontWeight.bold),
          content: const AppText('¿Estás seguro de que deseas eliminar la impresora seleccionada?'),
          actions: [
            TextButton(onPressed: () => NavigationService.pop(dialogContext), child: const AppText('Cancelar', color: AppColors.kNeutral600)),
            ElevatedButton(
              onPressed: () async {
                NavigationService.pop(dialogContext);
                await ref.read(printerServiceProvider).clearSavedPrinter();
                ref.invalidate(hasSavedPrinterProvider);
                if (context.mounted) {
                  SnackbarUtil.showSuccess(context, 'Impresora desvinculada correctamente.');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
              child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      await ref.read(printerServiceProvider).showPrinterSelectionModal(context);
      ref.invalidate(hasSavedPrinterProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isMobile = Responsive.isMobile(context);
    final hasPrinterAsync = ref.watch(hasSavedPrinterProvider);

    return AppScaffold(
      title: 'Movimientos',
      appBar: AppBar(
        title: const AppText('Movimientos', color: AppColors.kNeutral100),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.kPrimaryColor,
        actions: [
          IconButton(
            tooltip: 'Abrir Cajón',
            icon: const Icon(Icons.point_of_sale_rounded),
            onPressed: () async {
              await ref.read(printerServiceProvider).openCashDrawerWithFeedback(context);
            },
          ),
          hasPrinterAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (hasPrinter) => IconButton(
              tooltip: hasPrinter ? 'Desvincular Impresora' : 'Seleccionar Impresora',
              icon: Icon(hasPrinter ? Icons.print_disabled_rounded : Icons.print_rounded),
              onPressed: () => _handlePrinterToggle(context, ref, hasPrinter),
            ),
          ),
        ],
      ),
      mobile: TransactionsListView(businessId: businessId),
      tablet: TransactionsListView(businessId: businessId),
      desktop: TransactionsListView(businessId: businessId),
      floatingActionButton: isMobile
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'transferFunds',
                  tooltip: 'Transferir entre cuentas',
                  onPressed: () {
                    NavigationService.navigateTo(context, Routes.transferFunds, arguments: businessId);
                  },
                  backgroundColor: AppColors.kSecondaryColor,
                  child: const Icon(Icons.swap_horiz, color: AppColors.kNeutral100),
                ),
                const SizedBox(width: 14),
                FloatingActionButton(
                  heroTag: 'addTransaction',
                  tooltip: 'Agregar movimiento',
                  onPressed: () {
                    NavigationService.navigateTo(context, Routes.addTransaction, arguments: businessId);
                  },
                  backgroundColor: AppColors.kPrimaryColor,
                  child: const Icon(Icons.add, color: AppColors.kNeutral100),
                ),
              ],
            )
          : null,
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
  bool _isSettingDefault = false;

  Future<void> _handleSetDefaultAccount(AccountModel account) async {
    if (_isSettingDefault || account.isDefault || account.isCreditOrLoan) return;

    setState(() => _isSettingDefault = true);
    try {
      await ref
          .read(accountsBusinessProvider(businessId: widget.businessId).notifier)
          .setDefaultAccount(account.id);
      if (!mounted) return;
      SnackbarUtil.showSuccess(
        context,
        '"${account.name}" ahora es la cuenta predeterminada para cobros.',
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e is HttpFailure ? e.message : 'Error al cambiar cuenta predeterminada';
      SnackbarUtil.showError(context, msg);
    } finally {
      if (mounted) setState(() => _isSettingDefault = false);
    }
  }

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
    final accountsAsync = ref.watch(accountsBusinessProvider(businessId: widget.businessId));
    final bool isMobile = Responsive.isMobile(context);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(accountsBusinessProvider(businessId: widget.businessId));
        await ref.read(transactionsListProvider(widget.businessId, _selectedAccountId).notifier).refresh();
      },
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary + Filter Header
            if (!isMobile) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: _buildBalanceCard(transactionsAsync)),
                    const Gap(14),
                    Expanded(child: _buildAccountFilterCard(accountsAsync, isMobile: false)),
                  ],
                ),
              ),
            ] else ...[
              _buildBalanceCard(transactionsAsync),
              const Gap(10),
              _buildAccountFilterCard(accountsAsync, isMobile: true),
            ],
            const Gap(12),
            _buildAccountsBalancesStrip(accountsAsync),
            const Gap(12),
            Expanded(
              child: transactionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: AppText('Error loading transactions: $error', color: Colors.red)),
                data: (listState) {
                  final transactions = listState.transactions;

                  if (transactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(color: AppColors.kPrimary50, shape: BoxShape.circle),
                            child: const Icon(Icons.account_balance_wallet_rounded, size: 36, color: AppColors.kPrimaryColor),
                          ),
                          const Gap(12),
                          const AppText(AppTexts.noData, color: AppColors.kNeutral600, fontWeight: FontWeight.w600),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
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
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: isIncome ? AppColors.kSuccess.withValues(alpha: 0.12) : AppColors.kWarning.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                isIncome ? Icons.south_west_rounded : Icons.north_east_rounded,
                                color: isIncome ? AppColors.kSuccess : AppColors.kWarning,
                                size: 22,
                              ),
                            ),
                            const Gap(14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    transaction.accountName ?? transaction.accountId,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.kNeutral900,
                                    fontSize: 14.5,
                                  ),
                                  const Gap(3),
                                  AppText(
                                    transaction.description?.isNotEmpty == true
                                        ? transaction.description!
                                        : '${transaction.type.name} · ${transaction.paymentMethodName ?? transaction.paymentMethodId}',
                                    color: AppColors.kNeutral600,
                                    fontSize: 12.5,
                                  ),
                                ],
                              ),
                            ),
                            const Gap(12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AppText(
                                  '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
                                  color: isIncome ? AppColors.kSuccess : AppColors.kWarning,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.5,
                                ),
                                const Gap(4),
                                AppText(
                                  '${transaction.createdAt.day.toString().padLeft(2, '0')}/${transaction.createdAt.month.toString().padLeft(2, '0')}/${transaction.createdAt.year} • ${transaction.createdAt.hour.toString().padLeft(2, '0')}:${transaction.createdAt.minute.toString().padLeft(2, '0')}',
                                  color: AppColors.kNeutral500,
                                  fontSize: 11.5,
                                ),
                              ],
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

  Widget _buildBalanceCard(AsyncValue<TransactionsListState> transactionsAsync) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppText('Balance de la cuenta', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.kNeutral600),
          const Gap(6),
          transactionsAsync.when(
            loading: () => const SizedBox(height: 44, child: Center(child: CircularProgressIndicator())),
            error: (error, stackTrace) => const AppText('No se pudo cargar el balance', color: Colors.red),
            data: (state) => Row(
              children: [
                Expanded(
                  child: AppText(
                    '\$${state.summary.balance.toStringAsFixed(2)}',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kPrimaryColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.kSuccess.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const AppText('Ingresos', fontSize: 10, color: AppColors.kNeutral600),
                      AppText(
                        '+\$${state.summary.totalIncome.toStringAsFixed(2)}',
                        color: AppColors.kSuccess,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ],
                  ),
                ),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.kWarning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const AppText('Egresos', fontSize: 10, color: AppColors.kNeutral600),
                      AppText(
                        '-\$${state.summary.totalExpense.toStringAsFixed(2)}',
                        color: AppColors.kWarning,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountFilterCard(AsyncValue accountsAsync, {required bool isMobile}) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          accountsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => const Text('Error al cargar cuentas', style: TextStyle(color: Colors.red)),
            data: (accounts) {
              return Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedAccountId ?? '',
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Filtrar por cuenta',
                        filled: true,
                        fillColor: AppColors.kNeutral50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Todas las cuentas', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        ...accounts.map<DropdownMenuItem<String>>(
                          (acc) => DropdownMenuItem<String>(
                            value: acc.id,
                            child: Text(
                              '${acc.isDefault ? "★ " : ""}${acc.name} (\$${acc.balance.toStringAsFixed(2)})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedAccountId = (value == null || value.isEmpty) ? null : value;
                          ref.invalidate(transactionsListProvider(widget.businessId, _selectedAccountId));
                        });
                      },
                    ),
                  ),
                  const Gap(8),
                  CreateAccountSideButton(
                    businessId: widget.businessId,
                    tooltip: 'Agregar nueva cuenta de negocio',
                    onAccountCreated: (created) {
                      setState(() {
                        _selectedAccountId = created.id;
                        ref.invalidate(transactionsListProvider(widget.businessId, _selectedAccountId));
                      });
                    },
                  ),
                ],
              );
            },
          ),
          if (!isMobile) ...[
            const Gap(10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      NavigationService.navigateTo(context, Routes.transferFunds, arguments: widget.businessId);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kSecondaryColor,
                      side: const BorderSide(color: AppColors.kSecondaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 17),
                    label: const Text('Transferir', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      NavigationService.navigateTo(context, Routes.addTransaction, arguments: widget.businessId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kPrimaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: const Text('Movimiento', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                  ),
                ),
                const Gap(8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.kSecondaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    tooltip: 'Abrir Cajón',
                    icon: const Icon(Icons.point_of_sale_rounded, color: Colors.white, size: 20),
                    onPressed: () async {
                      await ref.read(printerServiceProvider).openCashDrawerWithFeedback(context);
                    },
                  ),
                ),
                const Gap(8),
                ref.watch(hasSavedPrinterProvider).when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (hasPrinter) => Container(
                        decoration: BoxDecoration(
                          color: hasPrinter ? Colors.red : AppColors.kPrimaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          tooltip: hasPrinter ? 'Desvincular Impresora' : 'Seleccionar Impresora',
                          icon: Icon(
                            hasPrinter ? Icons.print_disabled_rounded : Icons.print_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () async {
                            if (hasPrinter) {
                              await showDialog(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: const AppText('Eliminar impresora seleccionada', fontWeight: FontWeight.bold),
                                  content: const AppText('¿Estás seguro de que deseas eliminar la impresora seleccionada?'),
                                  actions: [
                                    TextButton(onPressed: () => NavigationService.pop(dialogContext), child: const AppText('Cancelar', color: AppColors.kNeutral600)),
                                    ElevatedButton(
                                      onPressed: () async {
                                        NavigationService.pop(dialogContext);
                                        await ref.read(printerServiceProvider).clearSavedPrinter();
                                        ref.invalidate(hasSavedPrinterProvider);
                                        if (mounted) {
                                          SnackbarUtil.showSuccess(context, 'Impresora desvinculada correctamente.');
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
                                      child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              await ref.read(printerServiceProvider).showPrinterSelectionModal(context);
                              ref.invalidate(hasSavedPrinterProvider);
                            }
                          },
                        ),
                      ),
                    ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccountsBalancesStrip(AsyncValue accountsAsync) {
    final bool isAdmin = ref.watch(isBusinessAdminProvider(widget.businessId));

    return accountsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (accounts) {
        if (accounts.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: accounts.length,
            separatorBuilder: (_, _) => const Gap(10),
            itemBuilder: (context, index) {
              final AccountModel acc = accounts[index];
              final isSelected = _selectedAccountId == acc.id;
              final bool isDebit = acc.isDebitOrBank == true;
              final bool canBeDefault = !acc.isCreditOrLoan;

              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() {
                    _selectedAccountId = isSelected ? null : acc.id;
                    ref.invalidate(transactionsListProvider(widget.businessId, _selectedAccountId));
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 235,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.kPrimaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.kPrimaryColor
                          : (acc.isDefault ? Colors.amber.shade600 : AppColors.kNeutral200),
                      width: (isSelected || acc.isDefault) ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.18)
                              : (isDebit
                                  ? AppColors.kSecondaryColor.withValues(alpha: 0.12)
                                  : AppColors.kPrimaryColor.withValues(alpha: 0.1)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDebit ? Icons.credit_card_rounded : Icons.payments_outlined,
                          size: 20,
                          color: isSelected
                              ? Colors.white
                              : (isDebit ? AppColors.kSecondaryColor : AppColors.kPrimaryColor),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppText(
                              acc.name,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white.withValues(alpha: 0.9) : AppColors.kNeutral700,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(2),
                            AppText(
                              '\$${acc.balance.toStringAsFixed(2)}',
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.kPrimaryColor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (acc.isDefault)
                        Tooltip(
                          message: 'Cuenta predeterminada para cobros',
                          child: Icon(
                            Icons.star_rounded,
                            color: isSelected ? Colors.amberAccent : Colors.amber.shade700,
                            size: 22,
                          ),
                        )
                      else if (isAdmin && canBeDefault)
                        Tooltip(
                          message: 'Establecer como predeterminada para cobros',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _isSettingDefault ? null : () => _handleSetDefaultAccount(acc),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.star_border_rounded,
                                color: isSelected ? Colors.white70 : AppColors.kNeutral400,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
