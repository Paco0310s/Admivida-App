import 'package:admivida/business/features/add_transaction/add_transactions_provider.dart';
import 'package:admivida/business/features/add_transaction/models/transfer_funds_dto.dart';
import 'package:admivida/business/features/transactions/transactions_provider.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class TransferFundsScreen extends ConsumerStatefulWidget {
  final String businessId;

  const TransferFundsScreen({super.key, required this.businessId});

  @override
  ConsumerState<TransferFundsScreen> createState() => _TransferFundsScreenState();
}

class _TransferFundsScreenState extends ConsumerState<TransferFundsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _sourceAccountId;
  String? _destinationAccountId;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    if (_sourceAccountId == null) {
      SnackbarUtil.showWarning(context, 'Por favor selecciona la cuenta de origen');
      return;
    }

    if (_destinationAccountId == null) {
      SnackbarUtil.showWarning(context, 'Por favor selecciona la cuenta de destino');
      return;
    }

    if (_sourceAccountId == _destinationAccountId) {
      SnackbarUtil.showWarning(context, 'La cuenta de origen y destino no pueden ser la misma');
      return;
    }

    final dto = TransferFundsDto(
      amount: double.parse(_amountController.text.trim()),
      description: _descriptionController.text.trim(),
      fromAccountId: _sourceAccountId!,
      toAccountId: _destinationAccountId!,
      businessId: widget.businessId,
    );

    ref.read(transferFundsProvider.notifier).submit(dto);
  }

  Widget _buildHeaderCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText('Transferencia entre Cuentas', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
            const Gap(8),
            AppText('Mueve dinero de una cuenta a otra dentro del mismo negocio. Esto mantendrá los saldos actualizados.', color: AppColors.kNeutral600),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isLoading) {
    // Usamos el mismo provider para obtener todas las cuentas disponibles
    final accountsAsync = ref.watch(accountsBusinessProvider(businessId: widget.businessId));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- MONTO ---
                  AppTextField(
                    text: 'Monto a transferir *',
                    hintText: '\$ 0.00',
                    controller: _amountController,
                    isRequired: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return 'El monto es requerido';
                      final amount = double.tryParse(value.trim());
                      if (amount == null) return 'Ingresa una cantidad válida';
                      if (amount <= 0) return 'El monto debe ser mayor a cero';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- DESCRIPCIÓN ---
                  AppTextField(
                    text: 'Concepto / Referencia *',
                    hintText: 'Ej. Reposición de caja chica, Ahorro...',
                    controller: _descriptionController,
                    isRequired: true,
                    maxLines: 2,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'El concepto es requerido' : null,
                  ),
                  const SizedBox(height: 16),

                  // --- SELECTORES DE CUENTAS ---
                  accountsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, stack) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('Error al cargar cuentas: $err', style: const TextStyle(color: Colors.red)),
                    ),
                    data: (accounts) {
                      return Column(
                        children: [
                          // CUENTA DE ORIGEN
                          DropdownButtonFormField<String>(
                            initialValue: _sourceAccountId,
                            decoration: InputDecoration(
                              labelText: 'Cuenta de origen (Retirar de) *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(Icons.arrow_upward, color: Colors.red),
                            ),
                            items: accounts.map((acc) {
                              return DropdownMenuItem<String>(value: acc.id, child: Text(acc.name));
                            }).toList(),
                            validator: (val) => val == null ? 'Selecciona una cuenta de origen' : null,
                            onChanged: (value) => setState(() => _sourceAccountId = value),
                          ),
                          const SizedBox(height: 16),

                          // CUENTA DE DESTINO
                          DropdownButtonFormField<String>(
                            initialValue: _destinationAccountId,
                            decoration: InputDecoration(
                              labelText: 'Cuenta de destino (Depositar a) *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              prefixIcon: const Icon(Icons.arrow_downward, color: Colors.green),
                            ),
                            items: accounts.map((acc) {
                              // Deshabilita la opción si es la misma que la cuenta de origen
                              final isSameAsSource = acc.id == _sourceAccountId;
                              return DropdownMenuItem<String>(
                                value: acc.id,
                                enabled: !isSameAsSource,
                                child: Text(acc.name, style: TextStyle(color: isSameAsSource ? Colors.grey : null)),
                              );
                            }).toList(),
                            validator: (val) {
                              if (val == null) return 'Selecciona una cuenta de destino';
                              if (val == _sourceAccountId) return 'No puedes transferir a la misma cuenta';
                              return null;
                            },
                            onChanged: (value) => setState(() => _destinationAccountId = value),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- BOTÓN GUARDAR ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text(
                        'Confirmar Transferencia',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escucha el estado del provider (necesitarás crear transferFundsProvider)
    final transferState = ref.watch(transferFundsProvider);
    final isLoading = transferState.isLoading;

    ref.listen(transferFundsProvider, (previous, next) {
      next.whenOrNull(
        data: (result) {
          if (result != null) {
            SnackbarUtil.showSuccess(context, 'Transferencia completada correctamente');
            ref.invalidate(transactionsListProvider(widget.businessId, null));
            NavigationService.pop(context);
          }
        },
        error: (error, stackTrace) {
          final message = error is HttpFailure ? error.message : 'Error inesperado';
          SnackbarUtil.showError(context, message);
        },
      );
    });

    return AppScaffold(
      title: 'Transferir Fondos',
      appBar: AppBar(
        title: const AppText('Transferir Fondos', color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
      ),
      mobile: _buildContent(isLoading),
      tablet: _buildContent(isLoading),
      desktop: _buildContent(isLoading),
      marginDesktop: 160,
    );
  }
}
