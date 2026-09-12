import 'package:admivida/business/features/commission_payment_history/models/commission_payment_history_provider.dart';
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
    final title = isAdmin ? 'Historial de Comisiones' : 'Mis Comisiones';

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
            widget.isAdmin ? 'Balance General de Comisiones' : 'Mi Balance de Comisiones',
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText('Pendiente', color: AppColors.kNeutral600, fontSize: 12),
                    const Gap(4),
                    AppText('\$${summary.totalPendingAmount.toStringAsFixed(2)}', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.kWarning),
                  ],
                ),
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
    final isIncome = !widget.isAdmin; // Para el vendedor es un ingreso, para el dueño egreso visual.

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero, // El ExpansionTile maneja su propio padding
      child: Theme(
        // Quitamos las líneas de los bordes del ExpansionTile por defecto
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: AppColors.kSuccess.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.attach_money_rounded, color: AppColors.kSuccess),
          ),
          title: AppText(widget.isAdmin ? payment.sellerName : 'Pago Recibido', fontWeight: FontWeight.bold, color: AppColors.kNeutral900),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(4),
              AppText('Fecha: $formattedDate', color: AppColors.kNeutral500, fontSize: 12),
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
              AppText('Detalles', color: AppColors.kPrimaryColor, fontSize: 11),
            ],
          ),
          children: [
            Container(color: AppColors.kNeutral200, height: 1), // Custom Divider
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
        ),
      ),
    );
  }
}
