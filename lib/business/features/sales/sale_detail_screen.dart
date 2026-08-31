import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class SaleDetailScreen extends StatelessWidget {
  const SaleDetailScreen({super.key, required this.sale});

  final SaleModel sale;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Detalle de Venta',
      appBar: AppBar(
        title: const AppText('Detalle de Venta', color: AppColors.kNeutral100),
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
      ),
      mobile: _SaleDetailView(sale: sale),
      tablet: _SaleDetailView(sale: sale),
      desktop: _SaleDetailView(sale: sale),
    );
  }
}

class _SaleDetailView extends StatelessWidget {
  const _SaleDetailView({required this.sale});

  final SaleModel sale;

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd/MM/yyyy • hh:mm a').format(sale.createdAt.toLocal());
    final isPaid = sale.status.toUpperCase() == 'PAID' || sale.status.toUpperCase() == 'COMPLETED';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600), // Nice width for tablets too
          child: Column(
            children: [
              // 💡 Receipt Card
              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- HEADER ---
                    const Icon(Icons.check_circle_rounded, color: AppColors.kSuccess, size: 56),
                    const Gap(12),
                    Center(
                      child: AppText(isPaid ? 'Venta Cobrada' : 'Venta Pendiente', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.kNeutral900),
                    ),
                    Center(
                      child: AppText(
                        '\$${sale.totalPriceSnapshot.toStringAsFixed(2)}',
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kPrimaryColor,
                      ),
                    ),
                    const Gap(8),
                    Center(child: AppText(dateFormatted, color: AppColors.kNeutral500, fontSize: 13)),
                    const Gap(24),
                    const Divider(color: AppColors.kNeutral200),
                    const Gap(16),

                    // --- INFO SECTION ---
                    _InfoRow(label: 'Folio de venta', value: sale.id.split('-').first.toUpperCase()),
                    _InfoRow(label: 'Cliente', value: sale.clientNameSnapshot),
                    _InfoRow(label: 'Atendido por', value: sale.sellerName ?? 'Vendedor'),
                    if (sale.notes?.isNotEmpty == true) _InfoRow(label: 'Notas', value: sale.notes!),

                    const Gap(16),
                    const Divider(color: AppColors.kNeutral200),
                    const Gap(16),

                    // --- ITEMS SECTION ---
                    AppText('Artículos (${sale.details.length})', fontWeight: FontWeight.bold, color: AppColors.kNeutral900, fontSize: 16),
                    const Gap(8),
                    ...sale.details.map((detail) {
                      final qty = detail.quantity == detail.quantity.toInt() ? detail.quantity.toInt().toString() : detail.quantity.toString();

                      return InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          if (detail.productId != null) {
                            NavigationService.navigateTo(
                              context,
                              Routes.productDetail,
                              arguments: {'businessId': sale.businessId, 'productId': detail.productId},
                            );
                          } else {
                            SnackbarUtil.showError(context, 'No se puede abrir este producto (Falta ID)');
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 💡 Product Image Thumbnail
                              if (detail.imageUrl != null)
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.kNeutral200),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    // Make sure your AdaptedFile supports just URL if blurhash is null
                                    child: AdaptedFile.network(detail.imageUrl!).getWidget(fit: BoxFit.cover),
                                  ),
                                )
                              else
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(color: AppColors.kPrimary50, borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.inventory_2_outlined, size: 20, color: AppColors.kPrimaryColor),
                                ),
                              const Gap(12),

                              AppText('${qty}x', fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor, fontSize: 14),
                              const Gap(8),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(detail.productNameSnapshot, color: AppColors.kNeutral900, fontSize: 14),
                                    AppText('\$${detail.productPriceSnapshot.toStringAsFixed(2)} c/u', color: AppColors.kNeutral500, fontSize: 12),
                                  ],
                                ),
                              ),
                              AppText('\$${detail.subtotal.toStringAsFixed(2)}', fontWeight: FontWeight.bold, color: AppColors.kNeutral900, fontSize: 14),
                            ],
                          ),
                        ),
                      );
                    }),

                    const Gap(8),
                    const Divider(color: AppColors.kNeutral200),
                    const Gap(16),

                    // --- SUMMARY SECTION ---
                    _SummaryRow(label: 'Subtotal', value: '\$${(sale.totalPriceSnapshot + sale.discountAmount).toStringAsFixed(2)}'),
                    if (sale.discountAmount > 0) _SummaryRow(label: 'Descuento', value: '-\$${sale.discountAmount.toStringAsFixed(2)}', valueColor: Colors.red),
                    const Gap(8),
                    _SummaryRow(label: 'Total', value: '\$${sale.totalPriceSnapshot.toStringAsFixed(2)}', isTotal: true),

                    const Gap(16),
                    if (sale.amountPaid != null) ...[
                      _SummaryRow(label: 'Efectivo recibido', value: '\$${sale.amountPaid!.toStringAsFixed(2)}'),
                      _SummaryRow(label: 'Cambio', value: '\$${(sale.changeGiven ?? 0).toStringAsFixed(2)}'),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 💡 Helper Widgets to keep the main tree clean
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: AppText(label, color: AppColors.kNeutral500, fontSize: 13)),
          Expanded(
            flex: 3,
            child: AppText(value, color: AppColors.kNeutral900, fontWeight: FontWeight.bold, fontSize: 13, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.isTotal = false, this.valueColor});

  final String label;
  final String value;
  final bool isTotal;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            label,
            color: isTotal ? AppColors.kNeutral900 : AppColors.kNeutral600,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            fontSize: isTotal ? 16 : 14,
          ),
          AppText(
            value,
            color: valueColor ?? (isTotal ? AppColors.kPrimaryColor : AppColors.kNeutral900),
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 18 : 14,
          ),
        ],
      ),
    );
  }
}
