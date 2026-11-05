import 'package:admivida/business/features/reports/models/business_report_model.dart';
import 'package:admivida/business/features/reports/reports_provider.dart';
import 'package:admivida/business/models/business_model.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/dashboard_navigation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class BusinessReportsScreen extends ConsumerStatefulWidget {
  final BusinessModel business;

  const BusinessReportsScreen({super.key, required this.business});

  @override
  ConsumerState<BusinessReportsScreen> createState() => _BusinessReportsScreenState();
}

class _BusinessReportsScreenState extends ConsumerState<BusinessReportsScreen> {
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);

  String _formatDateStr(String raw) {
    if (raw.isEmpty) return '';
    try {
      final parsed = DateTime.parse(raw);
      return DateFormat('dd/MM/yyyy').format(parsed);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(businessReportProvider(widget.business.id));
    final filterState = ref.watch(reportFilterProvider(widget.business.id));

    return AppScaffold(
      title: 'Reportes y Analíticas',
      appBar: AppBar(
        title: const AppText('Reportes y Analíticas', color: AppColors.kNeutral100),
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: AppColors.kPrimaryColor,
        actions: [
          IconButton(
            tooltip: 'Actualizar reporte',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(businessReportProvider(widget.business.id)),
          ),
        ],
      ),
      mobile: _buildContent(reportAsync, filterState, isDesktop: false),
      tablet: _buildContent(reportAsync, filterState, isDesktop: true),
      desktop: _buildContent(reportAsync, filterState, isDesktop: true),
    );
  }

  Widget _buildContent(
    AsyncValue<BusinessReportModel> reportAsync,
    ReportFilterState filterState, {
    required bool isDesktop,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(businessReportProvider(widget.business.id));
        await ref.read(businessReportProvider(widget.business.id).future);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(isDesktop ? 24 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPeriodFilterBar(filterState),
            const Gap(14),
            reportAsync.when(
              data: (report) => _buildReportView(report, isDesktop),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.kError, size: 48),
                      const Gap(12),
                      AppText('No se pudo cargar el reporte: $err', color: AppColors.kNeutral700),
                      const Gap(12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
                        onPressed: () => ref.refresh(businessReportProvider(widget.business.id)),
                        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                        label: const Text('Reintentar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Barra de Filtros de Fecha (Mismo estilo que el resto de la app)
  // ===========================================================================
  Widget _buildPeriodFilterBar(ReportFilterState filterState) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.kNeutral200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ReportPeriodFilter.values.map((period) {
            final isSelected = filterState.filter == period;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InkWell(
                onTap: () async {
                  if (period == ReportPeriodFilter.custom) {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2023),
                      lastDate: DateTime.now(),
                      initialDateRange: filterState.customRange ??
                          DateTimeRange(
                            start: DateTime.now().subtract(const Duration(days: 30)),
                            end: DateTime.now(),
                          ),
                    );
                    if (picked != null) {
                      ref.read(reportFilterProvider(widget.business.id).notifier).setCustomRange(picked);
                    }
                  } else {
                    ref.read(reportFilterProvider(widget.business.id).notifier).setFilter(period);
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.kPrimaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (period == ReportPeriodFilter.custom) ...[
                        Icon(
                          Icons.date_range_rounded,
                          size: 16,
                          color: isSelected ? Colors.white : AppColors.kNeutral700,
                        ),
                        const Gap(6),
                      ],
                      AppText(
                        period == ReportPeriodFilter.custom && filterState.customRange != null
                            ? '${DateFormat('dd/MM/yy').format(filterState.customRange!.start)} - ${DateFormat('dd/MM/yy').format(filterState.customRange!.end)}'
                            : period.label,
                        color: isSelected ? Colors.white : AppColors.kNeutral700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ===========================================================================
  // Vista Completa del Reporte
  // ===========================================================================
  Widget _buildReportView(BusinessReportModel report, bool isDesktop) {
    final startFormatted = _formatDateStr(report.startDate);
    final endFormatted = _formatDateStr(report.endDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Ventas y Ganancias del Periodo
        _buildSalesProfitSection(
          report.salesSummary,
          report.cashFlow,
          startFormatted == endFormatted ? 'Hoy ($startFormatted)' : '$startFormatted al $endFormatted',
          isDesktop,
        ),
        const Gap(20),

        // 2. Saldos en Cajas/Cuentas, Flujo de Dinero y Por Cobrar
        _buildMoneyAndAccountsSection(report.cashFlow, report.accountsBreakdown, isDesktop),
        const Gap(20),

        // 3. Valor del Inventario Actual
        _buildInventoryValuationCard(report.inventoryValuation, isDesktop),
        const Gap(20),

        // 4. Gráfica Diaria y Métodos de Pago
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _buildTimelineChartCard(report.timeline)),
              const Gap(14),
              Expanded(flex: 4, child: _buildPaymentMethodsCard(report.paymentMethods)),
            ],
          )
        else ...[
          _buildTimelineChartCard(report.timeline),
          const Gap(16),
          _buildPaymentMethodsCard(report.paymentMethods),
        ],
        const Gap(20),

        // 5. Top 10 Productos y Rendimiento de Vendedores
        if (isDesktop && report.topProducts.isNotEmpty && report.topSellers.isNotEmpty)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 6, child: _buildTopProductsCard(report.topProducts)),
              const Gap(14),
              Expanded(flex: 4, child: _buildTopSellersCard(report.topSellers)),
            ],
          )
        else ...[
          if (report.topProducts.isNotEmpty) ...[
            _buildTopProductsCard(report.topProducts),
            const Gap(16),
          ],
          if (report.topSellers.isNotEmpty) ...[
            _buildTopSellersCard(report.topSellers),
            const Gap(20),
          ],
        ],
      ],
    );
  }

  // ===========================================================================
  // 1. Resumen de Ventas y Ganancias
  // ===========================================================================
  Widget _buildSalesProfitSection(
    SalesSummaryReport sales,
    CashFlowReport cashFlow,
    String periodLabel,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: AppText(
                'Resumen de Ventas y Ganancias',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.kNeutral900,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: AppText(
                periodLabel,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.kPrimaryColor,
              ),
            ),
          ],
        ),
        const Gap(12),
        GridView.count(
          crossAxisCount: isDesktop ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isDesktop ? 1.55 : 1.22,
          children: [
            _buildKpiCard(
              title: 'Total Vendido',
              value: _currencyFormat.format(sales.totalSales),
              subtitle: '${sales.salesCount} ventas • Prom: ${_currencyFormat.format(sales.averageTicket)}',
              icon: Icons.point_of_sale_rounded,
              color: AppColors.kPrimaryColor,
            ),
            _buildKpiCard(
              title: 'Costo de Mercancía',
              value: _currencyFormat.format(sales.totalCost),
              subtitle: '${sales.totalItemsSold.toStringAsFixed(0)} piezas vendidas',
              icon: Icons.inventory_2_rounded,
              color: AppColors.kWarning,
            ),
            _buildKpiCard(
              title: 'Ganancia de Ventas',
              value: _currencyFormat.format(sales.grossProfit),
              subtitle: '${sales.profitMarginPercentage.toStringAsFixed(1)}% de margen libre',
              icon: Icons.trending_up_rounded,
              color: AppColors.kSuccess,
              isHighlight: true,
            ),
            _buildKpiCard(
              title: 'Balance Neto en Caja',
              value: '${cashFlow.netCashFlow >= 0 ? '+' : ''}${_currencyFormat.format(cashFlow.netCashFlow)}',
              subtitle: 'Ingresos cobrados menos gastos',
              icon: Icons.account_balance_wallet_rounded,
              color: cashFlow.netCashFlow >= 0 ? AppColors.kSecondaryColor : AppColors.kError,
            ),
          ],
        ),
        const Gap(12),

        // Tarjeta concisa de desglose de ventas
        AppCard(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  _buildCompactPillStat(
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.kSuccess,
                    label: 'Ventas de Contado (${sales.completedSalesCount})',
                    value: _currencyFormat.format(sales.completedSalesTotal),
                  ),
                  _buildCompactPillStat(
                    icon: Icons.schedule_rounded,
                    color: AppColors.kWarning,
                    label: 'Ventas a Crédito / Apartado (${sales.creditLayawaySalesCount})',
                    value: _currencyFormat.format(sales.creditLayawaySalesTotal),
                  ),
                  if (sales.totalDiscounts > 0)
                    _buildCompactPillStat(
                      icon: Icons.local_offer_outlined,
                      color: AppColors.kError,
                      label: 'Descuentos Otorgados',
                      value: '-${_currencyFormat.format(sales.totalDiscounts)}',
                    ),
                  if (sales.totalCommissions > 0)
                    _buildCompactPillStat(
                      icon: Icons.badge_outlined,
                      color: const Color(0xFF6366F1),
                      label: 'Comisiones (Libre: ${_currencyFormat.format(sales.netProfitAfterCommissions)})',
                      value: _currencyFormat.format(sales.totalCommissions),
                    ),
                ],
              ),
              if (sales.itemsWithoutCostCount > 0) ...[
                const Gap(12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.kWarning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 17, color: AppColors.kWarning),
                      const Gap(8),
                      Expanded(
                        child: AppText(
                          '${sales.itemsWithoutCostCount} productos vendidos no tenían costo de compra registrado (se calculó como \$0.00).',
                          fontSize: 11.5,
                          color: AppColors.kNeutral800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactPillStat({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.kNeutral50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.kNeutral200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const Gap(8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(label, fontSize: 11, color: AppColors.kNeutral600),
              AppText(value, fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.kNeutral900),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isHighlight = false,
  }) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AppText(
                  title,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kNeutral600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AppText(
              value,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isHighlight ? color : AppColors.kNeutral900,
            ),
          ),
          AppText(
            subtitle,
            fontSize: 11,
            color: AppColors.kNeutral500,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. Cajas, Cuentas y Flujo de Dinero
  // ===========================================================================
  Widget _buildMoneyAndAccountsSection(
    CashFlowReport cashFlow,
    List<AccountBalanceReportItem> accounts,
    bool isDesktop,
  ) {
    if (isDesktop) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 5, child: _buildAccountsBalanceCard(cashFlow, accounts)),
            const Gap(14),
            Expanded(flex: 5, child: _buildReceivablesAndCashFlowCard(cashFlow)),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildAccountsBalanceCard(cashFlow, accounts),
        const Gap(14),
        _buildReceivablesAndCashFlowCard(cashFlow),
      ],
    );
  }

  Widget _buildAccountsBalanceCard(CashFlowReport cashFlow, List<AccountBalanceReportItem> accounts) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
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
                    AppText('Dinero Disponible Hoy en Cajas', fontSize: 15, fontWeight: FontWeight.bold),
                    AppText('Saldo actual por cuenta y movimientos del periodo', fontSize: 11.5, color: AppColors.kNeutral600),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.kSuccess.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppText(
                  _currencyFormat.format(cashFlow.totalAvailableInAccounts),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.kSuccess,
                ),
              ),
            ],
          ),
          const Gap(14),
          if (accounts.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: AppText('No hay cajas o cuentas activas.', fontSize: 12, color: AppColors.kNeutral600),
            )
          else
            ...accounts.map((acc) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.kNeutral50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.kNeutral200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        acc.typeCode == 'CASH' ? Icons.point_of_sale_rounded : Icons.account_balance_rounded,
                        size: 18,
                        color: AppColors.kPrimaryColor,
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            acc.isDefault ? '${acc.name} ★' : acc.name,
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.kNeutral900,
                          ),
                          AppText(
                            'Periodo: +${_currencyFormat.format(acc.periodIncome)}  |  -${_currencyFormat.format(acc.periodExpense)}',
                            fontSize: 11,
                            color: AppColors.kNeutral600,
                          ),
                        ],
                      ),
                    ),
                    AppText(
                      _currencyFormat.format(acc.currentBalance),
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: acc.currentBalance >= 0 ? AppColors.kPrimaryColor : AppColors.kError,
                    ),
                  ],
                ),
              );
            }),
          const Gap(6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => DashboardSession.navigateToBusinessRoute(
                  context,
                  Routes.cashShifts,
                  widget.business,
                ),
                icon: const Icon(Icons.lock_clock_rounded, size: 16, color: AppColors.kSecondaryColor),
                label: const AppText(
                  'Cortes de Caja',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kSecondaryColor,
                ),
              ),
              const Gap(8),
              TextButton.icon(
                onPressed: () => DashboardSession.navigateToBusinessRoute(
                  context,
                  Routes.transactions,
                  widget.business,
                ),
                icon: const Icon(Icons.swap_vert_rounded, size: 16, color: AppColors.kPrimaryColor),
                label: const AppText(
                  'Ver Movimientos',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kPrimaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReceivablesAndCashFlowCard(CashFlowReport cashFlow) {
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
              const AppText('Flujo de Dinero y Cuentas por Cobrar', fontSize: 15, fontWeight: FontWeight.bold),
              const AppText('Entradas y salidas reales en el periodo seleccionado', fontSize: 11.5, color: AppColors.kNeutral600),
              const Gap(14),
              _buildFlowRow(
                '(+) Cobros por ventas y abonos:',
                _currencyFormat.format(cashFlow.salesIncome),
                AppColors.kSuccess,
              ),
              if (cashFlow.manualIncome > 0) ...[
                const Gap(6),
                _buildFlowRow(
                  '(+) Entradas manuales en caja:',
                  _currencyFormat.format(cashFlow.manualIncome),
                  AppColors.kSuccess,
                ),
              ],
              const Gap(6),
              _buildFlowRow(
                '(-) Gastos, pagos y retiros:',
                '-${_currencyFormat.format(cashFlow.totalExpenses)}',
                AppColors.kWarning,
              ),
              const Divider(height: 18),
              _buildFlowRow(
                'Balance Neto del Periodo:',
                '${cashFlow.netCashFlow >= 0 ? '+' : ''}${_currencyFormat.format(cashFlow.netCashFlow)}',
                cashFlow.netCashFlow >= 0 ? AppColors.kSuccess : AppColors.kError,
                isBold: true,
              ),
            ],
          ),
          const Gap(14),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => DashboardSession.navigateToBusinessRoute(
              context,
              Routes.clients,
              widget.business,
            ),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.kWarning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.kWarning.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.kWarning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.people_alt_rounded, size: 18, color: AppColors.kWarning),
                  ),
                  const Gap(10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          'Por Cobrar a Clientes (Fiados / Apartados)',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kNeutral900,
                        ),
                        AppText(
                          'Toca para ver clientes con saldo pendiente',
                          fontSize: 11,
                          color: AppColors.kNeutral600,
                        ),
                      ],
                    ),
                  ),
                  const Gap(8),
                  AppText(
                    _currencyFormat.format(cashFlow.pendingReceivablesDebt),
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kWarning,
                  ),
                  const Gap(4),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.kNeutral500),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: AppText(
            label,
            fontSize: 12.5,
            color: AppColors.kNeutral700,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const Gap(8),
        AppText(value, fontSize: isBold ? 14 : 12.5, color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.w600),
      ],
    );
  }

  // ===========================================================================
  // 3. Valor de tu Inventario Actual (Mismo gradiente institucional que BusinessDetailScreen)
  // ===========================================================================
  Widget _buildInventoryValuationCard(InventoryValuationReport inv, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 22 : 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF163542),
            AppColors.kPrimaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.kPrimaryColor.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: AppColors.kPrimary100, size: 22),
              ),
              const Gap(12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      'Valor de tu Mercancía en Existencia',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    AppText(
                      'Dinero invertido y ganancia estimada de tu inventario actual',
                      color: Color(0xD9FFFFFF),
                      fontSize: 12,
                    ),
                  ],
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => DashboardSession.navigateToBusinessRoute(
                  context,
                  Routes.products,
                  widget.business,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        '${inv.totalActiveProducts} prod. • ${inv.totalStockPieces.toStringAsFixed(0)} pzas',
                        color: AppColors.kPrimary100,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      const Gap(4),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.kPrimary100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Gap(16),
          const Divider(color: Colors.white12, height: 1),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: _buildInventoryMetricColumn(
                  label: 'Costo Invertido',
                  sublabel: 'Lo que pagaste por el stock',
                  value: _currencyFormat.format(inv.totalCostValue),
                  valueColor: Colors.white,
                ),
              ),
              Container(height: 40, width: 1, color: Colors.white12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildInventoryMetricColumn(
                    label: 'Valor a Precio Venta',
                    sublabel: 'Al vender toda la existencia',
                    value: _currencyFormat.format(inv.totalSaleValue),
                    valueColor: AppColors.kPrimary100,
                  ),
                ),
              ),
              Container(height: 40, width: 1, color: Colors.white12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildInventoryMetricColumn(
                    label: 'Ganancia Estimada',
                    sublabel: '${inv.expectedMarginPercentage.toStringAsFixed(1)}% de margen',
                    value: _currencyFormat.format(inv.expectedProfit),
                    valueColor: const Color(0xFF4ADE80),
                  ),
                ),
              ),
            ],
          ),
          if (inv.lowStockVariantsCount > 0 || inv.outOfStockVariantsCount > 0 || inv.variantsWithoutCostCount > 0) ...[
            const Gap(14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (inv.outOfStockVariantsCount > 0)
                  _buildInventoryBadge(
                    icon: Icons.production_quantity_limits_rounded,
                    color: const Color(0xFFFF8A80),
                    text: '${inv.outOfStockVariantsCount} agotados',
                  ),
                if (inv.lowStockVariantsCount > 0)
                  _buildInventoryBadge(
                    icon: Icons.warning_amber_rounded,
                    color: Colors.amber,
                    text: '${inv.lowStockVariantsCount} con stock bajo',
                  ),
                if (inv.variantsWithoutCostCount > 0)
                  _buildInventoryBadge(
                    icon: Icons.info_outline_rounded,
                    color: AppColors.kPrimary100,
                    text: '${inv.variantsWithoutCostCount} sin costo registrado',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInventoryBadge({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const Gap(6),
          Flexible(
            child: AppText(text, color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryMetricColumn({
    required String label,
    required String sublabel,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, color: const Color(0xD9FFFFFF), fontSize: 11.5, fontWeight: FontWeight.w600),
        const Gap(4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: AppText(value, color: valueColor, fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const Gap(2),
        AppText(sublabel, color: Colors.white70, fontSize: 10),
      ],
    );
  }

  // ===========================================================================
  // 4. Gráfica Diaria (Ventas vs Ganancia por Día)
  // ===========================================================================
  Widget _buildTimelineChartCard(List<TimelineReportItem> timeline) {
    if (timeline.isEmpty) {
      return AppCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(color: AppColors.kPrimary50, shape: BoxShape.circle),
                child: const Icon(Icons.bar_chart_rounded, size: 32, color: AppColors.kPrimaryColor),
              ),
              const Gap(10),
              const AppText(
                'Sin ventas registradas en este periodo',
                color: AppColors.kNeutral600,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      );
    }

    final maxVal = timeline.fold<double>(
      0.0,
      (max, item) => item.sales > max ? item.sales : max,
    );
    final double maxY = maxVal == 0 ? 100 : (maxVal * 1.25);

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
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
                    AppText('Evolución Diaria', fontSize: 15, fontWeight: FontWeight.bold),
                    AppText(
                      'Toca cualquier barra para ver el detalle del día',
                      color: AppColors.kNeutral600,
                      fontSize: 11.5,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildLegendItem('Vendido', AppColors.kPrimaryColor),
                  const Gap(12),
                  _buildLegendItem('Ganancia', AppColors.kSuccess),
                ],
              ),
            ],
          ),
          const Gap(22),
          SizedBox(
            height: 210,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = timeline[groupIndex];
                      return BarTooltipItem(
                        '${_formatDateStr(item.date)} (${item.count} ventas)\n',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                        children: [
                          TextSpan(
                            text: 'Vendido: ${_currencyFormat.format(item.sales)}\n',
                            style: const TextStyle(
                              color: AppColors.kPrimary100,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                          TextSpan(
                            text: 'Costo: ${_currencyFormat.format(item.cost)}\n',
                            style: const TextStyle(
                              color: Color(0xFFFDE68A),
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                          TextSpan(
                            text: 'Ganancia: ${_currencyFormat.format(item.profit)}',
                            style: const TextStyle(
                              color: Color(0xFF4ADE80),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) {
                        if (value == 0 || value == maxY) return const SizedBox.shrink();
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
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < timeline.length) {
                          final rawDate = timeline[idx].date;
                          final parts = rawDate.split('-');
                          final label = parts.length >= 3 ? '${parts[2]}/${parts[1]}' : rawDate;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 9, color: AppColors.kNeutral600),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => const FlLine(color: AppColors.kNeutral200, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(timeline.length, (index) {
                  final item = timeline[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: item.sales,
                        color: AppColors.kPrimaryColor,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                      BarChartRodData(
                        toY: item.profit > 0 ? item.profit : 0,
                        color: AppColors.kSuccess,
                        width: 8,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const Gap(4),
        AppText(label, fontSize: 11, color: AppColors.kNeutral700, fontWeight: FontWeight.w600),
      ],
    );
  }

  // ===========================================================================
  // 5. Métodos de Pago
  // ===========================================================================
  Widget _buildPaymentMethodsCard(List<PaymentMethodReportItem> methods) {
    final activeMethods = methods.where((m) => m.total > 0).toList();
    if (activeMethods.isEmpty) {
      return AppCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(color: AppColors.kPrimary50, shape: BoxShape.circle),
                child: const Icon(Icons.pie_chart_outline_rounded, size: 32, color: AppColors.kPrimaryColor),
              ),
              const Gap(10),
              const AppText('Sin cobros registrados en este periodo', color: AppColors.kNeutral600, fontWeight: FontWeight.w600),
            ],
          ),
        ),
      );
    }

    final colors = [
      AppColors.kPrimaryColor,
      AppColors.kSuccess,
      AppColors.kSecondaryColor,
      AppColors.kWarning,
      const Color(0xFF6366F1),
    ];

    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('Cobros por Método de Pago', fontSize: 15, fontWeight: FontWeight.bold),
          const AppText('Cómo pagaron tus clientes en el periodo', fontSize: 11.5, color: AppColors.kNeutral600),
          const Gap(16),
          SizedBox(
            height: 145,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 32,
                sections: List.generate(activeMethods.length, (i) {
                  final m = activeMethods[i];
                  final color = colors[i % colors.length];
                  return PieChartSectionData(
                    color: color,
                    value: m.total,
                    title: '${m.percentage.toStringAsFixed(0)}%',
                    radius: 34,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }),
              ),
            ),
          ),
          const Gap(12),
          ...List.generate(activeMethods.length, (i) {
            final m = activeMethods[i];
            final color = colors[i % colors.length];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const Gap(8),
                  Expanded(
                    child: AppText(
                      '${m.name} (${m.count})',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kNeutral800,
                    ),
                  ),
                  AppText(
                    '${_currencyFormat.format(m.total)} (${m.percentage.toStringAsFixed(0)}%)',
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.kNeutral900,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ===========================================================================
  // 6. Top 10 Productos Más Vendidos
  // ===========================================================================
  Widget _buildTopProductsCard(List<TopProductReportItem> products) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('Productos Más Vendidos', fontSize: 15, fontWeight: FontWeight.bold),
          const AppText('Unidades vendidas, ingreso y ganancia generada', fontSize: 11.5, color: AppColors.kNeutral600),
          const Gap(12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.kNeutral200),
            itemBuilder: (context, index) {
              final p = products[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: index < 3 ? AppColors.kPrimaryColor.withValues(alpha: 0.12) : AppColors.kNeutral100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AppText(
                        '#${index + 1}',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: index < 3 ? AppColors.kPrimaryColor : AppColors.kNeutral700,
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(p.name, fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.kNeutral900, maxLines: 1),
                          AppText(
                            '${p.unitsSold.toStringAsFixed(0)} pzas • Costo: ${_currencyFormat.format(p.totalCost)}',
                            fontSize: 11.5,
                            color: AppColors.kNeutral600,
                          ),
                        ],
                      ),
                    ),
                    const Gap(8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppText(_currencyFormat.format(p.totalRevenue), fontSize: 13.5, fontWeight: FontWeight.bold),
                        AppText(
                          '+${_currencyFormat.format(p.totalProfit)} ganancia',
                          fontSize: 11,
                          color: AppColors.kSuccess,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 7. Rendimiento por Vendedor
  // ===========================================================================
  Widget _buildTopSellersCard(List<TopSellerReportItem> sellers) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('Ventas por Colaborador', fontSize: 15, fontWeight: FontWeight.bold),
          const AppText('Ventas, ganancia y comisión generada en el periodo', fontSize: 11.5, color: AppColors.kNeutral600),
          const Gap(12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sellers.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.kNeutral200),
            itemBuilder: (context, index) {
              final s = sellers[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_rounded, size: 18, color: AppColors.kPrimaryColor),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(s.name, fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.kNeutral900),
                          AppText(
                            '${s.salesCount} ventas${s.totalCommission > 0 ? ' • Com: ${_currencyFormat.format(s.totalCommission)}' : ''}',
                            fontSize: 11.5,
                            color: AppColors.kNeutral600,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AppText(
                          _currencyFormat.format(s.totalRevenue),
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kNeutral900,
                        ),
                        AppText(
                          '+${_currencyFormat.format(s.totalProfit)} ganancia',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.kSuccess,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
