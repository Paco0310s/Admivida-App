import 'package:admivida/business/features/transactions/models/account_model.dart';
import 'package:admivida/business/features/transactions/models/paginated_transactions_model.dart';
import 'package:admivida/business/features/transactions/models/transactions_list_state.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/create_account_dialog.dart';
import 'package:admivida/common/widgets/responsive.dart';
import 'package:admivida/personal/features/transactions/personal_transactions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class PersonalTransactionsScreen extends ConsumerWidget {
  const PersonalTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isMobile = Responsive.isMobile(context);

    return AppScaffold(
      title: 'Finanzas Personales',
      appBar: AppBar(
        title: const AppText('Finanzas Personales', color: AppColors.kNeutral100),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.kPrimaryColor,
      ),
      mobile: const PersonalTransactionsListView(),
      tablet: const PersonalTransactionsListView(),
      desktop: const PersonalTransactionsListView(),
      floatingActionButton: isMobile
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'personalTransferFunds',
                  tooltip: 'Transferir / Pagar tarjeta o préstamo',
                  onPressed: () {
                    NavigationService.navigateTo(context, Routes.personalTransferFunds);
                  },
                  backgroundColor: AppColors.kSecondaryColor,
                  child: const Icon(Icons.swap_horiz, color: AppColors.kNeutral100),
                ),
                const SizedBox(width: 14),
                FloatingActionButton(
                  heroTag: 'personalAddTransaction',
                  tooltip: 'Agregar movimiento personal',
                  onPressed: () {
                    NavigationService.navigateTo(context, Routes.personalAddTransaction);
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

class PersonalTransactionsListView extends ConsumerStatefulWidget {
  const PersonalTransactionsListView({super.key});

  @override
  ConsumerState<PersonalTransactionsListView> createState() => _PersonalTransactionsListViewState();
}

class _PersonalTransactionsListViewState extends ConsumerState<PersonalTransactionsListView> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedAccountId;
  String _selectedCategory = 'REAL'; // 'REAL' (Efectivo y Débito) | 'CREDIT' (Tarjetas de Crédito y Préstamos)

  bool get _isCreditTab => _selectedCategory == 'CREDIT';

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
      ref
          .read(personalTransactionsListProvider(_selectedAccountId, category: _selectedCategory).notifier)
          .fetchNextPage();
    }
  }

  Future<void> _refreshAll() async {
    ref.invalidate(personalAccountsProvider);
    await ref
        .read(personalTransactionsListProvider(_selectedAccountId, category: _selectedCategory).notifier)
        .refresh();
  }

  void _selectAccount(String? accountId) {
    setState(() {
      _selectedAccountId = (accountId == null || accountId.isEmpty) ? null : accountId;
      ref.invalidate(personalTransactionsListProvider(_selectedAccountId, category: _selectedCategory));
    });
  }

  void _switchCategory(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _selectedAccountId = null;
      ref.invalidate(personalTransactionsListProvider(null, category: _selectedCategory));
    });
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(
      personalTransactionsListProvider(_selectedAccountId, category: _selectedCategory),
    );
    final accountsAsync = ref.watch(personalAccountsProvider);
    final bool isMobile = Responsive.isMobile(context);

    final List<AccountModel> allAccounts = accountsAsync.value ?? const [];
    final List<AccountModel> realMoneyAccounts =
        allAccounts.where((a) => !a.isCreditOrLoan).toList();
    final List<AccountModel> creditAccounts =
        allAccounts.where((a) => a.isCreditOrLoan).toList();
    final List<AccountModel> activeTabAccounts =
        _isCreditTab ? creditAccounts : realMoneyAccounts;

    final double totalRealMoney =
        realMoneyAccounts.fold(0.0, (sum, a) => sum + a.balance);
    final double totalDebt =
        creditAccounts.fold(0.0, (sum, a) => sum + a.effectiveDebt);
    final double totalAvailableCredit = creditAccounts
        .where((a) => a.hasCreditLimit)
        .fold(0.0, (sum, a) => sum + (a.effectiveAvailableCredit ?? 0.0));

    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selector superior: Mi Dinero (Efectivo/Débito) vs Créditos y Deudas (Tarjetas/Préstamos)
            _buildCategoryToggle(
              totalRealMoney: totalRealMoney,
              totalDebt: totalDebt,
              creditCount: creditAccounts.length,
            ),
            const Gap(12),

            // Summary + Filter Header
            if (!isMobile) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        transactionsAsync,
                        totalRealMoney: totalRealMoney,
                        totalDebt: totalDebt,
                        totalAvailableCredit: totalAvailableCredit,
                        creditAccounts: creditAccounts,
                      ),
                    ),
                    const Gap(14),
                    Expanded(
                      child: _buildAccountFilterCard(
                        accountsAsync,
                        activeTabAccounts: activeTabAccounts,
                        isMobile: false,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _buildSummaryCard(
                transactionsAsync,
                totalRealMoney: totalRealMoney,
                totalDebt: totalDebt,
                totalAvailableCredit: totalAvailableCredit,
                creditAccounts: creditAccounts,
              ),
              const Gap(10),
              _buildAccountFilterCard(
                accountsAsync,
                activeTabAccounts: activeTabAccounts,
                isMobile: true,
              ),
            ],
            const Gap(12),

            // Tarjetas individuales con el balance / deuda y disponible de cada cuenta
            _buildAccountsBalancesStrip(activeTabAccounts),
            if (activeTabAccounts.isNotEmpty) const Gap(12),

            // Lista paginada de movimientos
            Expanded(
              child: transactionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(
                  child: AppText('Error al cargar movimientos: $error', color: Colors.red),
                ),
                data: (listState) {
                  final transactions = listState.transactions;

                  if (transactions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: (_isCreditTab ? AppColors.kWarning : AppColors.kPrimaryColor)
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isCreditTab
                                  ? Icons.credit_score_rounded
                                  : Icons.account_balance_wallet_rounded,
                              size: 36,
                              color: _isCreditTab ? AppColors.kWarning : AppColors.kPrimaryColor,
                            ),
                          ),
                          const Gap(12),
                          AppText(
                            _isCreditTab && creditAccounts.isEmpty
                                ? 'Aún no tienes tarjetas de crédito ni préstamos registrados'
                                : AppTexts.noData,
                            color: AppColors.kNeutral600,
                            fontWeight: FontWeight.w600,
                          ),
                          const Gap(4),
                          AppText(
                            _isCreditTab
                                ? 'Usa el botón + junto al selector de cuentas para agregar una tarjeta de crédito o un préstamo.'
                                : 'Agrega una entrada o salida para comenzar a llevar tu control personal.',
                            color: AppColors.kNeutral500,
                            fontSize: 12.5,
                          ),
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

                      // En pestaña de crédito: EXPENSE = Cargo/Compra (aumenta deuda), INCOME = Abono/Pago (reduce deuda)
                      final Color amountColor = isIncome ? AppColors.kSuccess : AppColors.kWarning;
                      final String amountPrefix = _isCreditTab
                          ? (isIncome ? 'Abono -' : 'Cargo +')
                          : (isIncome ? '+' : '-');

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
                                color: amountColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(13),
                              ),
                              child: Icon(
                                _isCreditTab
                                    ? (isIncome ? Icons.check_circle_outline_rounded : Icons.shopping_bag_outlined)
                                    : (isIncome ? Icons.south_west_rounded : Icons.north_east_rounded),
                                color: amountColor,
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
                                        : '${_isCreditTab ? (isIncome ? 'Abono a crédito' : 'Compra / Disposición') : (isIncome ? 'Ingreso' : 'Egreso')}${transaction.paymentMethodName != null ? ' · ${transaction.paymentMethodName}' : ''}',
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
                                  '$amountPrefix\$${transaction.amount.toStringAsFixed(2)}',
                                  color: amountColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
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

  Widget _buildCategoryToggle({
    required double totalRealMoney,
    required double totalDebt,
    required int creditCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.kNeutral200.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CategoryTabButton(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Mi Dinero (Efectivo y Débito)',
              subtitle: '\$${totalRealMoney.toStringAsFixed(2)} disponible',
              isSelected: !_isCreditTab,
              activeColor: AppColors.kPrimaryColor,
              onTap: () => _switchCategory('REAL'),
            ),
          ),
          const Gap(6),
          Expanded(
            child: _CategoryTabButton(
              icon: Icons.credit_score_rounded,
              title: 'Créditos y Préstamos${creditCount > 0 ? ' ($creditCount)' : ''}',
              subtitle: 'Debes: \$${totalDebt.toStringAsFixed(2)}',
              isSelected: _isCreditTab,
              activeColor: AppColors.kWarning,
              onTap: () => _switchCategory('CREDIT'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    AsyncValue<TransactionsListState> transactionsAsync, {
    required double totalRealMoney,
    required double totalDebt,
    required double totalAvailableCredit,
    required List<AccountModel> creditAccounts,
  }) {
    final bool isAllAccounts = _selectedAccountId == null || _selectedAccountId!.isEmpty;
    final AccountModel? selectedCreditAccount = _isCreditTab && !isAllAccounts
        ? creditAccounts.where((a) => a.id == _selectedAccountId).firstOrNull
        : null;

    if (_isCreditTab) {
      final double displayedAvailable = selectedCreditAccount != null
          ? (selectedCreditAccount.effectiveAvailableCredit ?? 0.0)
          : totalAvailableCredit;
      final bool showAvailableBadge = selectedCreditAccount != null
          ? selectedCreditAccount.hasCreditLimit
          : creditAccounts.any((a) => a.hasCreditLimit);

      return AppCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              isAllAccounts ? 'Deuda total en créditos y préstamos' : 'Deuda actual de la cuenta',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.kNeutral600,
            ),
            const Gap(6),
            transactionsAsync.when(
              loading: () => const SizedBox(height: 44, child: Center(child: CircularProgressIndicator())),
              error: (error, stackTrace) => const AppText('No se pudo cargar el resumen', color: Colors.red),
              data: (state) => Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          '\$${state.summary.balance.toStringAsFixed(2)}',
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: state.summary.balance > 0 ? AppColors.kWarning : AppColors.kSuccess,
                        ),
                        if (showAvailableBadge) ...[
                          const Gap(2),
                          AppText(
                            'Crédito disponible: \$${displayedAvailable.toStringAsFixed(2)}',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kPrimaryColor,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.kWarning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const AppText('Cargos / Usado', fontSize: 10, color: AppColors.kNeutral600),
                        AppText(
                          '\$${state.summary.totalExpense.toStringAsFixed(2)}',
                          color: AppColors.kWarning,
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
                      color: AppColors.kSuccess.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const AppText('Abonado', fontSize: 10, color: AppColors.kNeutral600),
                        AppText(
                          '\$${state.summary.totalIncome.toStringAsFixed(2)}',
                          color: AppColors.kSuccess,
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

    final double netAfterDebt = totalRealMoney - totalDebt;

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppText(
            isAllAccounts ? 'Balance total disponible (Dinero propio)' : 'Balance de la cuenta seleccionada',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.kNeutral600,
          ),
          const Gap(6),
          transactionsAsync.when(
            loading: () => const SizedBox(height: 44, child: Center(child: CircularProgressIndicator())),
            error: (error, stackTrace) => const AppText('No se pudo cargar el balance', color: Colors.red),
            data: (state) => Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        '\$${state.summary.balance.toStringAsFixed(2)}',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kPrimaryColor,
                      ),
                      if (isAllAccounts && totalDebt > 0) ...[
                        const Gap(2),
                        AppText(
                          'Libre tras deudas: \$${netAfterDebt.toStringAsFixed(2)}',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: netAfterDebt >= 0 ? AppColors.kNeutral600 : AppColors.kWarning,
                        ),
                      ],
                    ],
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

  Widget _buildAccountFilterCard(
    AsyncValue<List<AccountModel>> accountsAsync, {
    required List<AccountModel> activeTabAccounts,
    required bool isMobile,
  }) {
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
            data: (_) {
              final hasSelectedInList =
                  _selectedAccountId == null || activeTabAccounts.any((a) => a.id == _selectedAccountId);
              final currentValue = hasSelectedInList ? (_selectedAccountId ?? '') : '';

              return Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      key: ValueKey('${_selectedCategory}_$currentValue'),
                      initialValue: currentValue,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: _isCreditTab ? 'Filtrar tarjeta o préstamo' : 'Filtrar por cuenta',
                        filled: true,
                        fillColor: AppColors.kNeutral50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: '',
                          child: Text(
                            _isCreditTab ? 'Todos mis créditos y préstamos' : 'Todas mis cuentas',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...activeTabAccounts.map<DropdownMenuItem<String>>(
                          (acc) => DropdownMenuItem<String>(
                            value: acc.id,
                            child: Text(
                              acc.dropdownLabel,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) => _selectAccount(value),
                    ),
                  ),
                  const Gap(8),
                  CreateAccountSideButton(
                    initialTypeCode: _isCreditTab ? 'BANK_CREDIT' : 'CASH',
                    tooltip: _isCreditTab
                        ? 'Agregar tarjeta de crédito o préstamo'
                        : 'Agregar cuenta de efectivo o débito',
                    onAccountCreated: (created) {
                      if (created.isCreditOrLoan && !_isCreditTab) {
                        setState(() {
                          _selectedCategory = 'CREDIT';
                          _selectedAccountId = created.id;
                        });
                      } else if (!created.isCreditOrLoan && _isCreditTab) {
                        setState(() {
                          _selectedCategory = 'REAL';
                          _selectedAccountId = created.id;
                        });
                      } else {
                        _selectAccount(created.id);
                      }
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
                      NavigationService.navigateTo(context, Routes.personalTransferFunds);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kSecondaryColor,
                      side: const BorderSide(color: AppColors.kSecondaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 17),
                    label: Text(
                      _isCreditTab ? 'Pagar / Disponer' : 'Transferir',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                    ),
                  ),
                ),
                const Gap(8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      NavigationService.navigateTo(
                        context,
                        Routes.personalAddTransaction,
                        arguments: _selectedAccountId,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kPrimaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: Text(
                      _isCreditTab ? 'Cargo / Abono' : 'Movimiento',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
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

  Widget _buildAccountsBalancesStrip(List<AccountModel> accounts) {
    if (accounts.isEmpty) return const SizedBox.shrink();

    final double stripHeight = _isCreditTab ? 104 : 78;

    return SizedBox(
      height: stripHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: accounts.length,
        separatorBuilder: (_, _) => const Gap(10),
        itemBuilder: (context, index) {
          final acc = accounts[index];
          final isSelected = _selectedAccountId == acc.id;

          if (acc.isCreditOrLoan) {
            return _buildCreditAccountCard(acc, isSelected: isSelected);
          }

          final isDebit = acc.isDebitOrBank;

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _selectAccount(isSelected ? null : acc.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 215,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.kPrimaryColor : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.kPrimaryColor : AppColors.kNeutral200,
                  width: isSelected ? 1.5 : 1,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreditAccountCard(AccountModel acc, {required bool isSelected}) {
    final bool hasLimit = acc.hasCreditLimit;
    final double debt = acc.effectiveDebt;
    final double available = acc.effectiveAvailableCredit ?? 0.0;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _selectAccount(isSelected ? null : acc.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 255,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.kPrimaryColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.kPrimaryColor : AppColors.kNeutral200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  hasLimit ? Icons.credit_score_rounded : Icons.handshake_outlined,
                  size: 18,
                  color: isSelected ? Colors.white : AppColors.kWarning,
                ),
                const Gap(6),
                Expanded(
                  child: AppText(
                    acc.name,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppColors.kNeutral900,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Debes',
                      fontSize: 10.5,
                      color: isSelected ? Colors.white70 : AppColors.kNeutral500,
                    ),
                    AppText(
                      '\$${debt.toStringAsFixed(2)}',
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (debt > 0 ? AppColors.kWarning : AppColors.kSuccess),
                    ),
                  ],
                ),
                if (hasLimit)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppText(
                        'Disponible',
                        fontSize: 10.5,
                        color: isSelected ? Colors.white70 : AppColors.kNeutral500,
                      ),
                      AppText(
                        '\$${available.toStringAsFixed(2)}',
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.kPrimaryColor,
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.16)
                          : AppColors.kNeutral100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: AppText(
                      'Préstamo',
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.kNeutral600,
                    ),
                  ),
              ],
            ),
            if (hasLimit)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: acc.creditUsageRatio,
                  minHeight: 5,
                  backgroundColor: isSelected
                      ? Colors.white.withValues(alpha: 0.22)
                      : AppColors.kNeutral200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isSelected
                        ? Colors.white
                        : (acc.creditUsageRatio > 0.8 ? AppColors.kWarning : AppColors.kPrimaryColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTabButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _CategoryTabButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? activeColor : AppColors.kNeutral600,
            ),
            const Gap(8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    title,
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? AppColors.kNeutral900 : AppColors.kNeutral600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppText(
                    subtitle,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? activeColor : AppColors.kNeutral500,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
