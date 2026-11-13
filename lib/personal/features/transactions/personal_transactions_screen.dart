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
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

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
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
  String? _selectedAccountId;
  String _selectedCategory = 'REAL'; // 'REAL' (Efectivo y Débito) | 'CREDIT' (Tarjetas de Crédito y Préstamos)
  bool _showAnalytics = true;
  bool _useLineChart = false;
  int _touchedAccountSlice = -1;

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
    if (_scrollController.hasClients && _scrollController.position.extentAfter < 300) {
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
      _touchedAccountSlice = -1;
      ref.invalidate(personalTransactionsListProvider(_selectedAccountId, category: _selectedCategory));
    });
  }

  void _switchCategory(String category) {
    if (_selectedCategory == category) return;
    setState(() {
      _selectedCategory = category;
      _selectedAccountId = null;
      _touchedAccountSlice = -1;
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
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, isMobile ? 16 : 24, isMobile ? 16 : 24, 0),
            sliver: SliverToBoxAdapter(
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
                  if (activeTabAccounts.isNotEmpty) const Gap(14),

                  // Sección de Gráficas y Salud Financiera
                  _buildVisualAnalyticsSection(
                    transactionsAsync: transactionsAsync,
                    activeTabAccounts: activeTabAccounts,
                    totalRealMoney: totalRealMoney,
                    totalDebt: totalDebt,
                    totalAvailableCredit: totalAvailableCredit,
                    isMobile: isMobile,
                  ),
                  const Gap(16),

                  // Encabezado del historial de movimientos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _isCreditTab ? AppColors.kWarning : AppColors.kSecondaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const Gap(8),
                          AppText(
                            _isCreditTab ? 'Historial de Cargos y Abonos' : 'Historial de Movimientos',
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kNeutral900,
                          ),
                        ],
                      ),
                      if (_selectedAccountId != null && _selectedAccountId!.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _selectAccount(null),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.filter_alt_off_rounded, size: 15, color: AppColors.kPrimaryColor),
                          label: const AppText(
                            'Ver todas las cuentas',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kPrimaryColor,
                          ),
                        ),
                    ],
                  ),
                  const Gap(10),
                ],
              ),
            ),
          ),

          // Lista paginada de movimientos
          transactionsAsync.when(
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, stackTrace) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: AppText('Error al cargar movimientos: $error', color: Colors.red),
              ),
            ),
            data: (listState) {
              final transactions = listState.transactions;

              if (transactions.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                    child: Center(
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
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 0, isMobile ? 16 : 24, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
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
                    childCount: transactions.length + (listState.isLoadingMore ? 1 : 0),
                  ),
                ),
              );
            },
          ),
        ],
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

  // ===========================================================================
  // SECCIÓN DE ANÁLISIS VISUAL Y GRÁFICAS (FINANZAS PERSONALES)
  // ===========================================================================
  Widget _buildVisualAnalyticsSection({
    required AsyncValue<TransactionsListState> transactionsAsync,
    required List<AccountModel> activeTabAccounts,
    required double totalRealMoney,
    required double totalDebt,
    required double totalAvailableCredit,
    required bool isMobile,
  }) {
    final listState = transactionsAsync.value;
    if (listState == null) return const SizedBox.shrink();

    final transactions = listState.transactions;
    final summary = listState.summary;

    if (transactions.isEmpty && activeTabAccounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.kPrimaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Gap(8),
                AppText(
                  _isCreditTab ? 'Panorama de Créditos y Deudas' : 'Panorama de tus Finanzas',
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kNeutral900,
                ),
              ],
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _showAnalytics = !_showAnalytics),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.kNeutral200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showAnalytics ? Icons.insights_rounded : Icons.bar_chart_rounded,
                      size: 15,
                      color: AppColors.kPrimaryColor,
                    ),
                    const Gap(5),
                    AppText(
                      _showAnalytics ? 'Ocultar gráficas' : 'Mostrar gráficas',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kPrimaryColor,
                    ),
                    const Gap(2),
                    Icon(
                      _showAnalytics ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.kNeutral500,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_showAnalytics) ...[
          const Gap(12),
          // 1. Termómetro de Salud Financiera (Ingresos vs Gastos / Uso de Crédito)
          _buildFinancialHealthBarCard(
            summary: summary,
            totalRealMoney: totalRealMoney,
            totalDebt: totalDebt,
            totalAvailableCredit: totalAvailableCredit,
          ),
          const Gap(12),
          // 2. Gráficas: Flujo Diario + Distribución de Cuentas y Conceptos
          if (!isMobile)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 6,
                    child: _buildDailyFlowChartCard(transactions),
                  ),
                  const Gap(14),
                  Expanded(
                    flex: 5,
                    child: _buildAccountsAndConceptsCard(
                      accounts: activeTabAccounts,
                      transactions: transactions,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _buildDailyFlowChartCard(transactions),
            const Gap(12),
            _buildAccountsAndConceptsCard(
              accounts: activeTabAccounts,
              transactions: transactions,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildFinancialHealthBarCard({
    required TransactionSummary summary,
    required double totalRealMoney,
    required double totalDebt,
    required double totalAvailableCredit,
  }) {
    if (_isCreditTab) {
      final double totalLimit = totalDebt + totalAvailableCredit;
      final double usageRatio = totalLimit > 0 ? (totalDebt / totalLimit).clamp(0.0, 1.0) : 0.0;
      final double usagePercent = usageRatio * 100;
      final Color statusColor = usagePercent <= 30
          ? AppColors.kSuccess
          : (usagePercent <= 70 ? AppColors.kWarning : AppColors.kError);
      final String statusLabel = usagePercent <= 30
          ? 'Uso saludable (<30%)'
          : (usagePercent <= 70 ? 'Uso moderado' : 'Uso elevado');

      return AppCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        'Nivel de Utilización de Crédito',
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kNeutral900,
                      ),
                      AppText(
                        'Qué parte de tu línea de crédito tienes ocupada frente a tu disponible',
                        fontSize: 11.5,
                        color: AppColors.kNeutral500,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AppText(
                    '${usagePercent.toStringAsFixed(0)}% • $statusLabel',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const Gap(12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: usageRatio,
                minHeight: 10,
                backgroundColor: AppColors.kPrimary100.withValues(alpha: 0.45),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
            const Gap(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 9, height: 9, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                    const Gap(6),
                    AppText(
                      'Ocupado: ${_currencyFormat.format(totalDebt)}',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kNeutral800,
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(color: AppColors.kPrimaryColor, shape: BoxShape.circle),
                    ),
                    const Gap(6),
                    AppText(
                      'Disponible: ${_currencyFormat.format(totalAvailableCredit)}',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kPrimaryColor,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Pestaña Mi Dinero (Efectivo y Débito): Comparativa Ingresos vs Egresos + Tasa de Ahorro
    final double income = summary.totalIncome;
    final double expense = summary.totalExpense;
    final double totalFlow = income + expense;
    final double incomeShare = totalFlow > 0 ? (income / totalFlow).clamp(0.0, 1.0) : 0.5;
    final double savedAmount = income - expense;
    final double savingsRate = income > 0 ? ((savedAmount / income) * 100) : 0.0;
    final bool isPositiveSavings = savedAmount >= 0;

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Balance de Entradas vs. Salidas',
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.kNeutral900,
                    ),
                    AppText(
                      'Proporción entre lo que ingresa y lo que gastas en tus cuentas',
                      fontSize: 11.5,
                      color: AppColors.kNeutral500,
                    ),
                  ],
                ),
              ),
              if (income > 0 || expense > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositiveSavings ? AppColors.kSuccess : AppColors.kWarning).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AppText(
                    isPositiveSavings
                        ? 'Conservas ${savingsRate.clamp(0, 100).toStringAsFixed(0)}% de tus ingresos'
                        : 'Gastos superan ingresos por ${_currencyFormat.format(savedAmount.abs())}',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPositiveSavings ? AppColors.kSuccess : AppColors.kWarning,
                  ),
                ),
            ],
          ),
          const Gap(12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: ((incomeShare * 100).round()).clamp(5, 95),
                    child: Container(color: AppColors.kSuccess),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    flex: (((1 - incomeShare) * 100).round()).clamp(5, 95),
                    child: Container(color: AppColors.kWarning),
                  ),
                ],
              ),
            ),
          ),
          const Gap(10),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(color: AppColors.kSuccess, shape: BoxShape.circle),
                  ),
                  const Gap(6),
                  AppText(
                    'Ingresos: +${_currencyFormat.format(income)}',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kNeutral800,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: const BoxDecoration(color: AppColors.kWarning, shape: BoxShape.circle),
                  ),
                  const Gap(6),
                  AppText(
                    'Gastos: -${_currencyFormat.format(expense)}',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kNeutral800,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_outlined, size: 14, color: AppColors.kPrimaryColor),
                  const Gap(4),
                  AppText(
                    'Patrimonio libre (Dinero - Deudas): ${_currencyFormat.format(totalRealMoney - totalDebt)}',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: (totalRealMoney - totalDebt) >= 0 ? AppColors.kPrimaryColor : AppColors.kWarning,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyFlowChartCard(List<Transaction> transactions) {
    // Agrupar movimientos por fecha (últimos 7 días con actividad, orden cronológico)
    final Map<String, ({double income, double expense, DateTime date})> grouped = {};
    for (final tx in transactions) {
      final dayKey =
          '${tx.createdAt.year}-${tx.createdAt.month.toString().padLeft(2, '0')}-${tx.createdAt.day.toString().padLeft(2, '0')}';
      final current = grouped[dayKey] ??
          (
            income: 0.0,
            expense: 0.0,
            date: DateTime(tx.createdAt.year, tx.createdAt.month, tx.createdAt.day),
          );
      if (tx.type == TransactionType.income) {
        grouped[dayKey] = (
          income: current.income + tx.amount,
          expense: current.expense,
          date: current.date,
        );
      } else {
        grouped[dayKey] = (
          income: current.income,
          expense: current.expense + tx.amount,
          date: current.date,
        );
      }
    }

    final sortedDays = grouped.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    final recentDays = sortedDays.length > 7 ? sortedDays.sublist(sortedDays.length - 7) : sortedDays;

    double maxVal = 0;
    for (final d in recentDays) {
      if (d.income > maxVal) maxVal = d.income;
      if (d.expense > maxVal) maxVal = d.expense;
    }
    final double maxY = maxVal <= 0 ? 100 : (maxVal * 1.25);

    final String positiveLabel = _isCreditTab ? 'Abonos' : 'Ingresos';
    final String negativeLabel = _isCreditTab ? 'Cargos' : 'Gastos';

    // Calcular mayor gasto y promedio por movimiento
    final expenseTxs = transactions.where((t) => t.type == TransactionType.expense).toList();
    final double maxSingleExpense = expenseTxs.fold<double>(0.0, (m, t) => t.amount > m ? t.amount : m);
    final double avgExpense =
        expenseTxs.isNotEmpty ? expenseTxs.fold<double>(0.0, (s, t) => s + t.amount) / expenseTxs.length : 0.0;

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      _isCreditTab ? 'Flujo Diario de Cargos vs. Abonos' : 'Flujo Diario de Ingresos vs. Gastos',
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.kNeutral900,
                    ),
                    const AppText(
                      'Toca cualquier día para ver cuánto entró y cuánto salió',
                      fontSize: 11.5,
                      color: AppColors.kNeutral500,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.kNeutral100,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: AppColors.kNeutral200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMiniChartModeBtn(
                      icon: Icons.bar_chart_rounded,
                      label: 'Barras',
                      selected: !_useLineChart,
                      onTap: () => setState(() => _useLineChart = false),
                    ),
                    _buildMiniChartModeBtn(
                      icon: Icons.show_chart_rounded,
                      label: 'Línea',
                      selected: _useLineChart,
                      onTap: () => setState(() => _useLineChart = true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(10),
          Row(
            children: [
              _buildLegendDot(positiveLabel, AppColors.kSuccess),
              const Gap(14),
              _buildLegendDot(negativeLabel, AppColors.kWarning),
            ],
          ),
          const Gap(16),
          if (recentDays.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: AppText('Registra movimientos para visualizar tu gráfica diaria.', color: AppColors.kNeutral500),
              ),
            )
          else
            SizedBox(
              height: 195,
              child: _useLineChart
                  ? LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: maxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) =>
                              const FlLine(color: AppColors.kNeutral200, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final day = recentDays[spot.x.toInt()];
                                final isIncLine = spot.barIndex == 0;
                                final dateLabel = DateFormat('dd/MM/yyyy').format(day.date);
                                return LineTooltipItem(
                                  isIncLine ? '$dateLabel\n$positiveLabel: ' : '$negativeLabel: ',
                                  const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                  children: [
                                    TextSpan(
                                      text: _currencyFormat.format(spot.y),
                                      style: TextStyle(
                                        color: isIncLine ? const Color(0xFF4ADE80) : const Color(0xFFFBBF24),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList();
                            },
                          ),
                        ),
                        titlesData: _buildDailyChartTitles(recentDays, maxY),
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(
                              recentDays.length,
                              (i) => FlSpot(i.toDouble(), recentDays[i].income),
                            ),
                            isCurved: true,
                            preventCurveOverShooting: true,
                            color: AppColors.kSuccess,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.kSuccess.withValues(alpha: 0.12),
                            ),
                          ),
                          LineChartBarData(
                            spots: List.generate(
                              recentDays.length,
                              (i) => FlSpot(i.toDouble(), recentDays[i].expense),
                            ),
                            isCurved: true,
                            preventCurveOverShooting: true,
                            color: AppColors.kWarning,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.kWarning.withValues(alpha: 0.10),
                            ),
                          ),
                        ],
                      ),
                    )
                  : BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) =>
                              const FlLine(color: AppColors.kNeutral200, strokeWidth: 1),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: _buildDailyChartTitles(recentDays, maxY),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final day = recentDays[groupIndex];
                              final dateLabel = DateFormat('dd/MM/yyyy').format(day.date);
                              return BarTooltipItem(
                                '$dateLabel\n',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                children: [
                                  TextSpan(
                                    text: '$positiveLabel: ${_currencyFormat.format(day.income)}\n',
                                    style: const TextStyle(
                                      color: Color(0xFF4ADE80),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '$negativeLabel: ${_currencyFormat.format(day.expense)}',
                                    style: const TextStyle(
                                      color: Color(0xFFFBBF24),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        barGroups: List.generate(recentDays.length, (index) {
                          final d = recentDays[index];
                          return BarChartGroupData(
                            x: index,
                            barsSpace: 4,
                            barRods: [
                              BarChartRodData(
                                toY: d.income,
                                color: AppColors.kSuccess,
                                width: 10,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                              BarChartRodData(
                                toY: d.expense,
                                color: AppColors.kWarning,
                                width: 10,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
            ),
          const Gap(12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _buildQuickInsightPill(
                icon: Icons.trending_down_rounded,
                color: AppColors.kWarning,
                label: 'Mayor ${negativeLabel.toLowerCase()}',
                value: _currencyFormat.format(maxSingleExpense),
              ),
              _buildQuickInsightPill(
                icon: Icons.calculate_outlined,
                color: AppColors.kPrimaryColor,
                label: 'Promedio por ${negativeLabel.toLowerCase()}',
                value: _currencyFormat.format(avgExpense),
              ),
            ],
          ),
        ],
      ),
    );
  }

  FlTitlesData _buildDailyChartTitles(
    List<({double income, double expense, DateTime date})> recentDays,
    double maxY,
  ) {
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 44,
          getTitlesWidget: (value, meta) {
            if (value == 0 || value >= maxY * 0.98) return const SizedBox.shrink();
            return Text(
              NumberFormat.compact(locale: 'es_MX').format(value),
              style: const TextStyle(fontSize: 10, color: AppColors.kNeutral500),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: (value, meta) {
            final idx = value.toInt();
            if (idx >= 0 && idx < recentDays.length) {
              final d = recentDays[idx].date;
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 10, color: AppColors.kNeutral600, fontWeight: FontWeight.w500),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildAccountsAndConceptsCard({
    required List<AccountModel> accounts,
    required List<Transaction> transactions,
  }) {
    final palette = [
      AppColors.kPrimaryColor,
      AppColors.kSecondaryColor,
      const Color(0xFF0284C7),
      const Color(0xFF6366F1),
      AppColors.kWarning,
      const Color(0xFF0D9488),
    ];

    // Cuentas con saldo o deuda positiva para la gráfica de dona
    final positiveAccounts = accounts
        .where((a) => (_isCreditTab ? a.effectiveDebt : a.balance) > 0)
        .toList();
    final double totalAccountValue = positiveAccounts.fold(
      0.0,
      (sum, a) => sum + (_isCreditTab ? a.effectiveDebt : a.balance),
    );

    // Top 3 conceptos de gasto/cargo reciente
    final Map<String, double> conceptTotals = {};
    double totalExpenseSum = 0;
    for (final tx in transactions) {
      if (tx.type == TransactionType.expense && tx.amount > 0) {
        final rawDesc = tx.description?.trim() ?? '';
        final label = rawDesc.isNotEmpty
            ? rawDesc
            : (tx.paymentMethodName ?? (tx.accountName ?? 'Gasto general'));
        conceptTotals[label] = (conceptTotals[label] ?? 0.0) + tx.amount;
        totalExpenseSum += tx.amount;
      }
    }
    final topConcepts = conceptTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final displayedConcepts = topConcepts.take(3).toList();

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                _isCreditTab ? 'Distribución de Deuda por Cuenta' : 'Distribución de tu Dinero',
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: AppColors.kNeutral900,
              ),
              AppText(
                _isCreditTab
                    ? 'Proporción de deuda en cada tarjeta o préstamo'
                    : 'Cómo está repartido tu saldo entre tus cuentas',
                fontSize: 11.5,
                color: AppColors.kNeutral500,
              ),
              const Gap(14),
              if (positiveAccounts.isEmpty || totalAccountValue <= 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: AppText(
                      _isCreditTab ? 'Sin deuda activa en tus cuentas' : 'Sin saldo positivo para graficar',
                      fontSize: 12,
                      color: AppColors.kNeutral500,
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    SizedBox(
                      width: 118,
                      height: 118,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                touchCallback: (event, response) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        response == null ||
                                        response.touchedSection == null) {
                                      _touchedAccountSlice = -1;
                                      return;
                                    }
                                    _touchedAccountSlice = response.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              sectionsSpace: 2,
                              centerSpaceRadius: 34,
                              sections: List.generate(positiveAccounts.length, (i) {
                                final acc = positiveAccounts[i];
                                final val = _isCreditTab ? acc.effectiveDebt : acc.balance;
                                final pct = (val / totalAccountValue) * 100;
                                final isTouched = i == _touchedAccountSlice;
                                return PieChartSectionData(
                                  color: palette[i % palette.length],
                                  value: val,
                                  title: pct >= 12 ? '${pct.toStringAsFixed(0)}%' : '',
                                  radius: isTouched ? 26 : 22,
                                  titleStyle: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppText(
                                _isCreditTab ? 'Deuda' : 'Total',
                                fontSize: 9.5,
                                color: AppColors.kNeutral500,
                              ),
                              AppText(
                                NumberFormat.compactCurrency(locale: 'es_MX', symbol: '\$').format(totalAccountValue),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.kNeutral900,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Gap(14),
                    Expanded(
                      child: Column(
                        children: List.generate(positiveAccounts.length, (i) {
                          final acc = positiveAccounts[i];
                          final val = _isCreditTab ? acc.effectiveDebt : acc.balance;
                          final pct = (val / totalAccountValue) * 100;
                          final color = palette[i % palette.length];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3.5),
                            child: Row(
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                                ),
                                const Gap(7),
                                Expanded(
                                  child: AppText(
                                    acc.name,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.kNeutral800,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const Gap(6),
                                AppText(
                                  '${pct.toStringAsFixed(0)}%',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.kNeutral600,
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (displayedConcepts.isNotEmpty && totalExpenseSum > 0) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: AppColors.kNeutral200),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  _isCreditTab ? 'Principales Cargos Recientes' : '¿En qué se va tu dinero? (Top Gastos)',
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kNeutral800,
                ),
                const Gap(8),
                ...displayedConcepts.map((entry) {
                  final ratio = (entry.value / totalExpenseSum).clamp(0.0, 1.0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: AppText(
                                entry.key,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.kNeutral700,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Gap(8),
                            AppText(
                              '${_currencyFormat.format(entry.value)} (${(ratio * 100).toStringAsFixed(0)}%)',
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.kNeutral900,
                            ),
                          ],
                        ),
                        const Gap(3),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 5,
                            backgroundColor: AppColors.kNeutral100,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.kWarning),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniChartModeBtn({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? AppColors.kPrimaryColor : AppColors.kNeutral500),
            const Gap(4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? AppColors.kPrimaryColor : AppColors.kNeutral600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const Gap(5),
        AppText(label, fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.kNeutral700),
      ],
    );
  }

  Widget _buildQuickInsightPill({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.kNeutral50,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.kNeutral200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const Gap(6),
          AppText('$label: ', fontSize: 11, color: AppColors.kNeutral600),
          AppText(value, fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.kNeutral900),
        ],
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
