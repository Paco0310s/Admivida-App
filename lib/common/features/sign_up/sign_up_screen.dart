import 'package:admivida/common/widgets/floating_whatsapp_button.dart';

import 'package:admivida/common/constants/app_assets.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/features/sign_up/models/create_user_dto.dart';
import 'package:admivida/common/features/sign_up/sign_up_provider.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/utils/validators.dart';
import 'package:admivida/common/widgets/app_button.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_image.dart';
import 'package:admivida/common/widgets/app_password_field.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/app_text_field.dart';
import 'package:admivida/common/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      showAppBar: false,
      showDashboardShell: false,
      title: AppTexts.signUp,
      floatingActionButton: const FloatingWhatsAppButton(heroTag: 'signup_whatsapp_fab'),
      mobile: SignUpMobile(context),
      tablet: SignUpTablet(context),
      desktop: SignUpDesktop(context),
      marginDesktop: 0,
      marginTablet: 0,
    );
  }
}

class SignUpMobile extends StatelessWidget {
  final BuildContext context;

  const SignUpMobile(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: SignUpForm(showHeaderLogo: true),
      ),
    );
  }
}

class SignUpTablet extends StatelessWidget {
  final BuildContext context;

  const SignUpTablet(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: const AppCard(
            padding: EdgeInsets.all(32),
            child: SignUpForm(showHeaderLogo: true),
          ),
        ),
      ),
    );
  }
}

class SignUpDesktop extends StatelessWidget {
  final BuildContext context;

  const SignUpDesktop(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Branding Panel (40%)
        Expanded(
          flex: 40,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF132D38),
                  AppColors.kPrimaryColor,
                  AppColors.kSecondaryColor,
                ],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: AppImage(
                    AdaptedFile.asset(AppAssets.icon),
                    height: 56,
                    width: 56,
                    fit: BoxFit.contain,
                  ),
                ),
                const Gap(24),
                const AppText(
                  AppTexts.appName,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                const Gap(10),
                const AppText(
                  'Crea tu cuenta para administrar tus negocios, inventario, ventas y equipo desde un solo lugar.',
                  fontSize: 14.5,
                  color: Color(0xE0FFFFFF),
                ),
                const Gap(28),
                const _SignUpFeatureItem(
                  icon: Icons.storefront_rounded,
                  label: 'Multi-empresa y sucursales',
                ),
                const Gap(12),
                const _SignUpFeatureItem(
                  icon: Icons.point_of_sale_rounded,
                  label: 'Punto de venta e inventario',
                ),
                const Gap(12),
                const _SignUpFeatureItem(
                  icon: Icons.security_rounded,
                  label: 'Acceso seguro en la nube',
                ),
              ],
            ),
          ),
        ),
        // Right Form Panel (60%)
        Expanded(
          flex: 60,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: const AppCard(
                  padding: EdgeInsets.all(32),
                  child: SignUpForm(showHeaderLogo: false),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignUpFeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SignUpFeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.kPrimary100, size: 18),
          const Gap(10),
          Flexible(
            child: AppText(
              label,
              fontSize: 12.5,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class SignUpImage extends StatelessWidget {
  const SignUpImage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppImage(
      AdaptedFile.asset(AppAssets.logo),
      color: AppColors.kNeutral100,
      height: double.infinity,
      width: double.infinity,
      fit: BoxFit.contain,
    );
  }
}

class SignUpWidget extends StatelessWidget {
  final int ponderContainers;
  final int ponderForm;

  const SignUpWidget({super.key, this.ponderContainers = 10, this.ponderForm = 80});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Flexible(flex: ponderContainers, child: Container()),
            Flexible(flex: ponderForm, child: const SignUpForm()),
            Flexible(flex: ponderContainers, child: Container()),
          ],
        ),
      ),
    );
  }
}

class SignUpForm extends ConsumerStatefulWidget {
  final bool showHeaderLogo;

  const SignUpForm({super.key, this.showHeaderLogo = true});

  @override
  ConsumerState<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _birthdateController = TextEditingController();
  final _countryCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _birthdateController.dispose();
    _countryCodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      final String firstName = _firstNameController.text.trim();
      final String lastName = _lastNameController.text.trim();
      final String birthdate = _birthdateController.text.trim();
      final String countryCode = _countryCodeController.text.isNotEmpty ? _countryCodeController.text.trim() : '52'; // Default a México
      final String phone = '+$countryCode ${_phoneController.text.trim()}';
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;

      CreateUserDto createBossDto = CreateUserDto(
        firstName: firstName,
        lastName: lastName,
        birthdate: DateTime.parse(birthdate),
        phone: phone,
        email: email,
        password: password,
        metadata: {},
      );

      ref.read(signUpLoadingProvider.notifier).setLoading(true);
      await ref.read(signUpProvider(context, createBossDto).future);
      ref.read(signUpLoadingProvider.notifier).setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSignUpLoading = ref.watch(signUpLoadingProvider);
    final isDesktop = Responsive.isDesktop(context);

    final firstNameField = AppTextField(
      text: AppTexts.firstNameLabel,
      hintText: AppTexts.firstNameHint,
      keyboardType: TextInputType.name,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      controller: _firstNameController,
      validator: (value) => ValidatorsUtil.validateName(value),
      prefixIcon: const Icon(Icons.person_rounded, size: 20, color: AppColors.kDark3),
    );

    final lastNameField = AppTextField(
      text: AppTexts.lastNameLabel,
      hintText: AppTexts.lastNameHint,
      keyboardType: TextInputType.name,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      controller: _lastNameController,
      validator: (value) => ValidatorsUtil.validateLastName(value),
      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.kDark3),
    );

    final emailField = AppTextField(
      text: AppTexts.emailLabel,
      hintText: AppTexts.emailHint,
      keyboardType: TextInputType.emailAddress,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      controller: _emailController,
      validator: (value) => ValidatorsUtil.validateEmail(value),
      prefixIcon: const Icon(Icons.email_rounded, size: 20, color: AppColors.kDark3),
    );

    final phoneField = AppTextField(
      text: AppTexts.phoneLabel,
      hintText: AppTexts.phoneHint,
      keyboardType: TextInputType.phone,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      controller: _phoneController,
      validator: (value) => ValidatorsUtil.validatePhone(value),
      prefixIcon: const Icon(Icons.phone_rounded, size: 20, color: AppColors.kDark3),
    );

    final passwordField = AppPasswordField(
      text: AppTexts.passwordLabel,
      hintText: AppTexts.passwordHint,
      keyboardType: TextInputType.visiblePassword,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      controller: _passwordController,
      validator: (value) => ValidatorsUtil.validatePassword(value),
      prefixIcon: const Icon(Icons.lock_rounded, size: 20, color: AppColors.kDark3),
    );

    final birthdayField = _AppBirthdayPicker(birthdateController: _birthdateController);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: AbsorbPointer(
        absorbing: isSignUpLoading,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showHeaderLogo) ...[
              Center(
                child: AppImage(
                  AdaptedFile.asset(AppAssets.icon),
                  height: 100,
                  width: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const Gap(16),
            ],
            const AppText(
              AppTexts.signUp,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.kNeutral900,
            ),
            const Gap(4),
            const AppText(
              AppTexts.signUpForContinue,
              fontSize: 13.5,
              color: AppColors.kNeutral600,
            ),
            const Gap(24),
            if (!isDesktop) ...[
              firstNameField,
              const Gap(14),
              lastNameField,
              const Gap(14),
              emailField,
              const Gap(14),
              phoneField,
              const Gap(14),
              passwordField,
              const Gap(14),
              birthdayField,
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: firstNameField),
                  const Gap(16),
                  Expanded(child: lastNameField),
                ],
              ),
              const Gap(16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: emailField),
                  const Gap(16),
                  Expanded(child: phoneField),
                ],
              ),
              const Gap(16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: passwordField),
                  const Gap(16),
                  Expanded(child: birthdayField),
                ],
              ),
            ],
            const Gap(28),
            AppButton(
              leadingWidget: const Icon(Icons.person_add_alt_1_rounded, size: 20, color: AppColors.kWhiteColor),
              text: AppTexts.signUp,
              onPressed: _handleSignUp,
              width: double.infinity,
              height: 52,
              backgroundColor: AppColors.kPrimaryColor,
              textColor: AppColors.kWhiteColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              isLoading: isSignUpLoading,
            ),
            const Gap(12),
            AppButton(
              leadingWidget: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.kWhiteColor),
              text: AppTexts.signIn,
              onPressed: () => ref.read(goToSignInProvider(context)),
              width: double.infinity,
              height: 52,
              backgroundColor: AppColors.kSecondaryColor,
              textColor: AppColors.kWhiteColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBirthdayPicker extends StatelessWidget {
  const _AppBirthdayPicker({required this.birthdateController});

  final TextEditingController birthdateController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(AppTexts.birthdateLabel, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.kDark3),
        const Gap(10),
        TextFormField(
          controller: birthdateController,
          readOnly: true,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.kDark3),
          decoration: InputDecoration(
            hintText: AppTexts.birthdateHint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.kPrimary500, width: 2),
            ),
            prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20, color: AppColors.kDark3),
            suffixIcon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.kDark3),
          ),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              birthdateController.text = DateFormat('yyyy-MM-dd').format(picked);
            }
          },
          validator: (value) => ValidatorsUtil.validateBirthdate(value),
        ),
      ],
    );
  }
}

class ButtonApple extends ConsumerWidget {
  const ButtonApple({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppButton(
      text: AppTexts.appleSignInButton,
      onPressed: () => ref.read(signUpWithAppleProvider(context)),
      backgroundColor: AppColors.kWhiteColor,
      textColor: AppColors.kDark3,
      fontSize: 12,
      leadingWidget: AppImage(AdaptedFile.svg(AppAssets.appleIcon), height: 20, width: 20, fit: BoxFit.contain),
      width: double.infinity,
      borderColor: AppColors.kNeutral300,
      fontWeight: FontWeight.w600,
      isLoading: false,
    );
  }
}

class ButtonGoogle extends ConsumerWidget {
  const ButtonGoogle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppButton(
      text: AppTexts.googleSignInButton,
      onPressed: () => ref.read(signUpWithGoogleProvider(context)),
      backgroundColor: AppColors.kWhiteColor,
      textColor: AppColors.kDark3,
      fontSize: 12,
      leadingWidget: AppImage(AdaptedFile.svg(AppAssets.googleIcon), height: 20, width: 20, fit: BoxFit.contain),
      borderColor: AppColors.kNeutral300,
      fontWeight: FontWeight.w600,
      isLoading: false,
    );
  }
}
