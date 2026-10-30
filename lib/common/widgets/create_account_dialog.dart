import 'package:admivida/business/features/commission_payments/commission_payment_provider.dart';
import 'package:admivida/business/features/transactions/models/account_model.dart';
import 'package:admivida/business/features/transactions/transactions_provider.dart';
import 'package:admivida/business/features/transactions/transactions_service.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/app_text_field.dart';
import 'package:admivida/personal/features/transactions/personal_transactions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

/// Muestra un AlertDialog para crear una nueva cuenta (de negocio si [businessId] está presente, o personal si es null).
/// Devuelve el [AccountModel] recién creado o `null` si se canceló.
Future<AccountModel?> showCreateAccountDialog(
  BuildContext context,
  WidgetRef ref, {
  String? businessId,
  String initialTypeCode = 'CASH',
}) async {
  return showDialog<AccountModel>(
    context: context,
    builder: (dialogContext) => _CreateAccountDialog(
      businessId: businessId,
      parentRef: ref,
      initialTypeCode: initialTypeCode,
    ),
  );
}

class _CreateAccountDialog extends StatefulWidget {
  final String? businessId;
  final WidgetRef parentRef;
  final String initialTypeCode;

  const _CreateAccountDialog({
    required this.businessId,
    required this.parentRef,
    required this.initialTypeCode,
  });

  @override
  State<_CreateAccountDialog> createState() => _CreateAccountDialogState();
}

class _CreateAccountDialogState extends State<_CreateAccountDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _creditLimitController = TextEditingController();
  final TextEditingController _initialAmountController = TextEditingController();

  late String _selectedTypeCode;
  bool _hasFixedCreditLimit = true; // true = Tarjeta / Línea con límite; false = Préstamo / Deuda abierta
  bool _isDefault = false;
  bool _isSubmitting = false;

  bool get _isBusiness => widget.businessId != null && widget.businessId!.trim().isNotEmpty;
  bool get _isCredit => _selectedTypeCode == 'BANK_CREDIT';

  @override
  void initState() {
    super.initState();
    _selectedTypeCode = widget.initialTypeCode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _creditLimitController.dispose();
    _initialAmountController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final double? creditLimit = (_isCredit && _hasFixedCreditLimit)
        ? double.tryParse(_creditLimitController.text.trim())
        : null;

    final double? initialBalance = _initialAmountController.text.trim().isNotEmpty
        ? double.tryParse(_initialAmountController.text.trim())
        : null;

    setState(() => _isSubmitting = true);

    final result = await TransactionsService.createAccount(
      name: _nameController.text.trim(),
      accountTypeCode: _selectedTypeCode,
      businessId: _isBusiness ? widget.businessId : null,
      creditLimit: creditLimit,
      initialBalance: initialBalance,
      isDefault: (_isBusiness && !_isCredit) ? _isDefault : null,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      (failure) {
        SnackbarUtil.showError(context, failure.message);
      },
      (createdAccount) {
        if (_isBusiness) {
          widget.parentRef.invalidate(accountsBusinessProvider(businessId: widget.businessId));
          widget.parentRef.invalidate(transactionsListProvider);
        } else {
          widget.parentRef.invalidate(personalAccountsProvider);
          widget.parentRef.invalidate(personalTransactionsListProvider);
          widget.parentRef.invalidate(accountsUserProvider);
        }
        SnackbarUtil.showSuccess(context, 'Cuenta "${createdAccount.name}" creada correctamente.');
        NavigationService.pop(context, createdAccount);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (_isCredit ? AppColors.kWarning : AppColors.kPrimaryColor).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _isCredit ? Icons.credit_score_rounded : Icons.add_card_rounded,
              color: _isCredit ? AppColors.kWarning : AppColors.kPrimaryColor,
              size: 22,
            ),
          ),
          const Gap(12),
          Expanded(
            child: AppText(
              _isBusiness ? 'Nueva Cuenta de Negocio' : 'Nueva Cuenta Personal',
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.kNeutral900,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  _isCredit
                      ? 'Registra una tarjeta de crédito, línea en app de préstamos (ej. Mercado Crédito) o un préstamo personal para controlar cuánto debes y cuánto tienes disponible.'
                      : 'Agrega una cuenta de efectivo o tarjeta de débito para llevar el control de tu dinero disponible.',
                  fontSize: 12.5,
                  color: AppColors.kNeutral600,
                ),
                const Gap(14),
                const AppText(
                  'Tipo de cuenta',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.kNeutral700,
                ),
                const Gap(8),
                Row(
                  children: [
                    Expanded(
                      child: _TypeOptionTile(
                        label: 'Efectivo',
                        icon: Icons.payments_outlined,
                        isSelected: _selectedTypeCode == 'CASH',
                        onTap: () => setState(() => _selectedTypeCode = 'CASH'),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: _TypeOptionTile(
                        label: 'Débito',
                        icon: Icons.credit_card_rounded,
                        isSelected: _selectedTypeCode == 'BANK_DEBIT',
                        onTap: () => setState(() => _selectedTypeCode = 'BANK_DEBIT'),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: _TypeOptionTile(
                        label: 'Crédito / Préstamo',
                        icon: Icons.credit_score_rounded,
                        isSelected: _selectedTypeCode == 'BANK_CREDIT',
                        activeColor: AppColors.kWarning,
                        onTap: () => setState(() => _selectedTypeCode = 'BANK_CREDIT'),
                      ),
                    ),
                  ],
                ),
                const Gap(14),
                AppTextField(
                  text: 'Nombre de la cuenta *',
                  hintText: _isCredit
                      ? (_hasFixedCreditLimit
                          ? 'Ej. Tarjeta Nu, BBVA Crédito, Mercado Crédito...'
                          : 'Ej. Préstamo Personal, Préstamo Familiar...')
                      : (_isBusiness ? 'Ej. Caja Chica, BBVA Negocio...' : 'Ej. Efectivo Cartera, Débito Nu, BBVA...'),
                  controller: _nameController,
                  isRequired: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresa el nombre de la cuenta';
                    }
                    return null;
                  },
                ),
                if (_isCredit) ...[
                  const Gap(14),
                  const AppText(
                    'Modalidad del crédito',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.kNeutral700,
                  ),
                  const Gap(8),
                  Row(
                    children: [
                      Expanded(
                        child: _TypeOptionTile(
                          label: 'Con límite (Tarjeta / App)',
                          icon: Icons.speed_rounded,
                          isSelected: _hasFixedCreditLimit,
                          activeColor: AppColors.kWarning,
                          onTap: () => setState(() => _hasFixedCreditLimit = true),
                        ),
                      ),
                      const Gap(8),
                      Expanded(
                        child: _TypeOptionTile(
                          label: 'Préstamo / Deuda fija',
                          icon: Icons.handshake_outlined,
                          isSelected: !_hasFixedCreditLimit,
                          activeColor: AppColors.kWarning,
                          onTap: () => setState(() => _hasFixedCreditLimit = false),
                        ),
                      ),
                    ],
                  ),
                  if (_hasFixedCreditLimit) ...[
                    const Gap(14),
                    AppTextField(
                      text: 'Límite de crédito autorizado (\$) *',
                      hintText: 'Ej. 10000.00',
                      controller: _creditLimitController,
                      isRequired: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (!_isCredit || !_hasFixedCreditLimit) return null;
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el límite de crédito';
                        }
                        final parsed = double.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Ingresa un límite válido mayor a 0';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
                const Gap(14),
                AppTextField(
                  text: _isCredit
                      ? '¿Cuánto debes actualmente en esta cuenta? (Opcional)'
                      : 'Saldo inicial disponible (Opcional)',
                  hintText: '0.00',
                  controller: _initialAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null || parsed < 0) {
                      return 'Ingresa un monto válido (0 o mayor)';
                    }
                    return null;
                  },
                ),
                if (_isBusiness && !_isCredit) ...[
                  const Gap(14),
                  Container(
                    decoration: BoxDecoration(
                      color: _isDefault ? AppColors.kPrimaryColor.withValues(alpha: 0.08) : AppColors.kNeutral50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isDefault ? AppColors.kPrimaryColor : AppColors.kNeutral300,
                      ),
                    ),
                    child: SwitchListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      activeThumbColor: AppColors.kPrimaryColor,
                      title: const AppText(
                        'Cuenta predeterminada para cobros',
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kNeutral800,
                      ),
                      subtitle: const AppText(
                        'Las ventas de tus vendedores se depositarán automáticamente en esta cuenta.',
                        fontSize: 11,
                        color: AppColors.kNeutral600,
                      ),
                      value: _isDefault,
                      onChanged: (val) => setState(() => _isDefault = val),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => NavigationService.pop(context),
          child: const AppText('Cancelar', color: AppColors.kNeutral600, fontWeight: FontWeight.w600),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.kPrimaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ],
    );
  }
}

class _TypeOptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;

  const _TypeOptionTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.activeColor = AppColors.kPrimaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.1) : AppColors.kNeutral50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.kNeutral300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? activeColor : AppColors.kNeutral600,
            ),
            const Gap(5),
            Flexible(
              child: AppText(
                label,
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : AppColors.kNeutral700,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón compacto para colocar al lado de cualquier Dropdown de cuentas.
class CreateAccountSideButton extends ConsumerWidget {
  final String? businessId;
  final String initialTypeCode;
  final ValueChanged<AccountModel>? onAccountCreated;
  final String tooltip;

  const CreateAccountSideButton({
    super.key,
    this.businessId,
    this.initialTypeCode = 'CASH',
    this.onAccountCreated,
    this.tooltip = 'Agregar nueva cuenta',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si la cuenta pertenece a un negocio, SOLO el ADMIN del negocio puede crear cuentas
    if (businessId != null && businessId!.isNotEmpty) {
      final isAdmin = ref.watch(isBusinessAdminProvider(businessId!));
      if (!isAdmin) {
        return const SizedBox.shrink();
      }
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.kPrimaryColor,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            final created = await showCreateAccountDialog(
              context,
              ref,
              businessId: businessId,
              initialTypeCode: initialTypeCode,
            );
            if (created != null && onAccountCreated != null) {
              onAccountCreated!(created);
            }
          },
          child: const SizedBox(
            width: 48,
            height: 48,
            child: Icon(Icons.add_rounded, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}
