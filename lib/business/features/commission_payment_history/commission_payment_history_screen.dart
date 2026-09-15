import 'package:admivida/business/features/commission_payment_history/commission_payment_history_provider.dart';
import 'package:admivida/business/features/commission_payment_history/models/commission_payment_history_response_model.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class CommissionPaymentHistoryScreen extends StatelessWidget {
  const CommissionPaymentHistoryScreen({super.key, required this.businessId, required this.isAdmin});

  final String businessId;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final title = isAdmin ? 'Historial de Pagos' : 'Mis Pagos';

    return AppScaffold(
      title: title,
      appBar: AppBar(
        title: AppText(title, color: AppColors.kNeutral100),
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
      ),
      mobile: CommissionHistoryListView(businessId: businessId, isAdmin: isAdmin),
      tablet: CommissionHistoryListView(businessId: businessId, isAdmin: isAdmin),
      desktop: CommissionHistoryListView(businessId: businessId, isAdmin: isAdmin),
    );
  }
}

class CommissionHistoryListView extends ConsumerStatefulWidget {
  const CommissionHistoryListView({super.key, required this.businessId, required this.isAdmin});

  final String businessId;
  final bool isAdmin;

  @override
  ConsumerState<CommissionHistoryListView> createState() => _CommissionHistoryListViewState();
}

class _CommissionHistoryListViewState extends ConsumerState<CommissionHistoryListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = commissionPaymentsControllerProvider(businessId: widget.businessId, isAdmin: widget.isAdmin);
    final historyAsync = ref.watch(provider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(provider.notifier).refreshHistory();
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header summary section
            historyAsync.when(
              loading: () => const AppCard(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => AppCard(
                padding: const EdgeInsets.all(16),
                child: AppText('Error al cargar el resumen: $error', color: Colors.red),
              ),
              data: (responseModel) => _buildSummaryCard(responseModel.summary),
            ),
            const Gap(16),
            AppText('Desglose de Pagos', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
            const Gap(12),

            // Payments list section
            Expanded(
              child: historyAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => Center(child: AppText('Error loading history: $error', color: Colors.red)),
                data: (responseModel) {
                  final payments = responseModel.payments;

                  if (payments.isEmpty) {
                    return Center(child: AppText(AppTexts.noData, color: AppColors.kNeutral600));
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      return _buildPaymentCard(payment);
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

  Widget _buildSummaryCard(CommissionPaymentSummaryModel summary) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            widget.isAdmin ? 'Balance General de Pagos' : 'Mi Balance de Pagos',
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.kPrimaryColor,
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(widget.isAdmin ? 'Total Pagado' : 'Total Cobrado', color: AppColors.kNeutral600, fontSize: 12),
                    const Gap(4),
                    AppText('\$${summary.totalPaidAmount.toStringAsFixed(2)}', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.kSuccess),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText('Pendiente', color: AppColors.kNeutral600, fontSize: 12),
                  const Gap(4),
                  AppText('\$${summary.totalPendingAmount.toStringAsFixed(2)}', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.kWarning),
                ],
              ),
            ],
          ),
          const Gap(12),
          Divider(color: AppColors.kNeutral200, height: 1),
          const Gap(8),
          Row(
            children: [
              AppText('Calculado por sistema: ', color: AppColors.kNeutral600, fontSize: 12),
              AppText('\$${summary.totalCalculatedAmount.toStringAsFixed(2)}', color: AppColors.kNeutral900, fontSize: 12, fontWeight: FontWeight.bold),
              const Spacer(),
              AppText('Pagos: ', color: AppColors.kNeutral600, fontSize: 12),
              AppText('${summary.totalPaymentsCount}', color: AppColors.kNeutral900, fontSize: 12, fontWeight: FontWeight.bold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(CommissionPaymentItemModel payment) {
    final formattedDate = '${payment.createdAt.day}/${payment.createdAt.month}/${payment.createdAt.year}';

    // For the seller/employee it's visually an income, for the admin/owner it's an expense.
    final isIncome = !widget.isAdmin;
    final isCommission = payment.type == 'COMMISSION';

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // If it's a free payment, disable expansion since there are no sale details
          enabled: isCommission,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Un poco más de padding vertical
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (isCommission ? AppColors.kSuccess : AppColors.kPrimaryColor).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(isCommission ? Icons.receipt_long_rounded : Icons.payments_rounded, color: isCommission ? AppColors.kSuccess : AppColors.kPrimaryColor),
          ),
          title: Row(
            children: [
              Expanded(
                child: AppText(widget.isAdmin ? payment.employeeName : 'Pago Recibido', fontWeight: FontWeight.bold, color: AppColors.kNeutral900),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: (isCommission ? Colors.green : Colors.blue).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(
                  isCommission ? 'Comisión' : 'Pago Libre',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCommission ? Colors.green.shade700 : Colors.blue.shade700),
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(4),
              AppText('Fecha: $formattedDate', color: AppColors.kNeutral500, fontSize: 12),

              // NEW: Muestra la nota directamente en el subtítulo si es Pago Libre
              if (!isCommission && payment.notes != null && payment.notes!.isNotEmpty) ...[
                const Gap(4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.short_text, size: 14, color: Colors.grey),
                    const Gap(4),
                    Expanded(
                      child: AppText(payment.notes!, color: AppColors.kNeutral600, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ],
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                '${isIncome ? '+' : '-'}\$${payment.paidAmount.toStringAsFixed(2)}',
                color: isIncome ? AppColors.kSuccess : AppColors.kNeutral900,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              const Gap(2),
              // Ocultamos la palabra "Nómina" si es pago libre, porque la nota ya nos da contexto
              if (isCommission) AppText('Detalles', color: AppColors.kPrimaryColor, fontSize: 11),
            ],
          ),
          children: [
            // Details section only shown if it's a COMMISSION
            if (isCommission) ...[
              Container(color: AppColors.kNeutral200, height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (payment.notes != null && payment.notes!.isNotEmpty) ...[
                      AppText('Nota: ${payment.notes}', color: AppColors.kNeutral700, fontSize: 13, fontStyle: FontStyle.italic),
                      const Gap(12),
                    ],
                    AppText('Productos pagados:', fontWeight: FontWeight.bold, color: AppColors.kNeutral800, fontSize: 13),
                    const Gap(8),
                    ...payment.details.map(
                      (detail) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText('${detail.quantity.toInt()}x', color: AppColors.kNeutral500, fontSize: 12, fontWeight: FontWeight.bold),
                            const Gap(8),
                            Expanded(child: AppText(detail.productName, color: AppColors.kNeutral800, fontSize: 13)),
                            AppText('\$${detail.commission.toStringAsFixed(2)}', color: AppColors.kSuccess, fontSize: 13, fontWeight: FontWeight.bold),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
