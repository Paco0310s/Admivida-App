import 'package:admivida/business/features/reports/models/business_report_model.dart';
import 'package:admivida/business/features/reports/reports_provider.dart';
import 'package:admivida/business/models/business_model.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
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
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(businessReportProvider(widget.business.id));
    final filterState = ref.watch(reportFilterProvider(widget.business.id));

    return AppScaffold(
      title: 'Reportes y Analíticas',
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText('Reportes y Analíticas', color: AppColors.kNeutral100, fontSize: 18, fontWeight: FontWeight.bold),
            AppText(widget.business.name, color: AppColors.kNeutral300, fontSize: 12),
          ],
        ),
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
        actions: [
          IconButton(
            tooltip: 'Actualizar reporte',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.kNeutral100),
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
            // 1. Selector de periodo
            _buildPeriodFilterBar(filterState),
            const Gap(16),

            // 2. Contenido del reporte
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
                      Icon(Icons.error_outline_rounded, color: AppColors.kError, size: 48),
                      const Gap(12),
                      AppText('Error al cargar reporte: $err', color: AppColors.kNeutral700),
                      const Gap(12),
                      ElevatedButton.icon(
                        onPressed: () => ref.refresh(businessReportProvider(widget.business.id)),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reintentar'),
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
  // Barra de Filtros
  // ===========================================================================
  Widget _buildPeriodFilterBar(ReportFilterState filterState) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.kNeutral100,
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                            ? '${DateFormat('dd/MM').format(filterState.customRange!.start)} - ${DateFormat('dd/MM').format(filterState.customRange!.end)}'
                            : period.label,
                        color: isSelected ? Colors.white : AppColors.kNeutral700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarjetas de Ventas y Ganancias Realizadas
        _buildSalesProfitSection(report.salesSummary, report.cashFlow, isDesktop),
        const Gap(20),

        // Tarjeta Destacada de Inventario y Ganancia Proyectada
        _buildInventoryValuationCard(report.inventoryValuation, isDesktop),
        const Gap(20),

        // Gráfica de Evolución Diaria (fl_chart)
        _buildTimelineChartCard(report.timeline),
        const Gap(20),

        // Métodos de Pago y Cuentas por Cobrar
        if (isDesktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 5, child: _buildPaymentMethodsCard(report.paymentMethods)),
              const Gap(16),
              Expanded(flex: 5, child: _buildReceivablesAndCashFlowCard(report.cashFlow)),
            ],
          )
        else ...[
          _buildPaymentMethodsCard(report.paymentMethods),
          const Gap(20),
          _buildReceivablesAndCashFlowCard(report.cashFlow),
        ],
        const Gap(20),

        // Top 10 Productos Más Vendidos y Rentables
        _buildTopProductsCard(report.topProducts),
        const Gap(20),

        // Top Vendedores
        if (report.topSellers.isNotEmpty) ...[
          _buildTopSellersCard(report.topSellers),
          const Gap(20),
        ],
      ],
    );
  }

  // ===========================================================================
  // 1. Sección de Ventas y Ganancias Realizadas
  // ===========================================================================
  Widget _buildSalesProfitSection(SalesSummaryReport sales, CashFlowReport cashFlow, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.point_of_sale_rounded, color: AppColors.kPrimaryColor, size: 20),
            Gap(8),
            AppText('Rentabilidad de Ventas Realizadas', fontSize: 16, fontWeight: FontWeight.bold),
          ],
        ),
        const Gap(12),
        GridView.count(
          crossAxisCount: isDesktop ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: isDesktop ? 1.6 : 1.3,
          children: [
            // Tarjeta 1: Ventas Totales
            _buildKpiCard(
              title: 'Ventas Totales',
              value: _currencyFormat.format(sales.totalSales),
              subtitle: '${sales.salesCount} tickets • Prom: ${_currencyFormat.format(sales.averageTicket)}',
              icon: Icons.attach_money_rounded,
              color: AppColors.kPrimaryColor,
              backgroundColor: const Color(0xFFEFF6FF),
            ),

            // Tarjeta 2: Ganancia Realizada (Utilidad)
            _buildKpiCard(
              title: 'Ganancia Neta Real',
              value: _currencyFormat.format(sales.grossProfit),
              subtitle: '${sales.profitMarginPercentage.toStringAsFixed(1)}% margen sobre ventas',
              icon: Icons.trending_up_rounded,
              color: AppColors.kSuccess,
              backgroundColor: const Color(0xFFF0FDF4),
              isHighlight: true,
            ),

            // Tarjeta 3: Costo de lo Vendido
            _buildKpiCard(
              title: 'Costo de lo Vendido',
              value: _currencyFormat.format(sales.totalCost),
              subtitle: '${sales.totalItemsSold.toStringAsFixed(0)} pzas vendidas',
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFFD97706),
              backgroundColor: const Color(0xFFFFFBEB),
            ),

            // Tarjeta 4: Flujo Neto de Caja
            _buildKpiCard(
              title: 'Flujo Neto de Caja',
              value: '${cashFlow.netCashFlow >= 0 ? '+' : ''}${_currencyFormat.format(cashFlow.netCashFlow)}',
              subtitle: 'Ingresos - Egresos operativos',
              icon: Icons.account_balance_wallet_rounded,
              color: cashFlow.netCashFlow >= 0 ? AppColors.kSuccess : AppColors.kError,
              backgroundColor: const Color(0xFFF8FAFC),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight ? color.withValues(alpha: 0.5) : color.withValues(alpha: 0.2),
          width: isHighlight ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AppText(title, fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.kNeutral700),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AppText(
              value,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          AppText(
            subtitle,
            fontSize: 10,
            color: AppColors.kNeutral600,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. Tarjeta Destacada de Inventario y Ganancia Proyectada
  // ===========================================================================
  Widget _buildInventoryValuationCard(InventoryValuationReport inv, bool isDesktop) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 22 : 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warehouse_rounded, color: Colors.amber, size: 22),
              ),
              const Gap(10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText('Mercancía Actual y Ganancia Esperada', color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    AppText('Valorización del stock actualmente en tienda', color: AppColors.kNeutral400, fontSize: 12),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: AppText(
                  '${inv.totalStockPieces.toStringAsFixed(0)} piezas',
                  color: Colors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(18),
          const Divider(color: Colors.white12, height: 1),
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: _buildInventoryMetricColumn(
                  label: 'Inversión en Mercancía',
                  sublabel: 'Costo total en estantes',
                  value: _currencyFormat.format(inv.totalCostValue),
                  valueColor: Colors.white,
                ),
              ),
              Container(height: 40, width: 1, color: Colors.white12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildInventoryMetricColumn(
                    label: 'Valor de Venta en Tienda',
                    sublabel: 'Total proyectado al cobrar',
                    value: _currencyFormat.format(inv.totalSaleValue),
                    valueColor: const Color(0xFF60A5FA),
                  ),
                ),
              ),
              Container(height: 40, width: 1, color: Colors.white12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _buildInventoryMetricColumn(
                    label: 'Ganancia Proyectada',
                    sublabel: '${inv.expectedMarginPercentage.toStringAsFixed(1)}% margen esperado',
                    value: _currencyFormat.format(inv.expectedProfit),
                    valueColor: const Color(0xFF4ADE80),
                  ),
                ),
              ),
            ],
          ),
          if (inv.lowStockVariantsCount > 0) ...[
            const Gap(14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                  const Gap(8),
                  AppText(
                    '${inv.lowStockVariantsCount} productos están por debajo de su stock mínimo recomendado.',
                    color: Colors.redAccent,
                    fontSize: 11,
                  ),
                ],
              ),
            ),
          ],
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
        AppText(label, color: AppColors.kNeutral300, fontSize: 11, fontWeight: FontWeight.w500),
        const Gap(4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: AppText(value, color: valueColor, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Gap(2),
        AppText(sublabel, color: AppColors.kNeutral400, fontSize: 10),
      ],
    );
  }

  // ===========================================================================
  // 3. Gráfica de Barras Diaria (Ventas vs Ganancia)
  // ===========================================================================
  Widget _buildTimelineChartCard(List<TimelineReportItem> timeline) {
    if (timeline.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.bar_chart_rounded, size: 40, color: AppColors.kNeutral400),
                const Gap(8),
                AppText('No hay ventas registradas en este periodo para graficar', color: AppColors.kNeutral600),
              ],
            ),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText('Evolución de Ventas vs Ganancia Neta', fontSize: 15, fontWeight: FontWeight.bold),
                    AppText('Comportamiento diario del periodo', color: AppColors.kNeutral600, fontSize: 11),
                  ],
                ),
                Row(
                  children: [
                    _buildLegendItem('Ventas', AppColors.kPrimaryColor),
                    const Gap(12),
                    _buildLegendItem('Ganancia', AppColors.kSuccess),
                  ],
                ),
              ],
            ),
            const Gap(24),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final item = timeline[groupIndex];
                        final isSales = rodIndex == 0;
                        return BarTooltipItem(
                          '${item.date}\n',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          children: [
                            TextSpan(
                              text: isSales
                                  ? 'Venta: ${_currencyFormat.format(item.sales)}'
                                  : 'Ganancia: ${_currencyFormat.format(item.profit)}',
                              style: TextStyle(
                                color: isSales ? const Color(0xFF60A5FA) : const Color(0xFF4ADE80),
                                fontWeight: FontWeight.w600,
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
                        reservedSize: 42,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == maxY) return const SizedBox.shrink();
                          return Text(
                            NumberFormat.compact().format(value),
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
                            // Mostrar solo dia ej: "15" o "15/10"
                            final parts = rawDate.split('-');
                            final label = parts.length >= 3 ? parts[2] : rawDate;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                label,
                                style: const TextStyle(fontSize: 10, color: AppColors.kNeutral600),
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
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const Gap(4),
        AppText(label, fontSize: 11, color: AppColors.kNeutral700, fontWeight: FontWeight.w500),
      ],
    );
  }

  // ===========================================================================
  // 4. Métodos de Pago (PieChart Dona)
  // ===========================================================================
  Widget _buildPaymentMethodsCard(List<PaymentMethodReportItem> methods) {
    final activeMethods = methods.where((m) => m.total > 0).toList();
    if (activeMethods.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: AppText('Sin registros de cobros en este periodo', color: AppColors.kNeutral600),
          ),
        ),
      );
    }

    final colors = [
      AppColors.kPrimaryColor,
      AppColors.kSuccess,
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
    ];

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart_rounded, color: AppColors.kPrimaryColor, size: 20),
                Gap(8),
                AppText('Métodos de Pago Utilizados', fontSize: 15, fontWeight: FontWeight.bold),
              ],
            ),
            const Gap(16),
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: List.generate(activeMethods.length, (i) {
                          final m = activeMethods[i];
                          final color = colors[i % colors.length];
                          return PieChartSectionData(
                            color: color,
                            value: m.total,
                            title: '${m.percentage.toStringAsFixed(0)}%',
                            radius: 36,
                            titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                          );
                        }),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    flex: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(activeMethods.length, (i) {
                        final m = activeMethods[i];
                        final color = colors[i % colors.length];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const Gap(6),
                              Expanded(
                                child: AppText(m.name, fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.kNeutral800),
                              ),
                              AppText(_currencyFormat.format(m.total), fontSize: 11, fontWeight: FontWeight.bold),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 5. Cuentas por Cobrar y Flujo de Caja
  // ===========================================================================
  Widget _buildReceivablesAndCashFlowCard(CashFlowReport cashFlow) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_rounded, color: Color(0xFF0284C7), size: 20),
                Gap(8),
                AppText('Cuentas por Cobrar y Flujo', fontSize: 15, fontWeight: FontWeight.bold),
              ],
            ),
            const Gap(16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText('Deuda en la Calle (Clientes)', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      AppText('Fiados y apartados pendientes', fontSize: 10, color: Color(0xFFB45309)),
                    ],
                  ),
                  AppText(
                    _currencyFormat.format(cashFlow.pendingReceivablesDebt),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD97706),
                  ),
                ],
              ),
            ),
            const Gap(12),
            _buildFlowRow('Ingresos Totales en Cajas:', _currencyFormat.format(cashFlow.totalIncome), AppColors.kSuccess),
            const Gap(6),
            _buildFlowRow('Egresos y Pagos Operativos:', _currencyFormat.format(cashFlow.totalExpenses), AppColors.kError),
            const Divider(height: 16),
            _buildFlowRow(
              'Balance Neto del Periodo:',
              '${cashFlow.netCashFlow >= 0 ? '+' : ''}${_currencyFormat.format(cashFlow.netCashFlow)}',
              cashFlow.netCashFlow >= 0 ? AppColors.kSuccess : AppColors.kError,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(label, fontSize: 12, color: AppColors.kNeutral700, fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
        AppText(value, fontSize: 12, color: color, fontWeight: isBold ? FontWeight.bold : FontWeight.w600),
      ],
    );
  }

  // ===========================================================================
  // 6. Top 10 Productos Más Vendidos y Rentables
  // ===========================================================================
  Widget _buildTopProductsCard(List<TopProductReportItem> products) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                Gap(8),
                AppText('Top Productos Más Vendidos y Rentables', fontSize: 15, fontWeight: FontWeight.bold),
              ],
            ),
            const Gap(12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.kNeutral200),
              itemBuilder: (context, index) {
                final p = products[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: index < 3 ? Colors.amber.withValues(alpha: 0.2) : AppColors.kNeutral100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: index < 3 ? Colors.amber[900] : AppColors.kNeutral700,
                          ),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(p.name, fontSize: 13, fontWeight: FontWeight.w600, maxLines: 1),
                            AppText(
                              '${p.unitsSold.toStringAsFixed(0)} unidades vendidas',
                              fontSize: 11,
                              color: AppColors.kNeutral600,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AppText(_currencyFormat.format(p.totalRevenue), fontSize: 13, fontWeight: FontWeight.bold),
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
      ),
    );
  }

  // ===========================================================================
  // 7. Top Vendedores
  // ===========================================================================
  Widget _buildTopSellersCard(List<TopSellerReportItem> sellers) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.badge_rounded, color: Color(0xFF6366F1), size: 20),
                Gap(8),
                AppText('Rendimiento por Colaborador / Vendedor', fontSize: 15, fontWeight: FontWeight.bold),
              ],
            ),
            const Gap(12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sellers.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.kNeutral200),
              itemBuilder: (context, index) {
                final s = sellers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.kPrimaryColor.withValues(alpha: 0.1),
                        child: const Icon(Icons.person_rounded, size: 18, color: AppColors.kPrimaryColor),
                      ),
                      const Gap(10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(s.name, fontSize: 13, fontWeight: FontWeight.w600),
                            AppText('${s.salesCount} ventas realizadas', fontSize: 11, color: AppColors.kNeutral600),
                          ],
                        ),
                      ),
                      AppText(
                        _currencyFormat.format(s.totalRevenue),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kNeutral900,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
