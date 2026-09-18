import 'package:admivida/business/features/commission_payments/commission_payment_provider.dart';
import 'package:admivida/business/features/commission_payments/models/business_staff_model.dart';
import 'package:admivida/business/features/user_businesses/models/commission_types_enum.dart';
import 'package:admivida/business/features/user_businesses/user_business_provider.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/features/sign_up/models/create_user_dto.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:admivida/common/utils/validators.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_password_field.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class UserBusinessScreen extends ConsumerStatefulWidget {
  final String businessId;

  const UserBusinessScreen({super.key, required this.businessId});

  @override
  ConsumerState<UserBusinessScreen> createState() => _UserBusinessScreenState();
}

class _UserBusinessScreenState extends ConsumerState<UserBusinessScreen> {
  // Search & Commission Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _commissionValueController = TextEditingController();

  // Registration Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthdateController = TextEditingController();

  // Local UI states to manage view transitions
  bool _showForm = false;
  bool _isEditing = false;
  String? _editingUserId;

  @override
  void dispose() {
    _searchController.dispose();
    _commissionValueController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  /// Triggers user search and formats phone numbers automatically
  void _onSearchSubmitted(String value, dynamic controller) {
    String term = value.trim();
    if (term.isEmpty) return;

    // Magic: Auto-detect 10-digit phones and format with +52
    if (RegExp(r'^\d{10}$').hasMatch(term)) {
      term = '+52 $term';
    }

    // WE DO NOT CHANGE _showForm HERE. We wait for the result.
    controller.searchUser(term);
  }

  /// Navigates to the edit form for an existing collaborator
  void _onEditCollaborator(BusinessStaffModel staff) {
    final controller = ref.read(collaboratorFormControllerProvider(widget.businessId).notifier);

    // 1. Precargamos el estado (Riverpod)
    controller.loadExistingCollaborator(staff);

    // 2. Llenamos el campo de texto de la comisión en la UI
    if (staff.commissionType != CommissionType.noCommission) {
      // Usamos toStringAsFixed para que se vea limpio (ej. "25" o "25.5")
      // RegExp remueve ceros decimales innecesarios
      _commissionValueController.text = staff.commissionValue.toString().replaceAll(RegExp(r'([.]*0)(?!.*\d)'), '');
    } else {
      _commissionValueController.clear();
    }

    // 3. Mostramos el formulario
    setState(() {
      _showForm = true;
      _isEditing = true;
      _editingUserId = staff.userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(collaboratorFormControllerProvider(widget.businessId));
    final controller = ref.read(collaboratorFormControllerProvider(widget.businessId).notifier);

    // Reuse existing staff list provider
    final staffAsync = ref.watch(businessSellersProvider(widget.businessId));
    final rolesAsync = ref.watch(availableBusinessRolesProvider);

    ref.listen(collaboratorFormControllerProvider(widget.businessId), (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        SnackbarUtil.showError(context, next.errorMessage!);
      }

      if (next.userFound && !(previous?.userFound ?? false)) {
        setState(() {
          _showForm = true;
          _isEditing = false;
          _editingUserId = null;
        });
      }

      if (next.searchedUser != null && previous?.isCreatingNewUser == true && !next.isCreatingNewUser) {
        _firstNameController.clear();
        _lastNameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _passwordController.clear();
        _birthdateController.clear();
      }

      if (next.isSuccess && !(previous?.isSuccess ?? false)) {
        SnackbarUtil.showSuccess(context, _isEditing ? 'Colaborador actualizado.' : 'Colaborador asignado con éxito.');

        controller.clearAssignmentFields();
        _commissionValueController.clear();
        setState(() => _showForm = false);
        _searchController.clear();

        ref.invalidate(businessSellersProvider(widget.businessId));
      }
    });

    return AppScaffold(
      title: 'Gestión de Colaboradores',
      appBar: AppBar(
        title: AppText(_showForm ? (_isEditing ? 'Editar Colaborador' : 'Nuevo Colaborador') : 'Colaboradores', color: AppColors.kNeutral100),
        backgroundColor: AppColors.kPrimaryColor,
        iconTheme: const IconThemeData(color: AppColors.kNeutral100),
        leading: _showForm
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() => _showForm = false);
                  controller.toggleCreateUserMode(false); // Reset create mode
                  controller.searchUser(''); // Clear searched user in state
                },
              )
            : null,
      ),
      mobile: _showForm ? _buildForm(state, controller, rolesAsync) : _buildListAndSearch(state, staffAsync, controller),
      tablet: _showForm ? _buildForm(state, controller, rolesAsync) : _buildListAndSearch(state, staffAsync, controller),
      desktop: _showForm ? _buildForm(state, controller, rolesAsync) : _buildListAndSearch(state, staffAsync, controller),
      marginDesktop: 160,
    );
  }

  // =========================================================================
  // VIEW 1: LIST AND SEARCH BAR
  // =========================================================================
  Widget _buildListAndSearch(dynamic state, AsyncValue staffAsync, dynamic controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search or Create Card
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText('Usuario existente', fontWeight: FontWeight.bold, fontSize: 16),
                const Gap(12),
                AppTextField(
                  text: 'Buscar por correo, teléfono o código',
                  hintText: 'Ej. 3312345678',
                  controller: _searchController,
                  prefixIcon: const Icon(Icons.search, color: AppColors.kPrimaryColor),
                  onSubmitted: (val) {
                    if (!state.isLoading) _onSearchSubmitted(val, controller);
                  },
                ),
                const Gap(12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kPrimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: state.isLoading ? null : () => _onSearchSubmitted(_searchController.text, controller),
                    child: state.isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Buscar', style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
                const Gap(12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_add),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kPrimaryColor,
                      side: const BorderSide(color: AppColors.kPrimaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      setState(() {
                        _showForm = true;
                        _isEditing = false;
                        _editingUserId = null;
                      });
                      controller.toggleCreateUserMode(true);
                    },
                    label: const Text('Registrar Nuevo', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
          const Gap(24),
          const AppText('Colaboradores Actuales', fontWeight: FontWeight.bold, fontSize: 16),
          const Gap(12),

          // Current Staff List
          staffAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error: $err'),
            data: (staffList) {
              if (staffList.isEmpty) {
                return const Center(child: AppText('No hay colaboradores registrados.'));
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: staffList.length,
                separatorBuilder: (_, _) => const Gap(8),
                itemBuilder: (context, index) {
                  final staff = staffList[index];
                  return AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      minVerticalPadding: 0,
                      horizontalTitleGap: 12,
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: AppColors.kPrimaryColor,
                        child: Text(
                          staff.fullName.isEmpty ? '?' : staff.fullName[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: AppText(staff.fullName, fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.kNeutral800),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (staff.roles.isEmpty)
                            const AppText('Sin roles asignados', fontSize: 12, color: AppColors.kNeutral500)
                          else
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: staff.roles
                                  .map<Widget>(
                                    (role) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                                      decoration: BoxDecoration(color: AppColors.kPrimary50, borderRadius: BorderRadius.circular(8)),
                                      child: Text(
                                        role.name,
                                        style: const TextStyle(color: AppColors.kPrimary700, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Icon(Icons.touch_app_outlined, size: 14, color: AppColors.kNeutral500),
                              SizedBox(width: 4),
                              AppText('Toca para editar', fontSize: 11, color: AppColors.kNeutral500),
                            ],
                          ),
                        ],
                      ),
                      trailing: Container(
                        decoration: BoxDecoration(color: AppColors.kPrimary50, borderRadius: BorderRadius.circular(10)),
                        child: IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.kPrimary700, size: 20),
                          tooltip: 'Editar asignación',
                          onPressed: () => _onEditCollaborator(staff),
                        ),
                      ),
                      onTap: () => _onEditCollaborator(staff),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // VIEW 2: FULL ASSIGNMENT / REGISTRATION FORM
  // =========================================================================
  Widget _buildForm(dynamic state, dynamic controller, AsyncValue<List<StaffRoleModel>> rolesAsync) {
    // Only show loading if we are performing an action within this view (like registering)
    if (state.isLoading && state.isCreatingNewUser) {
      return const Center(child: CircularProgressIndicator());
    }

    final requiresValue = state.commissionType != CommissionType.noCommission;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Section (Searched Card or Registration Form)
          _buildUserSection(state, controller),
          const Gap(16),

          // Role Selection Card
          AppCard(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText('Roles del Negocio', fontWeight: FontWeight.bold, fontSize: 16),
                  const Gap(12),
                  rolesAsync.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (err, stack) => AppText('Error al cargar roles: $err', color: Colors.red),
                    data: (roles) {
                      if (roles.isEmpty) return const AppText('No hay roles configurados.');

                      return Wrap(
                        spacing: 8.0,
                        children: roles.map((role) {
                          final isSelected = state.selectedRoleIds.contains(role.id);

                          return FilterChip(
                            label: Text(role.name),
                            selected: isSelected,
                            selectedColor: AppColors.kPrimaryColor,
                            checkmarkColor: AppColors.kBackgroundColor,
                            onSelected: (_) => controller.toggleRole(role.id),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const Gap(16),

          // Commission Configuration Card
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText('Configuración de Comisiones', fontWeight: FontWeight.bold, fontSize: 16),
                const Gap(12),
                DropdownButtonFormField<CommissionType>(
                  initialValue: state.commissionType,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Comisión',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: CommissionType.noCommission, child: Text('Sin Comisión')),
                    DropdownMenuItem(value: CommissionType.percentage, child: Text('Porcentaje (%)')),
                    DropdownMenuItem(value: CommissionType.fixedAmount, child: Text('Monto Fijo (\$')),
                  ],
                  onChanged: (CommissionType? newValue) {
                    if (newValue != null) {
                      controller.updateCommission(newValue, state.commissionValue);
                      if (newValue == CommissionType.noCommission) {
                        _commissionValueController.clear();
                      }
                    }
                  },
                ),
                if (requiresValue) ...[
                  const Gap(16),
                  AppTextField(
                    text: state.commissionType == CommissionType.percentage ? 'Porcentaje' : 'Monto Fijo',
                    hintText: state.commissionType == CommissionType.percentage ? 'Ej. 5.0' : 'Ej. 50.0',
                    controller: _commissionValueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: Icon(state.commissionType == CommissionType.percentage ? Icons.percent : Icons.attach_money),
                  ),
                ],
              ],
            ),
          ),
          const Gap(24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (state.commissionType != CommissionType.noCommission) {
                  final value = double.tryParse(_commissionValueController.text) ?? 0.0;
                  controller.updateCommission(state.commissionType, value);
                }

                if (_isEditing && _editingUserId != null) {
                  controller.updateUser(_editingUserId!);
                } else {
                  controller.assignUser();
                }
              },
              child: Text(_isEditing ? 'Guardar Cambios' : 'Confirmar y Asignar', style: const TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SUB-SECTION: USER RESOLUTION (Found or Creating)
  // =========================================================================
  Widget _buildUserSection(dynamic state, dynamic controller) {
    // 1. Hide user resolution if we are just editing an existing assignment
    if (_isEditing) return const SizedBox.shrink();

    // 2. User successfully found or created
    if (state.searchedUser != null) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            backgroundColor: AppColors.kSuccess,
            child: Icon(Icons.check, color: Colors.white),
          ),
          title: AppText('${state.searchedUser!.firstName} ${state.searchedUser!.lastName}', fontWeight: FontWeight.bold),
          subtitle: AppText(state.searchedUser!.email),
          trailing: IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            tooltip: 'Buscar otro',
            onPressed: () {
              setState(() => _showForm = false);
              controller.searchUser(''); // Clear user
              _searchController.clear();
            },
          ),
        ),
      );
    }

    // 3. Display full registration form (Active when "Registrar Nuevo Usuario" is tapped)
    if (state.isCreatingNewUser) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText('Registrar Nuevo Usuario', fontWeight: FontWeight.bold, fontSize: 16),
              const Gap(16),
              AppTextField(
                text: AppTexts.firstNameLabel,
                hintText: AppTexts.firstNameHint,
                controller: _firstNameController,
                prefixIcon: const Icon(Icons.person, color: AppColors.kDark3),
                validator: (value) => ValidatorsUtil.validateName(value),
              ),
              const Gap(10),
              AppTextField(
                text: AppTexts.lastNameLabel,
                hintText: AppTexts.lastNameHint,
                controller: _lastNameController,
                prefixIcon: const Icon(Icons.person, color: AppColors.kDark3),
                validator: (value) => ValidatorsUtil.validateLastName(value),
              ),
              const Gap(10),
              AppTextField(
                text: AppTexts.emailLabel,
                hintText: AppTexts.emailHint,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.email, color: AppColors.kDark3),
                validator: (value) => ValidatorsUtil.validateEmail(value),
              ),
              const Gap(10),
              AppTextField(
                text: AppTexts.phoneLabel,
                hintText: AppTexts.phoneHint,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                prefixIcon: const Icon(Icons.phone, color: AppColors.kDark3),
                validator: (value) => ValidatorsUtil.validatePhone(value),
              ),
              const Gap(10),
              AppPasswordField(
                text: AppTexts.passwordLabel,
                hintText: AppTexts.passwordHint,
                controller: _passwordController,
                prefixIcon: const Icon(Icons.lock, color: AppColors.kDark3),
                validator: (value) => ValidatorsUtil.validatePassword(value),
              ),
              const Gap(10),
              _AppBirthdayPicker(birthdateController: _birthdateController),
              const Gap(24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.kPrimaryColor, padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      final dto = CreateUserDto(
                        firstName: _firstNameController.text.trim(),
                        lastName: _lastNameController.text.trim(),
                        email: _emailController.text.trim(),
                        phone: '+52 ${_phoneController.text.trim()}',
                        password: _passwordController.text,
                        // Parse date only if the field is not empty, otherwise send null
                        birthdate: _birthdateController.text.isNotEmpty ? DateTime.parse(_birthdateController.text.trim()) : null,
                        metadata: {},
                      );
                      controller.registerNewUser(dto);
                    }
                  },
                  child: const Text('Registrar Usuario', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

// =========================================================================
// PRIVATE WIDGET: BIRTHDAY PICKER (OPTIONAL)
// =========================================================================
class _AppBirthdayPicker extends StatelessWidget {
  const _AppBirthdayPicker({required this.birthdateController});

  final TextEditingController birthdateController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText('${AppTexts.birthdateLabel} (Opcional)', fontSize: 14, color: AppColors.kSecondaryColor),
        const Gap(10),
        // Reacts to text changes to show/hide the clear button
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: birthdateController,
          builder: (context, value, child) {
            return TextFormField(
              controller: birthdateController,
              readOnly: true,
              decoration: InputDecoration(
                hintText: AppTexts.birthdateHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.kPrimary500, width: 2),
                ),
                prefixIcon: const Icon(Icons.calendar_today, color: AppColors.kDark3),
                // Show "Clear" (X) if there is a date, otherwise show standard dropdown arrow
                suffixIcon: value.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () => birthdateController.clear(),
                      )
                    : const Icon(Icons.arrow_drop_down, color: AppColors.kDark3),
              ),
              onTap: () async {
                final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now());
                if (picked != null) {
                  birthdateController.text = DateFormat('yyyy-MM-dd').format(picked);
                }
              },
              // Return null to mean "always valid" (since it's optional)
              validator: (val) => null,
            );
          },
        ),
      ],
    );
  }
}
