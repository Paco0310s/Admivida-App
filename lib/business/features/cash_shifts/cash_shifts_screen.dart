import 'package:admivida/business/features/cash_shifts/cash_shifts_provider.dart';
import 'package:admivida/business/features/cash_shifts/cash_shifts_service.dart';
import 'package:admivida/business/features/cash_shifts/models/cash_shift_model.dart';
import 'package:admivida/business/features/transactions/transactions_provider.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class CashShiftsScreen extends ConsumerStatefulWidget {
  final String businessId;
  final String businessName;

  const CashShiftsScreen({super.key, required this.businessId, this.businessName = 'Negocio'});

  @override
  ConsumerState<CashShiftsScreen> createState() => _CashShiftsScreenState();
}

class _CashShiftsScreenState extends ConsumerState<CashShiftsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final NumberFormat _currency = NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 2);
  final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy hh:mm a');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showOpenShiftDialog() async {
    final amountCtrl = TextEditingController(text: '0.00');
    final notesCtrl = TextEditingController();
    String? selectedAccountId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (ctx, dialogRef, _) {
            final accountsAsync = dialogRef.watch(
              accountsBusinessProvider(businessId: widget.businessId),
            );
            return StatefulBuilder(
              builder: (ctx, setDialogState) {
                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Row(
                    children: [
                      Icon(Icons.lock_open_rounded, color: AppColors.kPrimaryColor),
                      Gap(10),
                      Expanded(child: AppText('Abrir Turno de Caja', fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText(
                          'Selecciona la caja/cuenta del turno y registra el dinero físico con el que inicias en el cajón (fondo de caja para dar cambio):',
                          fontSize: 13,
                          color: AppColors.kNeutral600,
                        ),
                        const Gap(14),
                        accountsAsync.when(
                          data: (accounts) {
                            final operationalAccounts = accounts.where((a) => !a.isCreditOrLoan).toList();
                            final selectable = operationalAccounts.isNotEmpty ? operationalAccounts : accounts;
                            if (selectedAccountId == null && selectable.isNotEmpty) {
                              final defaultAcc = selectable.firstWhere(
                                (a) => a.isDefault,
                                orElse: () => selectable.first,
                              );
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
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                items: selectable
                                    .map(
                                      (a) => DropdownMenuItem<String>(
                                        value: a.id,
                                        child: Text(
                                          a.isDefault ? '${a.name} (Principal)' : a.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  setDialogState(() => selectedAccountId = val);
                                },
                              ),
                            );
                          },
                          loading: () => const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: LinearProgressIndicator(),
                          ),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        TextField(
                          controller: amountCtrl,
                          autofocus: true,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Fondo Inicial en Efectivo',
                            prefixText: '\$ ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const Gap(12),
                        TextField(
                          controller: notesCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Observaciones al abrir (opcional)',
                            hintText: 'Ej. Turno matutino',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const AppText('Cancelar', color: AppColors.kNeutral600),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kPrimaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final parsed = double.tryParse(amountCtrl.text.trim());
                        if (parsed == null || parsed < 0) {
                          SnackbarUtil.showWarning(context, 'Ingresa un monto inicial válido mayor o igual a 0.');
                          return;
                        }
                        Navigator.of(dialogContext).pop();
                        final error = await ref
                            .read(cashShiftsProvider(widget.businessId).notifier)
                            .openShift(
                              openingAmount: parsed,
                              accountId: selectedAccountId,
                              notes: notesCtrl.text.trim(),
                            );
                        if (!mounted) return;
                        if (error != null) {
                          SnackbarUtil.showError(context, error);
                        } else {
                          SnackbarUtil.showSuccess(context, 'Turno de caja abierto correctamente.');
                        }
                      },
                      child: const AppText('Abrir Caja', color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showAddMovementDialog(String initialType) async {
    String selectedType = initialType;
    final amountCtrl = TextEditingController();
    final conceptCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final isIn = selectedType == 'IN';
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(isIn ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded, color: isIn ? AppColors.kSuccess : AppColors.kError),
                  const Gap(10),
                  Expanded(child: AppText(isIn ? 'Entrada de Efectivo' : 'Retiro / Salida de Efectivo', fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Entrada (IN)'),
                            selected: isIn,
                            selectedColor: AppColors.kSuccess.withValues(alpha: 0.18),
                            onSelected: (_) => setDialogState(() => selectedType = 'IN'),
                          ),
                        ),
                        const Gap(8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Salida (OUT)'),
                            selected: !isIn,
                            selectedColor: AppColors.kError.withValues(alpha: 0.18),
                            onSelected: (_) => setDialogState(() => selectedType = 'OUT'),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    TextField(
                      controller: amountCtrl,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Monto en Efectivo',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const Gap(12),
                    TextField(
                      controller: conceptCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Concepto / Motivo obligatorio',
                        hintText: isIn ? 'Ej. Ingreso de cambio adicional' : 'Ej. Pago a proveedor de garrafones de agua',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const AppText('Cancelar', color: AppColors.kNeutral600),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isIn ? AppColors.kSuccess : AppColors.kError,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final parsed = double.tryParse(amountCtrl.text.trim());
                    if (parsed == null || parsed <= 0) {
                      SnackbarUtil.showWarning(context, 'Ingresa un monto mayor a 0.');
                      return;
                    }
                    if (conceptCtrl.text.trim().isEmpty) {
                      SnackbarUtil.showWarning(context, 'Escribe el concepto o motivo del movimiento.');
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                    final error = await ref
                        .read(cashShiftsProvider(widget.businessId).notifier)
                        .addMovement(type: selectedType, amount: parsed, concept: conceptCtrl.text.trim());
                    if (!mounted) return;
                    if (error != null) {
                      SnackbarUtil.showError(context, error);
                    } else {
                      ref.invalidate(transactionsListProvider);
                      ref.invalidate(accountsBusinessProvider(businessId: widget.businessId));
                      SnackbarUtil.showSuccess(context, 'Movimiento registrado en caja y en transacciones.');
                    }
                  },
                  child: const AppText('Registrar', color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCloseShiftDialog(CashShiftModel shift) async {
    final actualCashCtrl = TextEditingController();
    final notesCtrl = TextEditingController(text: shift.notes ?? '');
    bool showBillCounter = false;

    final List<int> denominations = [1000, 500, 200, 100, 50, 20, 10, 5, 2, 1];
    final Map<int, TextEditingController> denomControllers = {for (final d in denominations) d: TextEditingController()};

    void recalculateFromDenominations(StateSetter setDialogState) {
      double sum = 0;
      for (final d in denominations) {
        final count = int.tryParse(denomControllers[d]!.text.trim()) ?? 0;
        if (count > 0) {
          sum += d * count;
        }
      }
      setDialogState(() {
        actualCashCtrl.text = sum.toStringAsFixed(2);
      });
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final typedCash = double.tryParse(actualCashCtrl.text.trim());
            final diff = (!shift.isBlindMode && shift.expectedCash != null && typedCash != null) ? (typedCash - shift.expectedCash!) : null;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.point_of_sale_rounded, color: AppColors.kPrimaryColor),
                  Gap(10),
                  Expanded(child: AppText('Cerrar Turno / Hacer Corte', fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (shift.isBlindMode)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.kPrimaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.kPrimaryColor.withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.shield_outlined, color: AppColors.kPrimaryColor, size: 20),
                              Gap(8),
                              Expanded(
                                child: AppText(
                                  'Corte Ciego: Cuenta físicamente todos los billetes y monedas en tu cajón e ingresa el monto exacto que tienes. El sistema guardará tu conteo automáticamente.',
                                  fontSize: 12,
                                  color: AppColors.kNeutral800,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (shift.expectedCash != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.kNeutral100, borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            children: [
                              _buildSummaryRow('Efectivo Esperado en Caja:', _currency.format(shift.expectedCash), isBold: true),
                              const Gap(4),
                              _buildSummaryRow('Cobrado con Tarjeta:', _currency.format(shift.expectedCard ?? 0)),
                              const Gap(4),
                              _buildSummaryRow('Cobrado por Transferencia:', _currency.format(shift.expectedTransfer ?? 0)),
                            ],
                          ),
                        ),
                      const Gap(16),
                      TextField(
                        controller: actualCashCtrl,
                        autofocus: true,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setDialogState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Efectivo Físico Contado en Caja',
                          hintText: '0.00',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const Gap(8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => setDialogState(() => showBillCounter = !showBillCounter),
                          icon: Icon(showBillCounter ? Icons.expand_less_rounded : Icons.calculate_outlined, size: 18),
                          label: Text(
                            showBillCounter ? 'Ocultar calculadora de billetes' : 'Usar calculadora de billetes y monedas',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      if (showBillCounter) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.kNeutral100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.kNeutral300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppText(
                                'Ingresa cuántos billetes/monedas tienes de cada denominación:',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.kNeutral700,
                              ),
                              const Gap(10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: denominations.map((denom) {
                                  return SizedBox(
                                    width: 115,
                                    child: TextField(
                                      controller: denomControllers[denom],
                                      keyboardType: TextInputType.number,
                                      onChanged: (_) => recalculateFromDenominations(setDialogState),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        labelText: '\$$denom',
                                        hintText: '0',
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const Gap(10),
                      ],
                      if (diff != null) ...[
                        const Gap(6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: diff.abs() < 0.01
                                ? AppColors.kSuccess.withValues(alpha: 0.12)
                                : (diff > 0 ? Colors.blue.withValues(alpha: 0.12) : AppColors.kError.withValues(alpha: 0.12)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText(
                                diff.abs() < 0.01 ? 'Caja Cuadrada:' : (diff > 0 ? 'Sobrante en Caja:' : 'Faltante en Caja:'),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: diff.abs() < 0.01 ? AppColors.kSuccess : (diff > 0 ? Colors.blue : AppColors.kError),
                              ),
                              AppText(
                                '${diff > 0 ? '+' : ''}${_currency.format(diff)}',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: diff.abs() < 0.01 ? AppColors.kSuccess : (diff > 0 ? Colors.blue : AppColors.kError),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Gap(12),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Observaciones al cerrar (opcional)',
                          hintText: 'Notas o comentarios del turno',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const AppText('Cancelar', color: AppColors.kNeutral600),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kPrimaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final parsed = double.tryParse(actualCashCtrl.text.trim());
                    if (parsed == null || parsed < 0) {
                      SnackbarUtil.showWarning(context, 'Ingresa el efectivo físico contado (mayor o igual a 0).');
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                    final error = await ref
                        .read(cashShiftsProvider(widget.businessId).notifier)
                        .closeShift(actualCash: parsed, notes: notesCtrl.text.trim(), targetShiftId: shift.id);
                    if (!mounted) return;
                    if (error != null) {
                      SnackbarUtil.showError(context, error);
                    } else {
                      SnackbarUtil.showSuccess(context, 'Corte de caja cerrado y guardado exitosamente.');
                      _tabController.animateTo(1);
                    }
                  },
                  child: const AppText('Confirmar Cierre', color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showShiftDetailModal(CashShiftModel initialShift) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return FutureBuilder(
          future: CashShiftsService.getShiftDetail(initialShift.id),
          builder: (context, snapshot) {
            CashShiftModel shift = initialShift;
            final isLoadingDetail = snapshot.connectionState == ConnectionState.waiting;
            if (snapshot.hasData) {
              snapshot.data!.when((_) {}, (detailedShift) => shift = detailedShift);
            }

            final diff = shift.difference ?? 0.0;
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.82,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (_, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(color: AppColors.kNeutral300, borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const Gap(16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const AppText('Detalle de Corte de Caja', fontSize: 20, fontWeight: FontWeight.bold),
                        _buildStatusBadge(shift.status),
                      ],
                    ),
                    const Gap(6),
                    AppText('Cajero: ${shift.cashierName ?? 'Usuario'}', fontSize: 14, color: AppColors.kNeutral600),
                    if (shift.accountName != null)
                      AppText('Caja / Cuenta: ${shift.accountName}', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.kPrimaryColor),
                    AppText('Apertura: ${_dateTimeFormat.format(shift.openedAt)}', fontSize: 13, color: AppColors.kNeutral600),
                    if (shift.closedAt != null) AppText('Cierre: ${_dateTimeFormat.format(shift.closedAt!)}', fontSize: 13, color: AppColors.kNeutral600),
                    const Gap(16),
                    if (shift.isBlindMode)
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSummaryRow('Fondo Inicial:', _currency.format(shift.openingAmount)),
                            const Divider(height: 20),
                            _buildSummaryRow('(+) Entradas Manuales (IN):', _currency.format(shift.manualIn)),
                            const Gap(6),
                            _buildSummaryRow('(-) Salidas Manuales (OUT):', _currency.format(shift.manualOut)),
                            const Gap(6),
                            _buildSummaryRow('Ventas Registradas en el Turno:', '${shift.salesCount}'),
                            if (shift.actualCash != null) ...[
                              const Divider(height: 20),
                              _buildSummaryRow('Efectivo Físico Declarado al Cerrar:', _currency.format(shift.actualCash), isBold: true),
                            ],
                          ],
                        ),
                      )
                    else ...[
                      // 1. FINANCIAL SUMMARY FOR OWNER/ADMIN
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSummaryRow('Fondo Inicial:', _currency.format(shift.openingAmount)),
                            const Divider(height: 18),
                            _buildSummaryRow('(+) Ventas en Efectivo (${shift.salesCount} ventas totales):', _currency.format(shift.cashSales ?? 0)),
                            const Gap(6),
                            _buildSummaryRow('(+) Entradas Manuales (IN):', _currency.format(shift.manualIn)),
                            const Gap(6),
                            _buildSummaryRow('(-) Salidas Manuales (OUT):', _currency.format(shift.manualOut)),
                            const Divider(height: 18),
                            _buildSummaryRow('Efectivo Esperado en Caja:', _currency.format(shift.expectedCash ?? 0), isBold: true),
                            if (shift.actualCash != null) ...[
                              const Gap(6),
                              _buildSummaryRow('Efectivo Físico Contado por Cajero:', _currency.format(shift.actualCash), isBold: true),
                              const Gap(8),
                              _buildSummaryRow(
                                'Diferencia (Contado - Esperado):',
                                '${diff > 0 ? '+' : ''}${_currency.format(diff)}',
                                isBold: true,
                                valueColor: diff.abs() < 0.01 ? AppColors.kSuccess : (diff > 0 ? Colors.blue : AppColors.kError),
                              ),
                            ],
                            const Divider(height: 18),
                            _buildSummaryRow('Total Cobrado con Tarjeta:', _currency.format(shift.expectedCard ?? 0)),
                            const Gap(6),
                            _buildSummaryRow('Total Cobrado por Transferencia:', _currency.format(shift.expectedTransfer ?? 0)),
                            const Gap(8),
                            _buildSummaryRow(
                              'Total General Vendido en el Turno:',
                              _currency.format((shift.cashSales ?? 0) + (shift.expectedCard ?? 0) + (shift.expectedTransfer ?? 0)),
                              isBold: true,
                              valueColor: AppColors.kPrimaryColor,
                            ),
                          ],
                        ),
                      ),
                      const Gap(16),
                      // 2. ANTI-FRAUD AUDIT PANEL FOR OWNER/ADMIN
                      _buildOwnerAuditCard(shift),
                    ],
                    if (shift.isOpen) ...[
                      const Gap(14),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.kPrimaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _showCloseShiftDialog(shift);
                          },
                          icon: const Icon(Icons.lock_outline_rounded, color: Colors.white),
                          label: const AppText('Hacer Corte / Cerrar Este Turno', color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    if (shift.notes != null && shift.notes!.isNotEmpty) ...[
                      const Gap(14),
                      AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText('Observaciones del Cajero', fontWeight: FontWeight.bold, fontSize: 14),
                            const Gap(4),
                            AppText(shift.notes!, fontSize: 13, color: AppColors.kNeutral700),
                          ],
                        ),
                      ),
                    ],
                    const Gap(18),
                    const AppText('Movimientos Manuales de Efectivo', fontSize: 16, fontWeight: FontWeight.bold),
                    const Gap(8),
                    if (shift.movements.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: AppText('No se registraron entradas ni salidas manuales en este turno.', color: AppColors.kNeutral600, fontSize: 13),
                      )
                    else
                      ...shift.movements.map(_buildMovementTile),
                    if (!shift.isBlindMode) ...[
                      const Gap(18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const AppText('Tickets / Ventas del Turno', fontSize: 16, fontWeight: FontWeight.bold),
                          if (isLoadingDetail) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        ],
                      ),
                      const Gap(8),
                      if (shift.sales.isEmpty && !isLoadingDetail)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: AppText('No hay ventas registradas en este turno.', color: AppColors.kNeutral600, fontSize: 13),
                        )
                      else
                        ...shift.sales.map(_buildShiftSaleTile),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOwnerAuditCard(CashShiftModel shift) {
    final discountCount = shift.discountSalesCount ?? 0;
    final discountTotal = shift.discountTotal ?? 0.0;
    final cancelledCount = shift.cancelledSalesCount ?? 0;
    final cancelledTotal = shift.cancelledSalesTotal ?? 0.0;
    final prevCash = shift.previousShiftActualCash;
    final openDiff = shift.openingDiscrepancy;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: shift.hasAuditAlerts ? Colors.orange.withValues(alpha: 0.07) : AppColors.kSuccess.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: shift.hasAuditAlerts ? Colors.orange.withValues(alpha: 0.35) : AppColors.kSuccess.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                shift.hasAuditAlerts ? Icons.policy_rounded : Icons.verified_user_rounded,
                color: shift.hasAuditAlerts ? Colors.deepOrange : AppColors.kSuccess,
                size: 20,
              ),
              const Gap(8),
              const Expanded(child: AppText('Auditoría de Seguridad (Solo Administrador)', fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const Gap(12),
          // 1. Opening continuity vs previous shift
          if (prevCash != null && openDiff != null) ...[
            _buildAuditAlertRow(
              icon: openDiff.abs() < 0.01 ? Icons.check_circle_outline : Icons.warning_amber_rounded,
              color: openDiff.abs() < 0.01 ? AppColors.kSuccess : AppColors.kError,
              title: 'Continuidad de Fondo de Caja:',
              value: openDiff.abs() < 0.01
                  ? 'Coincide con corte anterior (${_currency.format(prevCash)})'
                  : 'Corte anterior dejó ${_currency.format(prevCash)} (${openDiff > 0 ? '+' : ''}${_currency.format(openDiff)})',
            ),
            const Gap(8),
          ],
          // 2. Discounts applied
          _buildAuditAlertRow(
            icon: discountTotal > 0 ? Icons.local_offer_rounded : Icons.check_circle_outline,
            color: discountTotal > 0 ? Colors.deepOrange : AppColors.kNeutral600,
            title: 'Descuentos otorgados ($discountCount ventas):',
            value: _currency.format(discountTotal),
          ),
          const Gap(8),
          // 3. Cancelled sales
          _buildAuditAlertRow(
            icon: cancelledCount > 0 ? Icons.cancel_outlined : Icons.check_circle_outline,
            color: cancelledCount > 0 ? AppColors.kError : AppColors.kNeutral600,
            title: 'Ventas canceladas ($cancelledCount tickets):',
            value: _currency.format(cancelledTotal),
          ),
          const Gap(8),
          // 4. Manual cash withdrawals
          _buildAuditAlertRow(
            icon: shift.manualOut > 0 ? Icons.money_off_csred_rounded : Icons.check_circle_outline,
            color: shift.manualOut > 0 ? Colors.deepOrange : AppColors.kNeutral600,
            title: 'Retiros manuales de caja (OUT):',
            value: _currency.format(shift.manualOut),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditAlertRow({required IconData icon, required Color color, required String title, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: color),
        const Gap(6),
        Expanded(child: AppText(title, fontSize: 12, color: AppColors.kNeutral800)),
        const Gap(8),
        Flexible(
          child: AppText(value, fontSize: 12, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildShiftSaleTile(CashShiftSaleItemModel sale) {
    final isCancelled = sale.isCancelled;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Icon(isCancelled ? Icons.cancel_rounded : Icons.receipt_long_rounded, color: isCancelled ? AppColors.kError : AppColors.kPrimaryColor, size: 20),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(child: AppText(sale.clientName, fontWeight: FontWeight.w600, fontSize: 13)),
                      if (isCancelled) ...[
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.kError.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                          child: const AppText('CANCELADA', fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.kError),
                        ),
                      ],
                    ],
                  ),
                  const Gap(2),
                  AppText(
                    '${_dateTimeFormat.format(sale.soldAt)} • ${sale.paymentMethodName}${sale.discountAmount > 0 ? ' • Desc: ${_currency.format(sale.discountAmount)}' : ''}',
                    fontSize: 11,
                    color: AppColors.kNeutral600,
                  ),
                ],
              ),
            ),
            AppText(_currency.format(sale.total), fontWeight: FontWeight.bold, fontSize: 14, color: isCancelled ? AppColors.kError : AppColors.kNeutral900),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cashShiftsProvider(widget.businessId));

    return AppScaffold(
      title: 'Cortes de Caja',
      isLoading: state.isLoading && state.activeShift == null && state.history.isEmpty,
      appBar: AppBar(
        title: const AppText('Cortes de Caja', color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(cashShiftsProvider(widget.businessId).notifier).loadAll(),
          ),
        ],
      ),
      mobile: _buildBody(state, isDesktop: false),
      tablet: _buildBody(state, isDesktop: true),
      desktop: _buildBody(state, isDesktop: true),
    );
  }

  Widget _buildBody(CashShiftsState state, {required bool isDesktop}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(isDesktop ? 24 : 16, isDesktop ? 20 : 14, isDesktop ? 24 : 16, 4),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.kNeutral200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabPill(
                    index: 0,
                    icon: Icons.point_of_sale_rounded,
                    label: 'Turno Actual',
                  ),
                ),
                const Gap(6),
                Expanded(
                  child: _buildTabPill(
                    index: 1,
                    icon: Icons.history_rounded,
                    label: 'Historial de Cortes',
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildActiveShiftTab(state),
              _buildHistoryTab(state),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabPill({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _tabController.index == index;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _tabController.animateTo(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.kPrimaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.kNeutral600,
            ),
            const Gap(8),
            Flexible(
              child: AppText(
                label,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.kNeutral700,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveShiftTab(CashShiftsState state) {
    final shift = state.activeShift;

    if (shift == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: AppColors.kPrimaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.lock_clock_rounded, size: 48, color: AppColors.kPrimaryColor),
                ),
                const Gap(16),
                const AppText('No tienes un turno de caja abierto', fontSize: 19, fontWeight: FontWeight.bold),
                const Gap(8),
                const AppText(
                  'Es obligatorio abrir tu turno de caja con el fondo inicial antes de cobrar ventas en el Punto de Venta.',
                  fontSize: 14,
                  color: AppColors.kNeutral600,
                ),
                const Gap(24),
                SizedBox(
                  width: 240,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kPrimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: state.isSubmitting ? null : _showOpenShiftDialog,
                    icon: const Icon(Icons.lock_open_rounded, color: Colors.white),
                    label: const AppText('Abrir Turno de Caja', color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(cashShiftsProvider(widget.businessId).notifier).loadAll(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card (Blind Mode for Seller vs Full Mode for Admin)
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: AppColors.kSuccess.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.storefront_rounded, color: AppColors.kSuccess),
                        ),
                        const Gap(12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              shift.accountName != null ? 'Caja Abierta • ${shift.accountName}' : 'Caja Abierta',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            AppText('Desde: ${_dateTimeFormat.format(shift.openedAt)}', fontSize: 12, color: AppColors.kNeutral600),
                          ],
                        ),
                      ],
                    ),
                    _buildStatusBadge(shift.status),
                  ],
                ),
                const Gap(20),
                if (shift.isBlindMode)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.kPrimaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.kPrimaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.visibility_off_outlined, color: AppColors.kPrimaryColor, size: 20),
                            Gap(8),
                            AppText('Turno Activo • Modalidad Corte Ciego', fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.kPrimaryColor),
                          ],
                        ),
                        const Gap(6),
                        AppText(
                          'Ventas registradas en tu turno: ${shift.salesCount}. Al terminar tu jornada, presiona "Hacer Corte / Cerrar Caja" e ingresa el efectivo físico contado.',
                          fontSize: 12,
                          color: AppColors.kNeutral700,
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF163542),
                          AppColors.kPrimaryColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AppText('Efectivo Esperado en Caja (Vista Administrador)', color: AppColors.kPrimary100, fontSize: 12, fontWeight: FontWeight.w600),
                        const Gap(4),
                        AppText(_currency.format(shift.expectedCash ?? 0), color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        const Gap(4),
                        AppText('${shift.salesCount} ventas registradas en este turno', color: Colors.white70, fontSize: 12),
                      ],
                    ),
                  ),
                const Gap(16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildMetricTile(
                      label: 'Fondo Inicial',
                      value: _currency.format(shift.openingAmount),
                      icon: Icons.savings_outlined,
                      color: AppColors.kPrimaryColor,
                    ),
                    if (!shift.isBlindMode) ...[
                      _buildMetricTile(
                        label: 'Ventas Efectivo',
                        value: _currency.format(shift.cashSales ?? 0),
                        icon: Icons.payments_outlined,
                        color: AppColors.kSuccess,
                      ),
                      _buildMetricTile(
                        label: 'Ventas Tarjeta',
                        value: _currency.format(shift.cardSales ?? 0),
                        icon: Icons.credit_card_rounded,
                        color: Colors.indigo,
                      ),
                      _buildMetricTile(
                        label: 'Transferencias',
                        value: _currency.format(shift.transferSales ?? 0),
                        icon: Icons.account_balance_rounded,
                        color: Colors.teal,
                      ),
                    ],
                    _buildMetricTile(
                      label: 'Entradas Manuales (+)',
                      value: _currency.format(shift.manualIn),
                      icon: Icons.arrow_downward_rounded,
                      color: AppColors.kSuccess,
                    ),
                    _buildMetricTile(
                      label: 'Salidas Manuales (-)',
                      value: _currency.format(shift.manualOut),
                      icon: Icons.arrow_upward_rounded,
                      color: AppColors.kError,
                    ),
                  ],
                ),
                if (!shift.isBlindMode) ...[const Gap(16), _buildOwnerAuditCard(shift)],
                const Gap(20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.kSuccess,
                          side: const BorderSide(color: AppColors.kSuccess),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: state.isSubmitting ? null : () => _showAddMovementDialog('IN'),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const Text('Entrada Efectivo'),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.kError,
                          side: const BorderSide(color: AppColors.kError),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: state.isSubmitting ? null : () => _showAddMovementDialog('OUT'),
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        label: const Text('Retiro / Gasto'),
                      ),
                    ),
                  ],
                ),
                const Gap(12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kPrimaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: state.isSubmitting ? null : () => _showCloseShiftDialog(shift),
                    icon: const Icon(Icons.lock_outline_rounded, color: Colors.white),
                    label: const AppText('Hacer Corte / Cerrar Caja', color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Gap(20),
          const AppText('Movimientos Manuales del Turno', fontSize: 16, fontWeight: FontWeight.bold),
          const Gap(10),
          if (shift.movements.isEmpty)
            AppCard(
              padding: const EdgeInsets.all(20),
              child: const Center(
                child: AppText('Aún no hay entradas ni retiros manuales registrados en este turno.', color: AppColors.kNeutral600, fontSize: 13),
              ),
            )
          else
            ...shift.movements.map(_buildMovementTile),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(CashShiftsState state) {
    if (state.history.isEmpty && !state.isLoading) {
      return const Center(child: AppText('Aún no hay cortes de caja registrados.', color: AppColors.kNeutral600, fontSize: 15));
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(cashShiftsProvider(widget.businessId).notifier).loadAll(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.history.length,
        separatorBuilder: (_, _) => const Gap(10),
        itemBuilder: (context, index) {
          final shift = state.history[index];
          final diff = shift.difference ?? 0.0;

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showShiftDetailModal(shift),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: AppText(
                          shift.accountName != null
                              ? '${shift.cashierName ?? 'Cajero'} • ${shift.accountName}'
                              : (shift.cashierName ?? 'Cajero'),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (!shift.isBlindMode && shift.hasAuditAlerts) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning_amber_rounded, size: 13, color: Colors.deepOrange),
                              Gap(4),
                              AppText('Auditoría', fontSize: 11, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                            ],
                          ),
                        ),
                        const Gap(6),
                      ],
                      _buildStatusBadge(shift.status),
                    ],
                  ),
                  const Gap(4),
                  AppText(
                    'Apertura: ${_dateTimeFormat.format(shift.openedAt)}'
                    '${shift.closedAt != null ? '  •  Cierre: ${_dateTimeFormat.format(shift.closedAt!)}' : ''}',
                    fontSize: 12,
                    color: AppColors.kNeutral600,
                  ),
                  const Divider(height: 20),
                  if (shift.isBlindMode)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCompactStat('Fondo Inicial', _currency.format(shift.openingAmount)),
                        _buildCompactStat('Ventas', '${shift.salesCount}'),
                        _buildCompactStat('Efectivo Declarado', shift.actualCash != null ? _currency.format(shift.actualCash) : 'En curso'),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCompactStat('Esperado', _currency.format(shift.expectedCash ?? 0)),
                        _buildCompactStat('Contado', shift.actualCash != null ? _currency.format(shift.actualCash) : '—'),
                        _buildCompactStat(
                          'Diferencia',
                          shift.difference != null ? '${diff > 0 ? '+' : ''}${_currency.format(diff)}' : '—',
                          valueColor: shift.difference == null
                              ? AppColors.kNeutral600
                              : (diff.abs() < 0.01 ? AppColors.kSuccess : (diff > 0 ? Colors.blue : AppColors.kError)),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricTile({required String label, required String value, required IconData icon, required Color color}) {
    return Container(
      width: 155,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.kNeutral100, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const Gap(6),
          AppText(label, fontSize: 11, color: AppColors.kNeutral600),
          const Gap(2),
          AppText(value, fontSize: 15, fontWeight: FontWeight.bold),
        ],
      ),
    );
  }

  Widget _buildMovementTile(CashMovementModel movement) {
    final isIn = movement.isIn;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: (isIn ? AppColors.kSuccess : AppColors.kError).withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, size: 18, color: isIn ? AppColors.kSuccess : AppColors.kError),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isIn ? AppColors.kSuccess : AppColors.kError).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: AppText(
                          isIn ? 'ENTRADA MANUAL' : 'RETIRO DE CAJA',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isIn ? AppColors.kSuccess : AppColors.kError,
                        ),
                      ),
                      const Gap(6),
                      Flexible(child: AppText(movement.concept, fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                  const Gap(2),
                  AppText(_dateTimeFormat.format(movement.createdAt), fontSize: 11, color: AppColors.kNeutral600),
                ],
              ),
            ),
            AppText(
              '${isIn ? '+' : '-'}${_currency.format(movement.amount)}',
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isIn ? AppColors.kSuccess : AppColors.kError,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final isOpen = status.toUpperCase() == 'OPEN';
    final color = isOpen ? AppColors.kSuccess : AppColors.kNeutral600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
      child: AppText(isOpen ? 'ABIERTO' : 'CERRADO', fontSize: 11, fontWeight: FontWeight.bold, color: color),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: AppText(label, fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: AppColors.kNeutral700),
        ),
        const Gap(8),
        AppText(value, fontSize: isBold ? 15 : 13, fontWeight: isBold ? FontWeight.bold : FontWeight.w600, color: valueColor ?? AppColors.kNeutral900),
      ],
    );
  }

  Widget _buildCompactStat(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(label, fontSize: 11, color: AppColors.kNeutral600),
        const Gap(2),
        AppText(value, fontSize: 14, fontWeight: FontWeight.bold, color: valueColor ?? AppColors.kNeutral900),
      ],
    );
  }
}
