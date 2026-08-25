import 'package:admivida/business/features/add_transaction/add_transactions_provider.dart';
import 'package:admivida/business/features/add_transaction/models/create_transaction_dto.dart';
import 'package:admivida/business/features/transactions/transactions_provider.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/errors/http_failure.dart';
// import 'package:admivida/common/constants/app_texts.dart'; // Si tienes textos definidos agrégalos aquí
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String businessId;

  const AddTransactionScreen({super.key, required this.businessId});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedType = 'INCOME'; // Default to 'INCOME', can be toggled to 'EXPENSE'
  String? _selectedAccountId;
  String? _selectedPaymentMethodId;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    // 1. Validate the form fields
    if (!_formKey.currentState!.validate()) return;

    // 2. Check if account and payment method are selected
    if (_selectedAccountId == null) {
      SnackbarUtil.showWarning(context, 'Por favor selecciona una cuenta');
      return;
    }

    if (_selectedPaymentMethodId == null) {
      SnackbarUtil.showWarning(context, 'Por favor selecciona un método de pago');
      return;
    }

    // 3. Create the DTO
    final dto = CreateTransactionDto(
      type: _selectedType, // 'INCOME' or 'EXPENSE'
      amount: double.parse(_amountController.text.trim()),
      description: _descriptionController.text.trim(),
      paymentMethodId: _selectedPaymentMethodId!,
      accountId: _selectedAccountId!,
      businessId: widget.businessId,
      saleId: null,
    );

    // 4. Call the provider to submit the transaction
    ref.read(addTransactionProvider.notifier).submit(dto);
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
            const AppText('Nuevo Movimiento', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
            const Gap(8),
            AppText('Registra un ingreso o gasto de forma manual especificando la cuenta y el método de pago.', color: AppColors.kNeutral600),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isLoading) {
    final accountsAsync = ref.watch(accountsProvider(businessId: widget.businessId));
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

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
                  // --- TIPO DE Movimiento (Dropdown) ---
                  DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Movimiento *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: Icon(
                        _selectedType == 'INCOME' ? Icons.arrow_downward : Icons.arrow_upward,
                        color: _selectedType == 'INCOME' ? Colors.green : Colors.red,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'INCOME',
                        child: Text(
                          'Entrada de dinero (Ingreso)',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'EXPENSE',
                        child: Text(
                          'Salida de dinero (Gasto)',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedType = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- MONTO ---
                  AppTextField(
                    text: 'Monto del Movimiento *',
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
                    text: 'Descripción / Motivo *',
                    hintText: 'Ej. Compra de bolsas, Pago de luz...',
                    controller: _descriptionController,
                    isRequired: true,
                    maxLines: 2,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'La descripción es requerida' : null,
                  ),
                  const SizedBox(height: 16),

                  // --- CUENTA (Dropdown Mock) ---
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
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedAccountId,
                        decoration: InputDecoration(
                          labelText: 'Cuenta de origen/destino *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.account_balance_wallet, color: AppColors.kPrimaryColor),
                        ),
                        items: accounts.map((acc) {
                          return DropdownMenuItem<String>(value: acc.id, child: Text(acc.name));
                        }).toList(),
                        validator: (val) => val == null ? 'Selecciona una cuenta' : null,
                        onChanged: (value) => setState(() => _selectedAccountId = value),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- MÉTODO DE PAGO (Dropdown Mock) ---
                  paymentMethodsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, stack) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('Error al cargar métodos de pago: $err', style: const TextStyle(color: Colors.red)),
                    ),
                    data: (methods) {
                      return DropdownButtonFormField<String>(
                        initialValue: _selectedPaymentMethodId,
                        decoration: InputDecoration(
                          labelText: 'Método de Pago *',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.payment, color: AppColors.kPrimaryColor),
                        ),
                        items: methods.map((method) {
                          return DropdownMenuItem<String>(value: method.id, child: Text(method.name));
                        }).toList(),
                        validator: (val) => val == null ? 'Selecciona un método de pago' : null,
                        onChanged: (value) => setState(() => _selectedPaymentMethodId = value),
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
                    : const Text('Registrar Movimiento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to the state of the addTransactionProvider to show loading, success, or error messages
    final addTransactionState = ref.watch(addTransactionProvider);
    final isLoading = addTransactionState.isLoading;

    // Update the _isSubmitting state based on the provider's state
    ref.listen(addTransactionProvider, (previous, next) {
      next.whenOrNull(
        data: (transaction) {
          if (transaction != null) {
            SnackbarUtil.showSuccess(context, 'Movimiento registrado correctamente');

            ref.invalidate(transactionsListProvider(widget.businessId, null)); // Refresh the transactions list for the current business

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
      title: 'Agregar Movimiento',
      appBar: AppBar(
        title: const AppText('Agregar Movimiento', color: AppColors.kNeutral100),
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
