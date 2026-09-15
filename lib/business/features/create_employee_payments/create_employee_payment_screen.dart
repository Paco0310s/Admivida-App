import 'package:admivida/business/features/add_transaction/add_transactions_provider.dart';
import 'package:admivida/business/features/commission_payments/commission_payment_provider.dart';
import 'package:admivida/business/features/commission_payments/models/business_staff_model.dart';
import 'package:admivida/business/features/create_employee_payments/create_employee_payment_service.dart';
import 'package:admivida/business/features/create_employee_payments/models/create_employee_payment_dto.dart';
import 'package:admivida/business/features/transactions/transactions_provider.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class CreateEmployeePaymentScreen extends ConsumerStatefulWidget {
  const CreateEmployeePaymentScreen({super.key, required this.businessId});

  final String businessId;

  @override
  ConsumerState<CreateEmployeePaymentScreen> createState() => _CreateEmployeePaymentScreenState();
}

class _CreateEmployeePaymentScreenState extends ConsumerState<CreateEmployeePaymentScreen> {
  String? _selectedEmployeeId;
  String? _sourceAccountId;
  String? _destinationAccountId;
  String? _paymentMethodId;
  bool _isSubmitting = false;

  final TextEditingController _amountController = TextEditingController(text: '0.00');
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitPayment() async {
    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      SnackbarUtil.showError(context, 'El monto a pagar debe ser mayor a cero.');
      return;
    }

    if (_selectedEmployeeId == null) {
      SnackbarUtil.showError(context, 'Debe seleccionar al empleado correspondiente.');
      return;
    }

    if (_sourceAccountId == null || _destinationAccountId == null || _paymentMethodId == null) {
      SnackbarUtil.showError(context, 'Complete la configuración financiera (Cuentas y Método de Pago).');
      return;
    }

    setState(() => _isSubmitting = true);

    final dto = CreateEmployeePaymentDto(
      employeeUserId: _selectedEmployeeId!,
      amount: amount,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      sourceAccountId: _sourceAccountId!,
      destinationAccountId: _destinationAccountId!,
      paymentMethodId: _paymentMethodId!,
    );

    final result = await CreateEmployeePaymentService.createEmployeePayment(dto, widget.businessId);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      (failure) {
        SnackbarUtil.showError(context, failure.message);
      },
      (successResponse) {
        SnackbarUtil.showSuccess(context, 'Pago registrado correctamente.');
        Navigator.of(context).pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(businessSellersProvider(widget.businessId)); // O tu provider de empleados del negocio
    final accountsBusinessAsync = ref.watch(accountsBusinessProvider(businessId: widget.businessId));
    final accountsUserAsync = ref.watch(accountsUserProvider(userId: _selectedEmployeeId));
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    return AppScaffold(
      title: 'Registro de Pagos a Empleados',
      appBar: AppBar(
        title: const AppText('Nuevo Pago / Nómina', color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
      ),
      mobile: _buildContent(staffAsync, accountsBusinessAsync, accountsUserAsync, paymentMethodsAsync),
      tablet: _buildContent(staffAsync, accountsBusinessAsync, accountsUserAsync, paymentMethodsAsync),
      desktop: _buildContent(staffAsync, accountsBusinessAsync, accountsUserAsync, paymentMethodsAsync),
      marginDesktop: 160,
    );
  }

  Widget _buildContent(
    AsyncValue<List<BusinessStaffModel>> staffAsync,
    AsyncValue accountsBusinessAsync,
    AsyncValue accountsUserAsync,
    AsyncValue paymentMethodsAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmployeeSelector(staffAsync),
          const Gap(16),
          _buildFinancialConfigCard(accountsBusinessAsync, accountsUserAsync, paymentMethodsAsync),
          const Gap(16),
          _buildSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildEmployeeSelector(AsyncValue<List<BusinessStaffModel>> staffAsync) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('Colaborador / Empleado', fontWeight: FontWeight.bold, fontSize: 16),
          const Gap(12),
          staffAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error al cargar personal: $err'),
            data: (staffList) {
              if (staffList.isEmpty) {
                return const Text('No se encontraron colaboradores registrados.');
              }
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                hint: const Text('Seleccionar miembro del personal...'),
                initialValue: _selectedEmployeeId,
                items: staffList.map((staff) {
                  return DropdownMenuItem<String>(value: staff.userId, child: Text(staff.fullName));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedEmployeeId = val;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialConfigCard(AsyncValue accountsBusinessAsync, AsyncValue accountsUserAsync, AsyncValue paymentMethodsAsync) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('Origen y Destino de Fondos', fontWeight: FontWeight.bold, fontSize: 16),
          const Gap(12),

          // Source Account (Business Expense)
          accountsBusinessAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => Text('Error al cargar cuentas: $e'),
            data: (accounts) {
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Cuenta de Origen (Retiro del Negocio)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                hint: const Text('Seleccionar cuenta...'),
                initialValue: _sourceAccountId,
                items: accounts.map<DropdownMenuItem<String>>((account) {
                  return DropdownMenuItem<String>(value: account.id, child: Text(account.name));
                }).toList(),
                onChanged: (val) => setState(() => _sourceAccountId = val),
              );
            },
          ),
          const Gap(12),

          // Destination Account (Employee Income)
          accountsUserAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, s) => const SizedBox.shrink(),
            data: (accounts) {
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Cuenta de Destino (Abono al Colaborador)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                hint: const Text('Seleccionar cuenta destino...'),
                initialValue: _destinationAccountId,
                items: accounts.map<DropdownMenuItem<String>>((account) {
                  return DropdownMenuItem<String>(value: account.id, child: Text(account.name));
                }).toList(),
                onChanged: (val) => setState(() => _destinationAccountId = val),
              );
            },
          ),
          const Gap(12),

          // Payment Method
          paymentMethodsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, s) => Text('Error al cargar métodos: $e'),
            data: (methods) {
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Método de Operación',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                hint: const Text('Seleccionar método...'),
                initialValue: _paymentMethodId,
                items: methods.map<DropdownMenuItem<String>>((method) {
                  return DropdownMenuItem<String>(value: method.id, child: Text(method.name));
                }).toList(),
                onChanged: (val) => setState(() => _paymentMethodId = val),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('Detalles del Pago', fontWeight: FontWeight.bold, fontSize: 16),
          const Gap(12),
          AppTextField(
            text: 'Monto a Pagar',
            hintText: '0.00',
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: const Icon(Icons.attach_money),
          ),
          const Gap(12),
          AppTextField(text: 'Observaciones / Notas', hintText: 'Ej. Anticipo de nómina o pago quincenal', controller: _notesController),
          const Gap(24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirmar y Registrar Pago', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
