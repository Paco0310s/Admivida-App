import 'dart:async';
import 'dart:math';

import 'package:admivida/business/features/add_sale/cart/models/create_sale_dto.dart';
import 'package:admivida/business/features/add_transaction/add_transactions_provider.dart';
import 'package:admivida/business/features/add_transaction/models/payment_method_model.dart';
import 'package:admivida/business/features/cash_shifts/cash_shifts_provider.dart';
import 'package:admivida/business/features/clients/clients_provider.dart';
import 'package:admivida/business/features/clients/models/client_payment_response.dart';
import 'package:admivida/business/features/transactions/transactions_provider.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/enums/app_failure_enum.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/services/pdf_receipt_service.dart';
import 'package:admivida/common/services/printer_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/dashboard_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class ClientPaymentsScreen extends ConsumerStatefulWidget {
  final String businessId;
  final String clientId;
  final String clientName;

  const ClientPaymentsScreen({super.key, required this.businessId, required this.clientId, required this.clientName});

  @override
  ConsumerState<ClientPaymentsScreen> createState() => _ClientPaymentsScreenState();
}

class _ClientPaymentsScreenState extends ConsumerState<ClientPaymentsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controladores reactivos
  final TextEditingController _totalController = TextEditingController();
  final FocusNode _totalFocusNode = FocusNode();
  final Map<String, TextEditingController> _itemControllers = {};
  final Map<String, FocusNode> _itemFocusNodes = {};

  // Selectores
  String? _selectedAccountId;
  String? _selectedPaymentMethodId;
  List<CreateSalePaymentDto> _mixedPayments = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _totalController.dispose();
    _totalFocusNode.dispose();
    for (var ctrl in _itemControllers.values) {
      ctrl.dispose();
    }
    for (var fn in _itemFocusNodes.values) {
      fn.dispose();
    }
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM, yyyy - HH:mm').format(date);
  }

  double _parseAmount(String raw) {
    final cleaned = raw.trim().replaceAll(' ', '');
    if (cleaned.isEmpty) return 0.0;
    if (cleaned.contains(',') && !cleaned.contains('.')) {
      final afterComma = cleaned.split(',').last;
      if (afterComma.length <= 2) {
        return double.tryParse(cleaned.replaceAll(',', '.')) ?? 0.0;
      }
    }
    return double.tryParse(cleaned.replaceAll(',', '')) ?? 0.0;
  }

  Future<bool> _showQuickOpenShiftDialog() async {
    final amountCtrl = TextEditingController(text: '0.00');
    String? selectedAccountId;
    bool opened = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Consumer(
        builder: (ctx, dialogRef, _) {
          final accountsAsync = dialogRef.watch(accountsBusinessProvider(businessId: widget.businessId));
          return StatefulBuilder(
            builder: (ctx, setDialogState) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.lock_open_rounded, color: AppColors.kPrimaryColor),
                  Gap(10),
                  Expanded(child: AppText('Abrir Turno de Caja', fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    'Para recibir abonos en tienda debes tener tu turno de caja abierto. Selecciona la caja/cuenta del turno e ingresa tu fondo inicial:',
                    fontSize: 13,
                    color: AppColors.kNeutral600,
                  ),
                  const Gap(14),
                  accountsAsync.when(
                    data: (accounts) {
                      final operationalAccounts = accounts.where((a) => !a.isCreditOrLoan).toList();
                      final selectable = operationalAccounts.isNotEmpty ? operationalAccounts : accounts;
                      if (selectedAccountId == null && selectable.isNotEmpty) {
                        final defaultAcc = selectable.firstWhere((a) => a.isDefault, orElse: () => selectable.first);
                        selectedAccountId = defaultAcc.id;
                      }
                      if (selectable.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: DropdownButtonFormField<String>(
                          initialValue: selectedAccountId,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Caja / Cuenta del Turno',
                            prefixIcon: const Icon(Icons.point_of_sale_rounded, size: 20),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          items: selectable
                              .map(
                                (a) => DropdownMenuItem<String>(
                                  value: a.id,
                                  child: Text(a.isDefault ? '${a.name} (Principal)' : a.name, overflow: TextOverflow.ellipsis),
                                ),
                              )
                              .toList(),
                          onChanged: (val) => setDialogState(() => selectedAccountId = val),
                        ),
                      );
                    },
                    loading: () => const Padding(padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator()),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                  TextField(
                    controller: amountCtrl,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      prefixText: '\$ ',
                      labelText: 'Fondo Inicial en Efectivo',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => NavigationService.pop(dialogContext),
                  child: const AppText('Cancelar', color: AppColors.kNeutral600),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
                  onPressed: () async {
                    final parsed = _parseAmount(amountCtrl.text);
                    if (parsed < 0) {
                      SnackbarUtil.showWarning(context, 'Ingresa un monto inicial válido mayor o igual a 0.');
                      return;
                    }
                    NavigationService.pop(dialogContext);
                    final error = await ref.read(cashShiftsProvider(widget.businessId).notifier).openShift(
                          openingAmount: parsed,
                          accountId: selectedAccountId,
                        );
                    if (!mounted) return;
                    if (error != null) {
                      SnackbarUtil.showError(context, error);
                    } else {
                      if (selectedAccountId != null) {
                        setState(() => _selectedAccountId = selectedAccountId);
                      }
                      opened = true;
                      SnackbarUtil.showSuccess(context, 'Turno de caja abierto correctamente.');
                    }
                  },
                  child: const Text('Abrir Turno', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        },
      ),
    );
    amountCtrl.dispose();
    return opened;
  }

  Future<bool> _showMixedPaymentDialog(double targetTotal) async {
    if (targetTotal <= 0) {
      SnackbarUtil.showWarning(context, 'Primero ingresa el monto total o distribuye el abono en los tickets.');
      return false;
    }

    final methods = ref.read(paymentMethodsProvider).value ?? const <PaymentMethodModel>[];
    if (methods.isEmpty) {
      SnackbarUtil.showWarning(context, 'Cargando métodos de pago...');
      return false;
    }

    final List<({String methodId, TextEditingController ctrl})> rows = [];
    if (_mixedPayments.isNotEmpty) {
      for (final p in _mixedPayments) {
        rows.add((methodId: p.paymentMethodId, ctrl: TextEditingController(text: p.amount.toStringAsFixed(2))));
      }
    } else {
      final firstId = _selectedPaymentMethodId ?? methods.first.id;
      final second = methods.firstWhere((m) => m.id != firstId, orElse: () => methods.first);
      rows.add((methodId: firstId, ctrl: TextEditingController(text: targetTotal.toStringAsFixed(2))));
      if (second.id != firstId) {
        rows.add((methodId: second.id, ctrl: TextEditingController(text: '0.00')));
      }
    }

    bool confirmed = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            double currentSum = 0.0;
            for (final r in rows) {
              currentSum += _parseAmount(r.ctrl.text);
            }
            final remaining = (targetTotal - currentSum);
            final isExact = remaining.abs() <= 0.01;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.call_split_rounded, color: AppColors.kPrimaryColor),
                  Gap(10),
                  Expanded(child: AppText('Pago Mixto en Abono', fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.kPrimary50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const AppText('Total del Abono:', fontWeight: FontWeight.w600),
                            AppText(
                              '\$${targetTotal.toStringAsFixed(2)}',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.kPrimaryColor,
                            ),
                          ],
                        ),
                      ),
                      const Gap(12),
                      for (int i = 0; i < rows.length; i++) ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<String>(
                                key: ValueKey('abono-mix-row-$i-${rows[i].methodId}'),
                                initialValue: rows[i].methodId,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Método ${i + 1}',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                items: methods
                                    .map((m) => DropdownMenuItem<String>(value: m.id, child: Text(m.name, overflow: TextOverflow.ellipsis)))
                                    .toList(),
                                onChanged: (val) {
                                  if (val == null) return;
                                  setDialogState(() {
                                    final oldCtrl = rows[i].ctrl;
                                    rows[i] = (methodId: val, ctrl: oldCtrl);
                                  });
                                },
                              ),
                            ),
                            const Gap(8),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: rows[i].ctrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  prefixText: '\$ ',
                                  labelText: 'Monto',
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onChanged: (_) => setDialogState(() {}),
                              ),
                            ),
                            if (rows.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () {
                                  setDialogState(() {
                                    rows[i].ctrl.dispose();
                                    rows.removeAt(i);
                                  });
                                },
                              ),
                          ],
                        ),
                        const Gap(8),
                      ],
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setDialogState(() {
                              final nextMethod = methods.firstWhere(
                                (m) => !rows.any((r) => r.methodId == m.id),
                                orElse: () => methods.first,
                              );
                              final autoFill = remaining > 0 ? remaining.toStringAsFixed(2) : '0.00';
                              rows.add((methodId: nextMethod.id, ctrl: TextEditingController(text: autoFill)));
                            });
                          },
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          label: const Text('Agregar método'),
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText('Suma capturada:', fontWeight: FontWeight.w600),
                          AppText(
                            '\$${currentSum.toStringAsFixed(2)}',
                            fontWeight: FontWeight.bold,
                            color: isExact ? AppColors.kSuccess : Colors.red,
                          ),
                        ],
                      ),
                      if (!isExact) ...[
                        const Gap(4),
                        AppText(
                          remaining > 0
                              ? 'Falta asignar \$${remaining.toStringAsFixed(2)}'
                              : 'Sobra \$${(-remaining).toStringAsFixed(2)} respecto al abono',
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                if (_mixedPayments.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() => _mixedPayments = []);
                      NavigationService.pop(dialogContext);
                    },
                    child: const Text('Quitar Pago Mixto', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => NavigationService.pop(dialogContext),
                  child: const AppText('Cancelar', color: AppColors.kNeutral600),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
                  onPressed: !isExact
                      ? null
                      : () {
                          final built = <CreateSalePaymentDto>[];
                          for (final r in rows) {
                            final amt = _parseAmount(r.ctrl.text);
                            if (amt <= 0) continue;
                            final method = methods.firstWhere((m) => m.id == r.methodId, orElse: () => methods.first);
                            built.add(
                              CreateSalePaymentDto(
                                paymentMethodId: method.id,
                                amount: double.parse(amt.toStringAsFixed(2)),
                                paymentMethodName: method.name,
                              ),
                            );
                          }
                          if (built.isEmpty) {
                            SnackbarUtil.showWarning(context, 'Ingresa al menos un método con monto mayor a 0.');
                            return;
                          }
                          setState(() {
                            _mixedPayments = built;
                            _selectedPaymentMethodId = built.first.paymentMethodId;
                          });
                          confirmed = true;
                          NavigationService.pop(dialogContext);
                        },
                  child: const Text('Aplicar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    for (final r in rows) {
      r.ctrl.dispose();
    }
    return confirmed;
  }

  Future<void> _showPaymentReceiptDialog(ClientPaymentResponse response) async {
    final businessName = DashboardSession.activeBusiness.value?.name ?? 'Admivida POS';
    final shiftCashierName = ref.read(cashShiftsProvider(widget.businessId)).activeShift?.cashierName;
    final cashierName = (shiftCashierName != null && shiftCashierName.trim().isNotEmpty) ? shiftCashierName : 'Cajero';

    bool isPrinting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.kSuccess, size: 28),
              Gap(10),
              Expanded(child: AppText('Abono Registrado', fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: 390,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.kSuccess.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.kSuccess.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      children: [
                        AppText('Folio: ${response.receiptId}', fontSize: 12, color: AppColors.kNeutral600),
                        const Gap(4),
                        AppText(
                          '\$${response.totalPaid.toStringAsFixed(2)}',
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.kSuccess,
                        ),
                        if (response.accountName != null) ...[
                          const Gap(4),
                          AppText('Cuenta: ${response.accountName}', fontSize: 12, color: AppColors.kNeutral700),
                        ],
                      ],
                    ),
                  ),
                  const Gap(14),
                  _ReceiptRow(label: 'Cliente', value: widget.clientName),
                  _ReceiptRow(label: 'Saldo anterior', value: '\$${response.previousTotalDebt.toStringAsFixed(2)}'),
                  _ReceiptRow(label: 'Total abonado', value: '\$${response.totalPaid.toStringAsFixed(2)}', valueColor: AppColors.kSuccess),
                  _ReceiptRow(
                    label: 'Saldo restante',
                    value: response.remainingTotalDebt <= 0.01 ? 'Liquidado (\$0.00)' : '\$${response.remainingTotalDebt.toStringAsFixed(2)}',
                    valueColor: response.remainingTotalDebt <= 0.01 ? AppColors.kSuccess : AppColors.kWarning,
                    isBold: true,
                  ),
                  if (response.payments.isNotEmpty) ...[
                    const Divider(height: 18),
                    const AppText('Métodos de Pago:', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.kNeutral700),
                    const Gap(6),
                    ...response.payments.map(
                      (p) => _ReceiptRow(label: ' • ${p.paymentMethodName}', value: '\$${p.amount.toStringAsFixed(2)}'),
                    ),
                  ],
                  if (response.appliedTickets.isNotEmpty) ...[
                    const Divider(height: 18),
                    const AppText('Tickets aplicados:', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.kNeutral700),
                    const Gap(6),
                    ...response.appliedTickets.map((t) {
                      final shortId = t.saleId.length >= 8 ? t.saleId.substring(0, 8).toUpperCase() : t.saleId;
                      final statusTag = t.remainingBalance <= 0.01 ? 'Pagado' : 'Resta \$${t.remainingBalance.toStringAsFixed(2)}';
                      return _ReceiptRow(
                        label: ' • #$shortId ($statusTag)',
                        value: '\$${t.amountPaid.toStringAsFixed(2)}',
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            OutlinedButton.icon(
              onPressed: () => PdfReceiptService.showClientPaymentPdfPreviewDialog(
                context: dialogContext,
                payment: response,
                clientName: widget.clientName,
                cashierName: cashierName,
                fallbackBusinessName: businessName,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F766E),
                side: const BorderSide(color: Color(0xFF0F766E)),
              ),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
              label: const Text('PDF / WhatsApp'),
            ),
            OutlinedButton.icon(
              onPressed: isPrinting
                  ? null
                  : () async {
                      setDialogState(() => isPrinting = true);
                      final doc = response.toObjectToPrint(
                        businessName: businessName,
                        clientName: widget.clientName,
                        cashierName: cashierName,
                        openDrawer: false,
                      );
                      await ref.read(printerServiceProvider).showPrintersAndPrint(dialogContext, doc);
                      if (dialogContext.mounted) {
                        setDialogState(() => isPrinting = false);
                      }
                    },
              icon: isPrinting
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.print_rounded, size: 18),
              label: const Text('Imprimir Recibo'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor),
              onPressed: () {
                NavigationService.pop(dialogContext);
                if (mounted) {
                  NavigationService.pop(context);
                }
              },
              child: const Text('Aceptar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _submitPayment(PaymentDistributionState state) async {
    if (!_formKey.currentState!.validate()) return;

    final isAdmin = ref.read(isBusinessAdminProvider(widget.businessId));
    final cashShiftsState = ref.read(cashShiftsProvider(widget.businessId));
    if (!isAdmin && cashShiftsState.activeShift == null) {
      final opened = await _showQuickOpenShiftDialog();
      if (!opened || !mounted) return;
    }

    if (_selectedAccountId == null) {
      SnackbarUtil.showWarning(context, 'Por favor selecciona una cuenta');
      return;
    }

    if (_selectedPaymentMethodId == null && _mixedPayments.isEmpty) {
      SnackbarUtil.showWarning(context, 'Por favor selecciona un método de pago');
      return;
    }

    final textValue = _totalController.text.trim();
    final visibleAmount = textValue.isEmpty ? state.totalAmount : _parseAmount(textValue);

    final distributedSum = double.parse(
      state.distributions.values.fold(0.0, (sum, amount) => sum + amount).toStringAsFixed(2),
    );
    final totalDebt = state.sales.fold(0.0, (sum, sale) => sum + sale.pendingBalance);

    if (visibleAmount > totalDebt + 0.01) {
      SnackbarUtil.showError(context, 'El monto ingresado supera la deuda total pendiente de \$${totalDebt.toStringAsFixed(2)}');
      return;
    }

    if ((visibleAmount - distributedSum).abs() > 0.01) {
      SnackbarUtil.showError(context, 'Error de cálculo. Revisa que el total coincida con la distribución de los tickets.');
      return;
    }

    final distributionsToSave = state.distributions.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {'saleId': entry.key, 'amount': double.parse(entry.value.toStringAsFixed(2))})
        .toList();

    if (distributionsToSave.isEmpty || distributedSum <= 0) {
      SnackbarUtil.showWarning(context, 'El monto a abonar debe ser mayor a 0');
      return;
    }

    if (_mixedPayments.isNotEmpty) {
      final mixedSum = _mixedPayments.fold<double>(0.0, (sum, p) => sum + p.amount);
      if ((mixedSum - distributedSum).abs() > 0.01) {
        final adjusted = await _showMixedPaymentDialog(distributedSum);
        if (!adjusted || !mounted) return;
      }
    }

    final payload = <String, dynamic>{
      'totalAmount': distributedSum,
      'accountId': _selectedAccountId,
      'paymentMethodId': _mixedPayments.isNotEmpty ? _mixedPayments.first.paymentMethodId : _selectedPaymentMethodId,
      if (_mixedPayments.isNotEmpty)
        'payments': _mixedPayments.map((p) => {'paymentMethodId': p.paymentMethodId, 'amount': p.amount}).toList(),
      'distributions': distributionsToSave,
    };

    ref.read(processClientPaymentProvider.notifier).submit(businessId: widget.businessId, clientId: widget.clientId, payload: payload);
  }

  Widget _buildHeaderCard(double totalGlobalDebt, double currentPaymentAmount) {
    final projectedRemaining = (totalGlobalDebt - currentPaymentAmount).clamp(-double.infinity, double.infinity);

    return AppCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText('Abono a Cuenta', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
            const Gap(6),
            const AppText('Distribuye el pago de forma manual o automática entre los tickets del cliente.', color: AppColors.kNeutral600),
            const Gap(14),
            const Divider(),
            const Gap(8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const AppText('Deuda Pendiente:', color: AppColors.kNeutral700, fontSize: 16, fontWeight: FontWeight.bold),
                AppText('\$${totalGlobalDebt.toStringAsFixed(2)}', color: AppColors.kWarning, fontWeight: FontWeight.bold, fontSize: 20),
              ],
            ),
            if (currentPaymentAmount > 0) ...[
              const Gap(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const AppText('Proyección:', color: AppColors.kNeutral700, fontSize: 14),
                  Builder(
                    builder: (context) {
                      if (projectedRemaining < -0.01) {
                        return const AppText('El abono supera la deuda', color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold);
                      } else if (projectedRemaining <= 0.01) {
                        return const AppText('Cuenta liquidada 🎉', color: AppColors.kSuccess, fontSize: 14, fontWeight: FontWeight.bold);
                      } else {
                        return AppText(
                          'Restará: \$${projectedRemaining.toStringAsFixed(2)}',
                          color: AppColors.kPrimaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final salesAsync = ref.watch(pendingSalesProvider(businessId: widget.businessId, clientId: widget.clientId));
    final accountsAsync = ref.watch(accountsBusinessProvider(businessId: widget.businessId));
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);
    final cashShiftsState = ref.watch(cashShiftsProvider(widget.businessId));
    final isAdmin = ref.watch(isBusinessAdminProvider(widget.businessId));

    final distributionState = ref.watch(paymentDistributionProvider(businessId: widget.businessId, clientId: widget.clientId));
    final distributionNotifier = ref.read(paymentDistributionProvider(businessId: widget.businessId, clientId: widget.clientId).notifier);

    return salesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: AppText('Error: $err', color: Colors.red)),
      data: (sales) {
        if (sales.isEmpty) {
          return const Center(child: AppText('Este cliente no tiene deudas pendientes.', color: AppColors.kNeutral600));
        }

        final totalGlobalDebt = sales.fold<double>(0, (sum, item) => sum + item.pendingBalance);

        for (var sale in sales) {
          _itemControllers.putIfAbsent(sale.id, () => TextEditingController());
          _itemFocusNodes.putIfAbsent(sale.id, () => FocusNode());
        }

        final activeShift = cashShiftsState.activeShift;
        final mustOpenShift = !isAdmin && !cashShiftsState.isLoading && activeShift == null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mustOpenShift)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.45)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock_clock_rounded, color: Colors.amber.shade900),
                        const Gap(10),
                        Expanded(
                          child: AppText(
                            'No tienes turno de caja abierto. Abre tu turno para que el abono quede registrado en tu corte.',
                            fontSize: 12.5,
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(8),
                        ElevatedButton(
                          onPressed: _showQuickOpenShiftDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.kPrimaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Abrir Turno', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                _buildHeaderCard(totalGlobalDebt, distributionState.totalAmount),

                // --- TARJETA DE CONFIGURACIÓN DEL PAGO ---
                AppCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Monto Total a Abonar + Acciones rápidas
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _totalController,
                              focusNode: _totalFocusNode,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              decoration: InputDecoration(
                                labelText: 'Cantidad a Abonar *',
                                prefixText: '\$ ',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: AppColors.kPrimaryColor, width: 2),
                                ),
                              ),
                              onChanged: (value) {
                                final val = _parseAmount(value);
                                setState(() => _mixedPayments = []);
                                distributionNotifier.distributeTotal(min(val, totalGlobalDebt));
                              },
                            ),
                          ),
                          const Gap(8),
                          Column(
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  _totalFocusNode.unfocus();
                                  setState(() => _mixedPayments = []);
                                  distributionNotifier.payAll();
                                  _totalController.text = totalGlobalDebt.toStringAsFixed(2);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.kSuccess,
                                  side: const BorderSide(color: AppColors.kSuccess),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                child: const Text('Liquidar todo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              if (distributionState.totalAmount > 0) ...[
                                const Gap(4),
                                TextButton(
                                  onPressed: () {
                                    _totalFocusNode.unfocus();
                                    _totalController.clear();
                                    setState(() => _mixedPayments = []);
                                    distributionNotifier.clearDistributions();
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.kNeutral600,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Limpiar', style: TextStyle(fontSize: 11.5)),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Cuenta Destino (sincronizada con CashShift si hay turno abierto)
                      accountsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Text('Error al cargar cuentas: $err', style: const TextStyle(color: Colors.red)),
                        data: (accounts) {
                          final operationalAccounts = accounts.where((a) => !a.isCreditOrLoan).toList();
                          final selectableAccounts = operationalAccounts.isNotEmpty ? operationalAccounts : accounts;
                          final shiftAccountId = activeShift?.accountId;

                          if (selectableAccounts.isNotEmpty) {
                            final defaultAcc = selectableAccounts.firstWhere(
                              (a) => a.isDefault,
                              orElse: () => selectableAccounts.firstWhere(
                                (a) => a.name.toLowerCase().startsWith('caja general'),
                                orElse: () => selectableAccounts.first,
                              ),
                            );

                            if (!isAdmin) {
                              if (shiftAccountId != null && selectableAccounts.any((a) => a.id == shiftAccountId)) {
                                _selectedAccountId = shiftAccountId;
                              } else {
                                _selectedAccountId = defaultAcc.id;
                              }
                            } else if (_selectedAccountId == null || !selectableAccounts.any((a) => a.id == _selectedAccountId)) {
                              _selectedAccountId = (shiftAccountId != null && selectableAccounts.any((a) => a.id == shiftAccountId))
                                  ? shiftAccountId
                                  : defaultAcc.id;
                            }
                          }

                          final isLockedToShift = !isAdmin;
                          final isLinkedToShift = activeShift != null && (shiftAccountId == null || _selectedAccountId == shiftAccountId);
                          final label = !isAdmin && shiftAccountId != null
                              ? 'Caja / Cuenta (Turno Abierto)'
                              : (isAdmin ? 'Ingresar a Cuenta *' : 'Ingresar a Cuenta (Fija)');

                          String? shiftHint;
                          if (isAdmin) {
                            if (activeShift == null) {
                              shiftHint = 'Sin turno abierto: el abono ingresará directo a esta cuenta.';
                            } else if (isLinkedToShift) {
                              shiftHint = 'Coincide con tu turno abierto: se sumará a tu corte actual.';
                            } else {
                              shiftHint = 'Cuenta distinta a tu caja abierta: entrará directo sin afectar tu turno.';
                            }
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                key: ValueKey('client-payment-acc-$_selectedAccountId-$isLockedToShift'),
                                initialValue: _selectedAccountId,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: label,
                                  filled: isLockedToShift,
                                  fillColor: isLockedToShift ? AppColors.kNeutral50 : null,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  prefixIcon: Icon(
                                    isLockedToShift ? Icons.lock_outline : Icons.account_balance_wallet,
                                    color: isLockedToShift ? AppColors.kNeutral500 : AppColors.kPrimaryColor,
                                  ),
                                ),
                                items: selectableAccounts
                                    .map(
                                      (acc) => DropdownMenuItem<String>(
                                        value: acc.id,
                                        child: Text(
                                          acc.isDefault ? '${acc.name} ★' : acc.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                validator: (val) => val == null ? 'Selecciona una cuenta' : null,
                                onChanged: isLockedToShift ? null : (value) => setState(() => _selectedAccountId = value),
                              ),
                              if (shiftHint != null) ...[
                                const Gap(6),
                                Row(
                                  children: [
                                    Icon(
                                      isLinkedToShift ? Icons.point_of_sale_rounded : Icons.info_outline_rounded,
                                      size: 14,
                                      color: isLinkedToShift ? AppColors.kSuccess : AppColors.kPrimaryColor,
                                    ),
                                    const Gap(6),
                                    Expanded(
                                      child: AppText(
                                        shiftHint,
                                        fontSize: 11.5,
                                        color: isLinkedToShift ? AppColors.kSuccess : AppColors.kNeutral600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Método de Pago + Pago Mixto
                      paymentMethodsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Text('Error al cargar métodos: $err', style: const TextStyle(color: Colors.red)),
                        data: (methods) {
                          if (_selectedPaymentMethodId == null && methods.isNotEmpty) {
                            final cashMethod = methods.firstWhere(
                              (m) => m.name.toLowerCase().contains('efectivo') || m.name.toLowerCase().contains('cash'),
                              orElse: () => methods.first,
                            );
                            _selectedPaymentMethodId = cashMethod.id;
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<String>(
                                key: ValueKey('client-payment-method-$_selectedPaymentMethodId'),
                                initialValue: _selectedPaymentMethodId,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Método de Pago *',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  prefixIcon: const Icon(Icons.payment, color: AppColors.kPrimaryColor),
                                ),
                                items: methods.map((method) => DropdownMenuItem<String>(value: method.id, child: Text(method.name))).toList(),
                                validator: (val) => (val == null && _mixedPayments.isEmpty) ? 'Selecciona un método de pago' : null,
                                onChanged: (value) => setState(() {
                                  _selectedPaymentMethodId = value;
                                  _mixedPayments = [];
                                }),
                              ),
                              const Gap(10),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      final target = distributionState.totalAmount > 0
                                          ? distributionState.totalAmount
                                          : _parseAmount(_totalController.text);
                                      _showMixedPaymentDialog(min(target, totalGlobalDebt));
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.kPrimaryColor,
                                      side: BorderSide(color: AppColors.kPrimaryColor.withValues(alpha: 0.45)),
                                    ),
                                    icon: const Icon(Icons.call_split_rounded, size: 17),
                                    label: Text(
                                      _mixedPayments.isEmpty ? 'Pago Mixto / Dividir' : 'Editar Pago Mixto (${_mixedPayments.length})',
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  if (_mixedPayments.isNotEmpty) ...[
                                    const Gap(8),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.kPrimary50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          _mixedPayments
                                              .map((p) => '${p.paymentMethodName ?? 'Pago'}: \$${p.amount.toStringAsFixed(2)}')
                                              .join(' + '),
                                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.kPrimaryColor),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const AppText('Distribución de Tickets', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
                const Gap(12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    final isLayaway = sale.status == 'LAYAWAY';

                    final allocatedToThisSale = distributionState.distributions[sale.id] ?? 0.0;
                    final projectedSaleRemaining = sale.pendingBalance - allocatedToThisSale;
                    final hasExtraDetails = sale.items.isNotEmpty || sale.paymentHistory.isNotEmpty;

                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      border: Border.all(
                        color: (allocatedToThisSale > 0 && projectedSaleRemaining <= 0.01) ? AppColors.kSuccess : Colors.transparent,
                        width: 1.5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isLayaway ? Colors.purple.shade50 : Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: AppText(
                                            isLayaway ? 'APARTADO' : 'FIADO',
                                            color: isLayaway ? Colors.purple : Colors.blue,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const Gap(8),
                                        Flexible(
                                          child: AppText(
                                            _formatDate(sale.date),
                                            color: AppColors.kNeutral500,
                                            fontSize: 11,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Gap(6),
                                    AppText(
                                      'Ticket #${sale.id.substring(0, 8).toUpperCase()}',
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.kNeutral900,
                                      fontSize: 13,
                                    ),
                                    const Gap(2),
                                    AppText(
                                      'Total: \$${sale.total.toStringAsFixed(2)}  •  Abonado: \$${sale.paidAmount.toStringAsFixed(2)}',
                                      color: AppColors.kNeutral600,
                                      fontSize: 11.5,
                                    ),
                                    const Gap(4),
                                    Builder(
                                      builder: (context) {
                                        if (allocatedToThisSale <= 0) {
                                          return AppText(
                                            'Resta: \$${sale.pendingBalance.toStringAsFixed(2)}',
                                            color: AppColors.kWarning,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          );
                                        } else if (projectedSaleRemaining <= 0.01) {
                                          return const AppText('Quedará pagada', color: AppColors.kSuccess, fontSize: 12, fontWeight: FontWeight.bold);
                                        } else {
                                          return AppText(
                                            'Restará: \$${projectedSaleRemaining.toStringAsFixed(2)}',
                                            color: AppColors.kPrimaryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const Gap(12),
                              SizedBox(
                                width: 108,
                                child: TextFormField(
                                  controller: _itemControllers[sale.id],
                                  focusNode: _itemFocusNodes[sale.id],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    prefixText: '\$ ',
                                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: AppColors.kPrimaryColor),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    final val = _parseAmount(value);
                                    setState(() => _mixedPayments = []);
                                    distributionNotifier.updateManualDistribution(sale.id, val);
                                  },
                                ),
                              ),
                            ],
                          ),
                          if (hasExtraDetails) ...[
                            const Gap(4),
                            Theme(
                              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                childrenPadding: const EdgeInsets.only(top: 4, bottom: 4),
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                title: AppText(
                                  'Ver artículos (${sale.items.length}) y abonos previos (${sale.paymentHistory.length})',
                                  fontSize: 11.5,
                                  color: AppColors.kPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  if (sale.items.isNotEmpty) ...[
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: AppText('Artículos:', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.kNeutral700),
                                    ),
                                    const Gap(4),
                                    ...sale.items.map((item) {
                                      final qtyStr = item.quantity == item.quantity.toInt()
                                          ? item.quantity.toInt().toString()
                                          : item.quantity.toString();
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: AppText(
                                                '${qtyStr}x ${item.productName}',
                                                fontSize: 11.5,
                                                color: AppColors.kNeutral700,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            AppText(
                                              '\$${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                                              fontSize: 11.5,
                                              color: AppColors.kNeutral700,
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                  if (sale.paymentHistory.isNotEmpty) ...[
                                    if (sale.items.isNotEmpty) const Gap(8),
                                    const Align(
                                      alignment: Alignment.centerLeft,
                                      child: AppText('Abonos previos:', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.kNeutral700),
                                    ),
                                    const Gap(4),
                                    ...sale.paymentHistory.map(
                                      (h) => Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: AppText(
                                                '${DateFormat('dd/MM/yy HH:mm').format(h.date)} • ${h.paymentMethodName}',
                                                fontSize: 11,
                                                color: AppColors.kNeutral600,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            AppText(
                                              '+\$${h.amount.toStringAsFixed(2)}',
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.kSuccess,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // --- BOTÓN REGISTRAR ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || distributionState.totalAmount <= 0) ? null : () => _submitPayment(distributionState),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(
                            'Registrar Abono (\$${distributionState.totalAmount.toStringAsFixed(2)})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentProcessState = ref.watch(processClientPaymentProvider);
    _isSubmitting = paymentProcessState.isLoading;

    ref.listen<AsyncValue<ClientPaymentResponse?>>(processClientPaymentProvider, (previous, next) {
      next.whenOrNull(
        data: (response) {
          if (previous?.isLoading == true && response != null) {
            final paidInCash = response.payments.any((p) => p.paymentMethodCode.toUpperCase() == 'CASH') || response.payments.isEmpty;
            if (paidInCash) {
              unawaited(ref.read(printerServiceProvider).openCashDrawerOnly());
            }

            ref.invalidate(pendingSalesProvider(businessId: widget.businessId, clientId: widget.clientId));
            ref.invalidate(clientsDebtListProvider(widget.businessId));
            ref.invalidate(accountsBusinessProvider(businessId: widget.businessId));
            ref.invalidate(cashShiftsProvider(widget.businessId));
            ref.invalidate(transactionsListProvider);

            _showPaymentReceiptDialog(response);
          }
        },
        error: (error, stackTrace) async {
          if (error is HttpFailure &&
              (error.type == AppFailure.cashShiftRequiredForSale.toCode() ||
                  error.message == AppFailure.cashShiftRequiredForSale.message)) {
            await _showQuickOpenShiftDialog();
            return;
          }
          final message = error is HttpFailure ? error.message : 'Error al procesar el abono';
          SnackbarUtil.showError(context, message);
        },
      );
    });

    // Sincronización reactiva entre campo total y campos individuales
    ref.listen(paymentDistributionProvider(businessId: widget.businessId, clientId: widget.clientId), (prev, next) {
      if (!_totalFocusNode.hasFocus) {
        final currentTotalVal = _parseAmount(_totalController.text);
        if ((currentTotalVal - next.totalAmount).abs() > 0.005) {
          _totalController.text = next.totalAmount > 0 ? next.totalAmount.toStringAsFixed(2) : '';
        }
      }
      for (var sale in next.sales) {
        final val = next.distributions[sale.id] ?? 0.0;
        final ctrl = _itemControllers[sale.id];
        final focus = _itemFocusNodes[sale.id];

        if (ctrl != null && focus != null && !focus.hasFocus) {
          final currentTextVal = _parseAmount(ctrl.text);
          if ((currentTextVal - val).abs() > 0.005) {
            ctrl.text = val > 0 ? val.toStringAsFixed(2) : '';
          }
        }
      }
    });

    return AppScaffold(
      title: 'Abono - ${widget.clientName}',
      appBar: AppBar(
        title: AppText('Abono - ${widget.clientName}', color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
      ),
      mobile: _buildContent(),
      tablet: _buildContent(),
      desktop: _buildContent(),
      marginDesktop: 160,
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: AppText(
              label,
              fontSize: 13,
              color: AppColors.kNeutral700,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Gap(8),
          AppText(
            value,
            fontSize: 13.5,
            color: valueColor ?? AppColors.kNeutral900,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ],
      ),
    );
  }
}
