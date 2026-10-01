import 'dart:math';

import 'package:admivida/business/features/add_transaction/add_transactions_provider.dart';
import 'package:admivida/business/features/clients/clients_provider.dart';
import 'package:admivida/business/features/transactions/transactions_provider.dart'; // Asumiendo que aquí están accountsBusinessProvider y paymentMethodsProvider
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
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

  void _submitPayment(PaymentDistributionState state) {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccountId == null) {
      SnackbarUtil.showWarning(context, 'Por favor selecciona una cuenta');
      return;
    }

    if (_selectedPaymentMethodId == null) {
      SnackbarUtil.showWarning(context, 'Por favor selecciona un método de pago');
      return;
    }

    // Usamos _totalController en lugar de _amountController
    final textValue = _totalController.text.replaceAll(',', '').trim();
    final visibleAmount = double.tryParse(textValue) ?? 0.0;

    // Calcula lo que el motor logró acomodar
    final distributedSum = state.distributions.values.fold(0.0, (sum, amount) => sum + amount);
    final totalDebt = state.sales.fold(0.0, (sum, sale) => sum + sale.pendingBalance);

    // Compara el valor VISUAL contra la distribución real
    if ((visibleAmount - distributedSum).abs() > 0.01) {
      if (visibleAmount > totalDebt) {
        SnackbarUtil.showError(context, 'El monto ingresado supera la deuda total pendiente de \$${totalDebt.toStringAsFixed(2)}');
      } else {
        SnackbarUtil.showError(context, 'Error de cálculo. Revisa la distribución de los tickets.');
      }
      return;
    }

    final distributionsToSave = state.distributions.entries
        .where((entry) => entry.value > 0)
        .map((entry) => {'saleId': entry.key, 'amount': entry.value})
        .toList();

    if (distributionsToSave.isEmpty || distributedSum <= 0) {
      SnackbarUtil.showWarning(context, 'El monto a abonar debe ser mayor a 0');
      return;
    }

    final payload = {
      "totalAmount": distributedSum,
      "accountId": _selectedAccountId,
      "paymentMethodId": _selectedPaymentMethodId,
      "distributions": distributionsToSave,
    };

    ref.read(processClientPaymentProvider.notifier).submit(businessId: widget.businessId, clientId: widget.clientId, payload: payload);
  }

  Widget _buildHeaderCard(double totalGlobalDebt, double currentPaymentAmount) {
    final projectedRemaining = totalGlobalDebt - currentPaymentAmount;

    return AppCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText('Abono a Cuenta', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
            const Gap(8),
            AppText('Distribuye el pago de forma manual o automática entre los tickets del cliente.', color: AppColors.kNeutral600),
            const Gap(16),
            const Divider(),
            const Gap(8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText('Deuda Pendiente:', color: AppColors.kNeutral700, fontSize: 16, fontWeight: FontWeight.bold),
                AppText('\$${totalGlobalDebt.toStringAsFixed(2)}', color: AppColors.kWarning, fontWeight: FontWeight.bold, fontSize: 20),
              ],
            ),

            // --- NUEVO: FEEDBACK VISUAL GLOBAL ---
            if (currentPaymentAmount > 0) ...[
              const Gap(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText('Proyección:', color: AppColors.kNeutral700, fontSize: 14),
                  Builder(
                    builder: (context) {
                      if (projectedRemaining < 0) {
                        return const AppText('El abono supera la deuda', color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold);
                      } else if (projectedRemaining == 0) {
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

  Widget _buildContent(bool isLoadingAsync) {
    final salesAsync = ref.watch(pendingSalesProvider(businessId: widget.businessId, clientId: widget.clientId));
    final accountsAsync = ref.watch(accountsBusinessProvider(businessId: widget.businessId));
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    final distributionState = ref.watch(paymentDistributionProvider(businessId: widget.businessId, clientId: widget.clientId));
    final distributionNotifier = ref.read(paymentDistributionProvider(businessId: widget.businessId, clientId: widget.clientId).notifier);

    return salesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: AppText('Error: $err', color: Colors.red)),
      data: (sales) {
        if (sales.isEmpty) {
          return Center(child: AppText('Este cliente no tiene deudas pendientes.', color: AppColors.kNeutral600));
        }

        final totalGlobalDebt = sales.fold<double>(0, (sum, item) => sum + item.pendingBalance);

        // Inicializar controladores de la lista
        for (var sale in sales) {
          _itemControllers.putIfAbsent(sale.id, () => TextEditingController());
          _itemFocusNodes.putIfAbsent(sale.id, () => FocusNode());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(totalGlobalDebt, distributionState.totalAmount),

                // --- TARJETA DE CONFIGURACIÓN DEL PAGO ---
                AppCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Monto Total a Abonar
                      TextFormField(
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
                          final val = double.tryParse(value) ?? 0.0;
                          distributionNotifier.distributeTotal(min(val, totalGlobalDebt));
                        },
                      ),
                      const SizedBox(height: 16),

                      // Cuenta Destino
                      accountsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Text('Error al cargar cuentas: $err', style: const TextStyle(color: Colors.red)),
                        data: (accounts) {
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedAccountId,
                            decoration: InputDecoration(
                              labelText: 'Ingresar a Cuenta *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(Icons.account_balance_wallet, color: AppColors.kPrimaryColor),
                            ),
                            items: accounts.map((acc) => DropdownMenuItem<String>(value: acc.id, child: Text(acc.name))).toList(),
                            validator: (val) => val == null ? 'Selecciona una cuenta' : null,
                            onChanged: (value) => setState(() => _selectedAccountId = value),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Método de Pago
                      paymentMethodsAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Text('Error al cargar métodos: $err', style: const TextStyle(color: Colors.red)),
                        data: (methods) {
                          return DropdownButtonFormField<String>(
                            initialValue: _selectedPaymentMethodId,
                            decoration: InputDecoration(
                              labelText: 'Método de Pago *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(Icons.payment, color: AppColors.kPrimaryColor),
                            ),
                            items: methods.map((method) => DropdownMenuItem<String>(value: method.id, child: Text(method.name))).toList(),
                            validator: (val) => val == null ? 'Selecciona un método de pago' : null,
                            onChanged: (value) => setState(() => _selectedPaymentMethodId = value),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                AppText('Distribución de Tickets', fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
                const Gap(12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    final isLayaway = sale.status == 'LAYAWAY';

                    // Calculamos la proyección individual de este ticket
                    final allocatedToThisSale = distributionState.distributions[sale.id] ?? 0.0;
                    final projectedSaleRemaining = sale.pendingBalance - allocatedToThisSale;

                    return AppCard(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      border: Border.all(color: (allocatedToThisSale > 0 && projectedSaleRemaining <= 0) ? AppColors.kSuccess : Colors.transparent, width: 1.5),
                      child: Row(
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
                                    AppText(_formatDate(sale.date), color: AppColors.kNeutral500, fontSize: 11),
                                  ],
                                ),
                                const Gap(6),
                                AppText(
                                  'Ticket #${sale.id.substring(0, 8).toUpperCase()}',
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.kNeutral900,
                                  fontSize: 13,
                                ),
                                const Gap(4),

                                // --- FEEDBACK VISUAL INDIVIDUAL ---
                                Builder(
                                  builder: (context) {
                                    if (allocatedToThisSale <= 0) {
                                      // Estado normal sin cambios
                                      return AppText(
                                        'Resta: \$${sale.pendingBalance.toStringAsFixed(2)}',
                                        color: AppColors.kWarning,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      );
                                    } else if (projectedSaleRemaining <= 0) {
                                      // Se va a liquidar
                                      return const AppText('Quedará pagada', color: AppColors.kSuccess, fontSize: 12, fontWeight: FontWeight.bold);
                                    } else {
                                      // Se abona una parte
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
                          // INPUT INDIVIDUAL
                          SizedBox(
                            width: 100,
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
                                final val = double.tryParse(value) ?? 0.0;
                                distributionNotifier.updateManualDistribution(sale.id, val);
                              },
                            ),
                          ),
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
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    // 1. Obtenemos el estado del proceso de pago
    final paymentProcessState = ref.watch(processClientPaymentProvider);
    _isSubmitting = paymentProcessState.isLoading;

    // 2. Escuchamos el resultado para mostrar mensajes y cerrar la vista
    ref.listen(processClientPaymentProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          if (previous?.isLoading == true) {
            // Aseguramos que venimos de estar cargando
            SnackbarUtil.showSuccess(context, 'Abono registrado correctamente');

            // Invalidamos las listas para que al regresar se vean los saldos actualizados
            ref.invalidate(pendingSalesProvider(businessId: widget.businessId, clientId: widget.clientId));
            ref.invalidate(clientsDebtListProvider(widget.businessId));

            NavigationService.pop(context);
          }
        },
        error: (error, stackTrace) {
          final message = error is HttpFailure ? error.message : 'Error al procesar el abono';
          SnackbarUtil.showError(context, message);
        },
      );
    });

    // Escucha de Sincronización Reactiva
    ref.listen(paymentDistributionProvider(businessId: widget.businessId, clientId: widget.clientId), (prev, next) {
      if (!_totalFocusNode.hasFocus) {
        final currentTotalText = double.tryParse(_totalController.text) ?? 0.0;
        if (currentTotalText != next.totalAmount) {
          _totalController.text = next.totalAmount > 0 ? next.totalAmount.toStringAsFixed(2) : '';
        }
      }
      for (var sale in next.sales) {
        final val = next.distributions[sale.id] ?? 0.0;
        final ctrl = _itemControllers[sale.id];
        final focus = _itemFocusNodes[sale.id];

        if (ctrl != null && focus != null && !focus.hasFocus) {
          final currentTextVal = double.tryParse(ctrl.text) ?? 0.0;
          if (currentTextVal != val) {
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
      mobile: _buildContent(false),
      tablet: _buildContent(false),
      desktop: _buildContent(false),
      marginDesktop: 160,
    );
  }
}
