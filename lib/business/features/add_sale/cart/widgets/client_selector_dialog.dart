import 'package:admivida/business/features/add_sale/models/business_client_model.dart';
import 'package:admivida/business/features/clients/clients_service.dart';
import 'package:admivida/business/features/clients/models/create_client_dto_model.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/user_logged_model.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/utils/validators.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

String? normalizeClientPhone(String rawPhone) {
  final trimmed = rawPhone.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('+')) return trimmed;
  return '+52 $trimmed';
}

Future<UserModel?> showQuickCreateClientDialog(
  BuildContext context, {
  required String businessId,
}) async {
  final formKey = GlobalKey<FormState>();
  final firstNameCtrl = TextEditingController();
  final lastNameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  bool isSaving = false;
  UserModel? createdClient;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        Future<void> submit() async {
          final email = emailCtrl.text.trim();
          final rawPhone = phoneCtrl.text.trim();

          if (email.isEmpty && rawPhone.isEmpty) {
            SnackbarUtil.showWarning(
              dialogContext,
              'Ingresa al menos un teléfono o correo electrónico.',
            );
            return;
          }

          if (!(formKey.currentState?.validate() ?? false)) return;

          setDialogState(() => isSaving = true);
          final dto = CreateClientDto(
            firstName: firstNameCtrl.text.trim(),
            lastName: lastNameCtrl.text.trim(),
            email: email.isEmpty ? null : email,
            phone: normalizeClientPhone(rawPhone),
          );

          final result = await ClientsService.createClient(dto, businessId);
          if (!dialogContext.mounted) return;

          result.when(
            (failure) {
              setDialogState(() => isSaving = false);
              SnackbarUtil.showError(
                dialogContext,
                'No se pudo registrar el cliente (${failure.message})',
              );
            },
            (user) {
              createdClient = user;
              NavigationService.pop(dialogContext);
            },
          );
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1_rounded, color: AppColors.kPrimaryColor),
              Gap(10),
              Expanded(
                child: AppText(
                  'Nuevo Cliente Rápido',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppTextField(
                      text: AppTexts.firstNameLabel,
                      hintText: AppTexts.firstNameHint,
                      controller: firstNameCtrl,
                      isRequired: true,
                      validator: (v) => ValidatorsUtil.validateName(v),
                    ),
                    const Gap(10),
                    AppTextField(
                      text: AppTexts.lastNameLabel,
                      hintText: AppTexts.lastNameHint,
                      controller: lastNameCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? null
                          : ValidatorsUtil.validateLastName(v),
                    ),
                    const Gap(10),
                    AppTextField(
                      text: '${AppTexts.phoneLabel} (Opcional si hay correo)',
                      hintText: 'Ej. 3312345678',
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? null
                          : ValidatorsUtil.validatePhone(v),
                    ),
                    const Gap(10),
                    AppTextField(
                      text: '${AppTexts.emailLabel} (Opcional si hay teléfono)',
                      hintText: AppTexts.emailHint,
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? null
                          : ValidatorsUtil.validateEmail(v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => NavigationService.pop(dialogContext),
              child: const AppText('Cancelar', color: AppColors.kNeutral600),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSaving ? null : submit,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: const Text('Guardar y seleccionar'),
            ),
          ],
        );
      },
    ),
  );

  firstNameCtrl.dispose();
  lastNameCtrl.dispose();
  phoneCtrl.dispose();
  emailCtrl.dispose();
  return createdClient;
}

Future<void> showClientSelectorDialog(
  BuildContext context, {
  required String businessId,
  required List<BusinessClientModel> clients,
  required String? selectedClientId,
  required void Function(String clientId, String fullName) onClientSelected,
  required VoidCallback onClientCreated,
}) async {
  final searchCtrl = TextEditingController();
  int highlightedIdx = 0;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setModalState) {
        final q = searchCtrl.text.trim().toLowerCase();
        final filtered = q.isEmpty
            ? clients
            : clients
                .where((c) => '${c.firstName} ${c.lastName}'.toLowerCase().contains(q))
                .toList();
        final safeIdx = filtered.isEmpty ? 0 : highlightedIdx.clamp(0, filtered.length - 1);

        void selectClient(BusinessClientModel c) {
          onClientSelected(c.userId, c.fullName);
          NavigationService.pop(dialogContext);
        }

        return Focus(
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent || filtered.isEmpty) return KeyEventResult.ignored;
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              setModalState(() => highlightedIdx = (safeIdx + 1).clamp(0, filtered.length - 1));
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              setModalState(() => highlightedIdx = (safeIdx - 1).clamp(0, filtered.length - 1));
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                const Icon(Icons.people_alt_outlined, color: AppColors.kPrimaryColor),
                const Gap(10),
                const Expanded(
                  child: AppText(
                    'Seleccionar Cliente (F3)',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final created = await showQuickCreateClientDialog(
                      dialogContext,
                      businessId: businessId,
                    );
                    if (created == null || !dialogContext.mounted) return;
                    onClientCreated();
                    final fullName = '${created.firstName} ${created.lastName}'.trim();
                    onClientSelected(created.id, fullName);
                    NavigationService.pop(dialogContext);
                  },
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                  label: const Text('Nuevo', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              height: 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    onChanged: (_) => setModalState(() => highlightedIdx = 0),
                    onSubmitted: (_) {
                      if (filtered.isNotEmpty) {
                        selectClient(filtered[safeIdx]);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Escribe para buscar cliente (↑↓ y Enter)...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: AppColors.kNeutral50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const Gap(10),
                  Expanded(
                    child: filtered.isEmpty
                        ? const Center(
                            child: AppText(
                              'No se encontraron clientes',
                              color: AppColors.kNeutral500,
                            ),
                          )
                        : ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final c = filtered[index];
                              final fullName = c.fullName;
                              final isGeneralPublic =
                                  fullName.toLowerCase().contains('público general') ||
                                  fullName.toLowerCase().contains('publico general');
                              final isSelected = selectedClientId == c.userId;
                              final isHighlighted = index == safeIdx;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: isHighlighted ? AppColors.kPrimary50 : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(
                                    isGeneralPublic ? Icons.public : Icons.person_outline,
                                    color: isGeneralPublic
                                        ? AppColors.kPrimaryColor
                                        : AppColors.kNeutral700,
                                  ),
                                  title: Text(
                                    fullName,
                                    style: TextStyle(
                                      fontWeight: isHighlighted || isSelected
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(Icons.check, color: AppColors.kPrimaryColor)
                                      : isHighlighted
                                          ? const Text(
                                              'Enter ↵',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.kPrimaryColor,
                                              ),
                                            )
                                          : null,
                                  onTap: () => selectClient(c),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => NavigationService.pop(dialogContext),
                child: const AppText('Cerrar (Esc)', color: AppColors.kNeutral600),
              ),
            ],
          ),
        );
      },
    ),
  );

  searchCtrl.dispose();
}
