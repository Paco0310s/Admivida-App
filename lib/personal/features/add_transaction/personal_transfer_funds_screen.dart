import 'package:admivida/business/features/add_transaction/add_transactions_provider.dart';
import 'package:admivida/business/features/add_transaction/models/transfer_funds_dto.dart';
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

class PersonalTransferFundsScreen extends ConsumerStatefulWidget {
  const PersonalTransferFundsScreen({super.key});

  @override
  ConsumerState<PersonalTransferFundsScreen> createState() => _PersonalTransferFundsScreenState();
}

class _PersonalTransferFundsScreenState extends ConsumerState<PersonalTransferFundsScreen> {
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
      businessId: null,
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
            const AppText('Transferir o Pagar Tarjeta / Préstamo', fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.kPrimaryColor),
            const Gap(8),
            AppText(
              'Mueve dinero entre tus cuentas de efectivo/débito, paga una tarjeta de crédito o préstamo desde tu dinero disponible, o registra el depósito de un préstamo a tu cuenta.',
              color: AppColors.kNeutral600,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildContextualBanner(AccountModel? src, AccountModel? dst) {
    if (src == null || dst == null) return null;

    String message;
    IconData icon;
    Color color;

    if (!src.isCreditOrLoan && dst.isCreditOrLoan) {
      message =
          'Estás pagando/abonando a "${dst.name}" usando dinero de "${src.name}". Tu saldo disponible disminuirá y tu deuda bajará.';
      icon = Icons.check_circle_outline_rounded;
      color = AppColors.kSuccess;
    } else if (src.isCreditOrLoan && !dst.isCreditOrLoan) {
      message =
          'Estás disponiendo efectivo / recibiendo un préstamo desde "${src.name}" hacia "${dst.name}". Tu dinero disponible aumentará y tu deuda en "${src.name}" subirá.';
      icon = Icons.info_outline_rounded;
      color = AppColors.kWarning;
    } else {
      message = 'Transferencia directa entre "${src.name}" y "${dst.name}".';
      icon = Icons.swap_horiz_rounded;
      color = AppColors.kPrimaryColor;
    }

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(10),
          Expanded(
            child: AppText(
              message,
              fontSize: 12.5,
              color: AppColors.kNeutral800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isLoading) {
    final accountsAsync = ref.watch(personalAccountsProvider);

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
                    text: 'Monto a transferir / abonar *',
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
                    hintText: 'Ej. Pago de tarjeta Nu, Abono a préstamo, Retiro en cajero...',
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
                      final validSource = accounts.any((a) => a.id == _sourceAccountId) ? _sourceAccountId : null;
                      final validDest = accounts.any((a) => a.id == _destinationAccountId) ? _destinationAccountId : null;

                      final srcAcc = accounts.where((a) => a.id == validSource).firstOrNull;
                      final dstAcc = accounts.where((a) => a.id == validDest).firstOrNull;
                      final banner = _buildContextualBanner(srcAcc, dstAcc);

                      return Column(
                        children: [
                          // CUENTA DE ORIGEN + BOTÓN NUEVA CUENTA
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  key: ValueKey('src_$validSource'),
                                  initialValue: validSource,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Cuenta de origen (Sale de) *',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    prefixIcon: const Icon(Icons.arrow_upward, color: Colors.red),
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
                                  validator: (val) => val == null ? 'Selecciona una cuenta de origen' : null,
                                  onChanged: (value) => setState(() => _sourceAccountId = value),
                                ),
                              ),
                              const Gap(8),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: CreateAccountSideButton(
                                  tooltip: 'Agregar nueva cuenta personal',
                                  onAccountCreated: (created) {
                                    setState(() {
                                      if (_sourceAccountId == null) {
                                        _sourceAccountId = created.id;
                                      } else {
                                        _destinationAccountId = created.id;
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // CUENTA DE DESTINO + BOTÓN NUEVA CUENTA
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  key: ValueKey('dst_$validDest'),
                                  initialValue: validDest,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Cuenta de destino (Entra / Abona a) *',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    prefixIcon: const Icon(Icons.arrow_downward, color: Colors.green),
                                  ),
                                  items: accounts.map((acc) {
                                    final isSameAsSource = acc.id == _sourceAccountId;
                                    return DropdownMenuItem<String>(
                                      value: acc.id,
                                      enabled: !isSameAsSource,
                                      child: Text(
                                        acc.dropdownLabel,
                                        style: TextStyle(color: isSameAsSource ? Colors.grey : null),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  validator: (val) {
                                    if (val == null) return 'Selecciona una cuenta de destino';
                                    if (val == _sourceAccountId) return 'No puedes transferir a la misma cuenta';
                                    return null;
                                  },
                                  onChanged: (value) => setState(() => _destinationAccountId = value),
                                ),
                              ),
                              const Gap(8),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: CreateAccountSideButton(
                                  initialTypeCode: 'BANK_CREDIT',
                                  tooltip: 'Agregar nueva cuenta o tarjeta',
                                  onAccountCreated: (created) {
                                    setState(() => _destinationAccountId = created.id);
                                  },
                                ),
                              ),
                            ],
                          ),
                          ?banner,
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
                        'Confirmar Operación',
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
    final transferState = ref.watch(transferFundsProvider);
    final isLoading = transferState.isLoading;

    ref.listen(transferFundsProvider, (previous, next) {
      next.whenOrNull(
        data: (result) {
          if (result != null) {
            SnackbarUtil.showSuccess(context, 'Operación completada correctamente');
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
      title: 'Transferir / Pagar Crédito',
      appBar: AppBar(
        title: const AppText('Transferir / Pagar Crédito', color: AppColors.kNeutral100),
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
