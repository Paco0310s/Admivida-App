import 'package:admivida/business/features/add_sale/cart/widgets/client_selector_dialog.dart';
import 'package:admivida/business/features/clients/clients_service.dart';
import 'package:admivida/business/features/clients/models/client_debt_model.dart';
import 'package:admivida/business/features/sales/models/sale_model.dart';
import 'package:admivida/business/features/sales/sales_service.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/utils/validators.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

String _stripMexicoPrefix(String? phone) {
  if (phone == null) return '';
  final trimmed = phone.trim();
  if (trimmed.startsWith('+52 ')) return trimmed.substring(4).trim();
  if (trimmed.startsWith('+52')) return trimmed.substring(3).trim();
  return trimmed;
}

Future<bool> showEditClientDialog(
  BuildContext context, {
  required String businessId,
  required ClientWithDebtModel client,
}) async {
  final parts = client.fullName.trim().split(RegExp(r'\s+'));
  final initialFirst = parts.isNotEmpty ? parts.first : '';
  final initialLast = parts.length > 1 ? parts.sublist(1).join(' ') : '';

  final formKey = GlobalKey<FormState>();
  final firstNameCtrl = TextEditingController(text: initialFirst);
  final lastNameCtrl = TextEditingController(text: initialLast);
  final phoneCtrl = TextEditingController(text: _stripMexicoPrefix(client.phone));
  final emailCtrl = TextEditingController(text: client.email ?? '');
  bool isSaving = false;
  bool didUpdate = false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        Future<void> submit() async {
          final email = emailCtrl.text.trim();
          final rawPhone = phoneCtrl.text.trim();

          if (email.isEmpty && rawPhone.isEmpty) {
            SnackbarUtil.showWarning(
              dialogContext,
              'El cliente debe tener al menos un teléfono o correo electrónico.',
            );
            return;
          }

          if (!(formKey.currentState?.validate() ?? false)) return;

          setDialogState(() => isSaving = true);
          final payload = <String, dynamic>{
            'firstName': firstNameCtrl.text.trim(),
            'lastName': lastNameCtrl.text.trim(),
            'email': email.isEmpty ? null : email,
            'phone': normalizeClientPhone(rawPhone),
          };

          final result = await ClientsService.updateClient(
            businessId: businessId,
            clientId: client.id,
            payload: payload,
          );
          if (!dialogContext.mounted) return;

          result.when(
            (failure) {
              setDialogState(() => isSaving = false);
              SnackbarUtil.showError(
                dialogContext,
                'No se pudo actualizar el cliente (${failure.message})',
              );
            },
            (_) {
              didUpdate = true;
              NavigationService.pop(dialogContext);
            },
          );
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.edit_note_rounded, color: AppColors.kPrimaryColor),
              Gap(10),
              Expanded(
                child: AppText('Editar Cliente', fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      text: AppTexts.firstNameLabel,
                      hintText: AppTexts.firstNameHint,
                      controller: firstNameCtrl,
                      isRequired: true,
                      validator: (v) => ValidatorsUtil.validateName(v),
                    ),
                    const Gap(10),
                    AppTextField(
                      text: AppTexts.lastNameLabel,
                      hintText: AppTexts.lastNameHint,
                      controller: lastNameCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? null
                          : ValidatorsUtil.validateLastName(v),
                    ),
                    const Gap(10),
                    AppTextField(
                      text: '${AppTexts.phoneLabel} (Opcional si hay correo)',
                      hintText: 'Ej. 3312345678',
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? null
                          : ValidatorsUtil.validatePhone(v),
                    ),
                    const Gap(10),
                    AppTextField(
                      text: '${AppTexts.emailLabel} (Opcional si hay teléfono)',
                      hintText: AppTexts.emailHint,
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? null
                          : ValidatorsUtil.validateEmail(v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => NavigationService.pop(dialogContext),
              child: const AppText('Cancelar', color: AppColors.kNeutral600),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSaving ? null : submit,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.save_rounded, size: 18),
              label: const Text('Guardar cambios'),
            ),
          ],
        );
      },
    ),
  );

  firstNameCtrl.dispose();
  lastNameCtrl.dispose();
  phoneCtrl.dispose();
  emailCtrl.dispose();
  return didUpdate;
}

({String label, Color color}) _historyStatusBadge(String status) {
  switch (status.toUpperCase()) {
    case 'COMPLETED':
      return (label: 'Pagada', color: AppColors.kSuccess);
    case 'CREDIT':
      return (label: 'Fiado', color: Colors.deepOrange);
    case 'LAYAWAY':
      return (label: 'Apartado', color: Colors.purple);
    case 'PENDING':
      return (label: 'Pendiente', color: AppColors.kWarning);
    case 'CANCELLED':
      return (label: 'Cancelada', color: AppColors.kError);
    default:
      return (label: status, color: AppColors.kNeutral600);
  }
}

Future<void> showClientPurchaseHistoryDialog(
  BuildContext context, {
  required String businessId,
  required ClientWithDebtModel client,
}) async {
  final future = SalesService.getTenantSales(
    page: 1,
    limit: 25,
    businessId: businessId,
    clientUserId: client.id,
  );

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          const Icon(Icons.history_rounded, color: AppColors.kPrimaryColor),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText('Historial de compras', fontWeight: FontWeight.bold, fontSize: 17),
                AppText(
                  client.fullName,
                  fontSize: 12.5,
                  color: AppColors.kNeutral600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        height: 400,
        child: FutureBuilder(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: AppText('No se pudo cargar el historial.', color: AppColors.kError),
              );
            }

            return snapshot.data!.when(
              (failure) => Center(
                child: AppText(
                  'Error: ${failure.message}',
                  color: AppColors.kError,
                  textAlign: TextAlign.center,
                ),
              ),
              (pageModel) {
                final List<SaleModel> sales = pageModel.sales;
                if (sales.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 42, color: AppColors.kNeutral400),
                        Gap(10),
                        AppText('Este cliente aún no tiene compras registradas.', color: AppColors.kNeutral600),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: sales.length,
                  separatorBuilder: (_, _) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    final badge = _historyStatusBadge(sale.status);
                    final dateStr = DateFormat('dd MMM yyyy • hh:mm a').format(sale.effectiveDate.toLocal());
                    final itemsSummary = sale.details.take(2).map((d) => d.productNameSnapshot).join(', ');
                    final extraCount = sale.details.length > 2 ? ' +${sale.details.length - 2}' : '';
                    final isPendingDebt = sale.status == 'CREDIT' || sale.status == 'LAYAWAY';
                    final remaining = (sale.totalPriceSnapshot - (sale.amountPaid ?? 0)).clamp(0.0, double.infinity);

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onTap: () {
                        NavigationService.pop(dialogContext);
                        NavigationService.navigateTo(context, Routes.saleDetail, arguments: sale);
                      },
                      title: Row(
                        children: [
                          Expanded(
                            child: AppText(
                              dateStr,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.kNeutral900,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badge.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badge.label,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: badge.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (itemsSummary.isNotEmpty) ...[
                            const Gap(3),
                            AppText(
                              '$itemsSummary$extraCount',
                              fontSize: 12,
                              color: AppColors.kNeutral600,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const Gap(4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText(
                                'Total: \$${sale.totalPriceSnapshot.toStringAsFixed(2)}',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: AppColors.kPrimaryColor,
                              ),
                              if (isPendingDebt && remaining > 0)
                                AppText(
                                  'Resta: \$${remaining.toStringAsFixed(2)}',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.kWarning,
                                ),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.kNeutral400),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => NavigationService.pop(dialogContext),
          child: const AppText('Cerrar', color: AppColors.kNeutral600),
        ),
      ],
    ),
  );
}
