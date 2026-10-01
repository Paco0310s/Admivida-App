import 'package:admivida/business/features/clients/clients_provider.dart';
import 'package:admivida/business/features/clients/models/create_client_dto_model.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/errors/http_failure.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/utils/validators.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class CreateClientScreen extends ConsumerStatefulWidget {
  final String businessId;

  const CreateClientScreen({super.key, required this.businessId});

  @override
  ConsumerState<CreateClientScreen> createState() => _CreateClientScreenState();
}

class _CreateClientScreenState extends ConsumerState<CreateClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Controla el estado de carga del botón
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (email.isEmpty && phone.isEmpty) {
      SnackbarUtil.showWarning(context, 'Debes ingresar al menos un teléfono o correo electrónico.');
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final dto = CreateClientDto(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: email,
        phone: phone.isNotEmpty ? '+52 $phone' : null,
      );

      ref.read(createClientProvider.notifier).submit(businessId: widget.businessId, dto: dto);
    }
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText('Datos Personales', fontWeight: FontWeight.bold, fontSize: 16),
              const Gap(16),
              AppTextField(
                text: AppTexts.firstNameLabel,
                hintText: AppTexts.firstNameHint,
                controller: _firstNameController,
                prefixIcon: const Icon(Icons.person, color: AppColors.kDark3),
                validator: (value) => ValidatorsUtil.validateName(value),
              ),
              const Gap(12),
              AppTextField(
                text: AppTexts.lastNameLabel,
                hintText: AppTexts.lastNameHint,
                controller: _lastNameController,
                prefixIcon: const Icon(Icons.person, color: AppColors.kDark3),
                validator: (value) => ValidatorsUtil.validateLastName(value),
              ),
              const Gap(16),
              const Divider(),
              const Gap(16),
              const AppText('Contacto (Ingresa al menos uno)', fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.kNeutral700),
              const Gap(12),
              AppTextField(
                text: '${AppTexts.phoneLabel} (Opcional si hay correo)',
                hintText: 'Ej. 3312345678',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone, color: AppColors.kDark3),
                validator: (value) {
                  // Solo validamos el formato si el usuario escribió algo
                  if (value != null && value.isNotEmpty) {
                    return ValidatorsUtil.validatePhone(value);
                  }
                  return null;
                },
              ),
              const Gap(12),
              AppTextField(
                text: '${AppTexts.emailLabel} (Opcional si hay teléfono)',
                hintText: AppTexts.emailHint,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email, color: AppColors.kDark3),
                validator: (value) {
                  // Solo validamos el formato si el usuario escribió algo
                  if (value != null && value.isNotEmpty) {
                    return ValidatorsUtil.validateEmail(value);
                  }
                  return null;
                },
              ),
              const Gap(24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.kPrimaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'Guardar Cliente',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientProcessState = ref.watch(createClientProvider);
    _isSubmitting = clientProcessState.isLoading;

    // 2. Reaccionamos al resultado
    ref.listen(createClientProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          if (previous?.isLoading == true) {
            SnackbarUtil.showSuccess(context, 'Cliente registrado exitosamente');
            ref.invalidate(clientsDebtListProvider(widget.businessId));
            NavigationService.pop(context);
          }
        },
        error: (error, stackTrace) {
          final message = error is HttpFailure ? error.message : 'Error al registrar cliente';
          SnackbarUtil.showError(context, message);
        },
      );
    });

    return AppScaffold(
      title: 'Nuevo Cliente',
      appBar: AppBar(
        title: const AppText('Nuevo Cliente', color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
      ),
      mobile: _buildForm(),
      tablet: _buildForm(),
      desktop: _buildForm(),
      marginDesktop: 160,
    );
  }
}
