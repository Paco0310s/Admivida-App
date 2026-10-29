import 'package:admivida/business/features/add_transaction/add_transactions_provider.dart';
import 'package:admivida/business/features/add_transaction/models/create_transaction_dto.dart';
import 'package:admivida/business/features/transactions/models/account_model.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/app_text_field.dart';
import 'package:admivida/common/widgets/create_account_dialog.dart';
import 'package:admivida/personal/features/transactions/personal_transactions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class PersonalAddTransactionScreen extends ConsumerStatefulWidget {
  final String? initialAccountId;

  const PersonalAddTransactionScreen({super.key, this.initialAccountId});

  @override
  ConsumerState<PersonalAddTransactionScreen> createState() => _PersonalAddTransactionScreenState();
}

class _PersonalAddTransactionScreenState extends ConsumerState<PersonalAddTransactionScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedType = 'INCOME';
  String? _selectedAccountId;
  String? _selectedPaymentMethodId;

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.initialAccountId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedAccountId == null) {
      SnackbarUtil.showWarning(context, 'Por favor selecciona una cuenta');
      return;
    }

    if (_selectedPaymentMethodId == null) {
      SnackbarUtil.showWarning(context, 'Por favor selecciona un método de pago');
      return;
    }

    final dto = CreateTransactionDto(
      type: _selectedType,
      amount: double.parse(_amountController.text.trim()),
      description: _descriptionController.text.trim(),
      paymentMethodId: _selectedPaymentMethodId!,
      accountId: _selectedAccountId!,
      businessId: null,
      saleId: null,
    );

    ref.read(addTransactionProvider.notifier).submit(dto);
  }

  Widget _buildHeaderCard(bool isCreditAccount) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              isCreditAccount ? 'Movimiento en Tarjeta de Crédito / Préstamo' : 'Nuevo Movimiento Personal',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.kPrimaryColor,
            ),
            const Gap(8),
            AppText(
              isCreditAccount
                  ? 'Registra una compra/cargo (aumenta lo que debes) o un abono/pago directo (reduce tu deuda).'
                  : 'Registra una entrada o salida de dinero en tu efectivo o tarjeta de débito.',
              color: AppColors.kNeutral600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isLoading) {
    final accountsAsync = ref.watch(personalAccountsProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodsProvider);

    final List<AccountModel> loadedAccounts = accountsAsync.value ?? const [];
    final AccountModel? selectedAccount =
        loadedAccounts.where((a) => a.id == _selectedAccountId).firstOrNull;
    final bool isCreditAccount = selectedAccount?.isCreditOrLoan ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(isCreditAccount),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- CUENTA PERSONAL + BOTÓN AGREGAR CUENTA ---
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
                      if (_selectedAccountId == null && accounts.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _selectedAccountId == null) {
                            final firstAcc = accounts.first;
                            setState(() {
                              _selectedAccountId = firstAcc.id;
                              if (firstAcc.isCreditOrLoan) {
                                _selectedType = 'EXPENSE';
                              }
                            });
                          }
                        });
                      }
                      final validSelectedId = accounts.any((a) => a.id == _selectedAccountId) ? _selectedAccountId : null;

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              key: ValueKey(validSelectedId),
                              initialValue: validSelectedId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Cuenta o tarjeta *',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                prefixIcon: Icon(
                                  isCreditAccount ? Icons.credit_score_rounded : Icons.account_balance_wallet,
                                  color: isCreditAccount ? AppColors.kWarning : AppColors.kPrimaryColor,
                                ),
                              ),
                              items: accounts.map((acc) {
                                return DropdownMenuItem<String>(
                                  value: acc.id,
                                  child: Text(
                                    acc.dropdownLabel,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              validator: (val) => val == null ? 'Selecciona una cuenta' : null,
                              onChanged: (value) {
                                final newlySelected = accounts.where((a) => a.id == value).firstOrNull;
                                setState(() {
                                  _selectedAccountId = value;
                                  if (newlySelected != null && newlySelected.isCreditOrLoan) {
                                    _selectedType = 'EXPENSE';
                                  }
                                });
                              },
                            ),
                          ),
                          const Gap(8),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: CreateAccountSideButton(
                              initialTypeCode: isCreditAccount ? 'BANK_CREDIT' : 'CASH',
                              tooltip: 'Agregar nueva cuenta o tarjeta',
                              onAccountCreated: (created) {
                                setState(() {
                                  _selectedAccountId = created.id;
                                  if (created.isCreditOrLoan) {
                                    _selectedType = 'EXPENSE';
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- TIPO DE MOVIMIENTO ---
                  DropdownButtonFormField<String>(
                    key: ValueKey('type_${isCreditAccount}_$_selectedType'),
                    initialValue: _selectedType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Movimiento *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      prefixIcon: Icon(
                        _selectedType == 'INCOME' ? Icons.arrow_downward : Icons.arrow_upward,
                        color: _selectedType == 'INCOME' ? Colors.green : Colors.red,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'EXPENSE',
                        child: Text(
                          isCreditAccount
                              ? 'Compra con tarjeta / Nuevo cargo (Aumenta deuda)'
                              : 'Salida de dinero (Gasto)',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'INCOME',
                        child: Text(
                          isCreditAccount
                              ? 'Abono / Pago directo al crédito (Reduce deuda)'
                              : 'Entrada de dinero (Ingreso)',
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
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
                    hintText: isCreditAccount
                        ? 'Ej. Compra en supermercado, Mensualidad, Abono...'
                        : 'Ej. Despensa, Gasolina, Quincena, Ahorro...',
                    controller: _descriptionController,
                    isRequired: true,
                    maxLines: 2,
                    validator: (value) => (value == null || value.trim().isEmpty) ? 'La descripción es requerida' : null,
                  ),
                  const SizedBox(height: 16),

                  // --- MÉTODO DE PAGO ---
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
                    : const Text('Registrar Movimiento', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final addTransactionState = ref.watch(addTransactionProvider);
    final isLoading = addTransactionState.isLoading;

    ref.listen(addTransactionProvider, (previous, next) {
      next.whenOrNull(
        data: (transaction) {
          if (transaction != null) {
            SnackbarUtil.showSuccess(context, 'Movimiento registrado correctamente');
            ref.invalidate(personalAccountsProvider);
            ref.invalidate(personalTransactionsListProvider);
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
      title: 'Agregar Movimiento Personal',
      appBar: AppBar(
        title: const AppText('Agregar Movimiento Personal', color: AppColors.kNeutral100),
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
