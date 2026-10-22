import 'package:admivida/common/services/external_link_service.dart';

import 'package:admivida/common/widgets/floating_whatsapp_button.dart';

import 'package:admivida/common/constants/app_assets.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/features/sign_in/models/login_user_dto.dart';
import 'package:admivida/common/features/sign_in/sign_in_provider.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/utils/validators.dart';
import 'package:admivida/common/widgets/app_button.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_image.dart';
import 'package:admivida/common/widgets/app_password_field.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_tap_text.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      showAppBar: false,
      showDashboardShell: false,
      title: AppTexts.signIn,
      floatingActionButton: const FloatingWhatsAppButton(heroTag: 'signin_whatsapp_fab'),
      mobile: SignInMobile(context),
      tablet: SignInTablet(context),
      desktop: SignInDesktop(context),
      marginDesktop: 0,
      marginTablet: 0,
    );
  }
}

class SignInMobile extends StatelessWidget {
  final BuildContext context;

  const SignInMobile(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: SignInForm(showHeaderLogo: true),
      ),
    );
  }
}

class SignInTablet extends StatelessWidget {
  final BuildContext context;

  const SignInTablet(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: const AppCard(
            padding: EdgeInsets.all(32),
            child: SignInForm(showHeaderLogo: true),
          ),
        ),
      ),
    );
  }
}

class SignInDesktop extends StatelessWidget {
  final BuildContext context;

  const SignInDesktop(this.context, {super.key});

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
            padding: const EdgeInsets.all(48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                    height: 64,
                    width: 64,
                    fit: BoxFit.contain,
                  ),
                ),
                const Gap(28),
                const AppText(
                  AppTexts.appName,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                const Gap(10),
                const AppText(
                  'Plataforma integral de administración de negocios, punto de venta (POS), control de inventario y gestión financiera.',
                  fontSize: 16,
                  color: Color(0xE0FFFFFF),
                ),
                const Gap(32),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const [
                    _FeatureBadge(icon: Icons.point_of_sale_rounded, label: 'Punto de Venta Rápido'),
                    _FeatureBadge(icon: Icons.inventory_2_rounded, label: 'Control de Inventario'),
                    _FeatureBadge(icon: Icons.account_balance_wallet_rounded, label: 'Cuentas y Finanzas'),
                  ],
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
                  child: SignInForm(showHeaderLogo: false),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.kPrimary100, size: 17),
          const Gap(8),
          AppText(label, fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w500),
        ],
      ),
    );
  }
}

class SignInImage extends StatelessWidget {
  const SignInImage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppImage(AdaptedFile.asset(AppAssets.logo), height: double.infinity, width: double.infinity, fit: BoxFit.contain);
  }
}

class SignInWidget extends StatelessWidget {
  final int ponderContainers;
  final int ponderForm;

  const SignInWidget({super.key, this.ponderContainers = 20, this.ponderForm = 60});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Flexible(flex: ponderContainers, child: Container()),
            Flexible(flex: ponderForm, child: const SignInForm()),
            Flexible(flex: ponderContainers, child: Container()),
          ],
        ),
      ),
    );
  }
}

class SignInForm extends ConsumerStatefulWidget {
  final bool showHeaderLogo;

  const SignInForm({super.key, this.showHeaderLogo = true});

  @override
  ConsumerState<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      final emailOrPhoneInput = _emailOrPhoneController.text.trim();
      String finalEmailOrPhone = emailOrPhoneInput;

      // 1. Check if the input is a raw phone number (does not contain '@' and does not start with '+')
      if (!emailOrPhoneInput.contains('@') && !emailOrPhoneInput.startsWith('+')) {
        // It is a raw phone number, so we prepend the country code '+52' and remove any spaces
        final noSpaces = emailOrPhoneInput.replaceAll(' ', '');
        finalEmailOrPhone = '+52 $noSpaces';
      }

      final password = _passwordController.text;

      final LoginUserDto loginUserDto = LoginUserDto(emailOrPhone: finalEmailOrPhone, password: password);

      ref.read(signInLoadingProvider.notifier).setLoading(true);
      await ref.read(signInProvider(context, loginUserDto).future);
      ref.read(signInLoadingProvider.notifier).setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(signInLoadingProvider);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: AbsorbPointer(
        absorbing: isLoading,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showHeaderLogo) ...[
              Center(
                child: AppImage(
                  AdaptedFile.asset(AppAssets.icon),
                  height: 120,
                  width: 120,
                  fit: BoxFit.contain,
                ),
              ),
              const Gap(16),
            ],
            const AppText(
              AppTexts.signIn,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.kNeutral900,
            ),
            const Gap(4),
            const AppText(
              AppTexts.signInForContinue,
              fontSize: 13.5,
              color: AppColors.kNeutral600,
            ),
            const Gap(24),
            AppTextField(
              text: AppTexts.emailOrPhoneLabel,
              hintText: AppTexts.emailOrPhoneHint,
              keyboardType: TextInputType.text,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              controller: _emailOrPhoneController,
              validator: (value) => ValidatorsUtil.validateEmailOrPhone(value),
              prefixIcon: const Icon(Icons.email_rounded, size: 20, color: AppColors.kDark3),
            ),
            const Gap(18),
            AppPasswordField(
              text: AppTexts.passwordLabel,
              hintText: AppTexts.passwordHint,
              keyboardType: TextInputType.visiblePassword,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              controller: _passwordController,
              validator: (value) => ValidatorsUtil.validatePassword(value),
              prefixIcon: const Icon(Icons.lock_rounded, size: 20, color: AppColors.kDark3),
            ),
            const Gap(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppTapText(
                  text: AppTexts.forgotPasswordTitle,
                  onTap: () => ref.read(goToForgotPasswordProvider(context)),
                ),
              ],
            ),
            const Gap(28),
            AppButton(
              leadingWidget: const Icon(Icons.login_rounded, size: 20),
              text: AppTexts.signIn,
              onPressed: _handleSignIn,
              width: double.infinity,
              height: 52,
              backgroundColor: AppColors.kPrimaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              isLoading: isLoading,
            ),
            const Gap(12),
            AppButton(
              leadingWidget: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              text: AppTexts.signUp,
              onPressed: () => ref.read(goToSignUpProvider(context)),
              width: double.infinity,
              height: 52,
              backgroundColor: AppColors.kSecondaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            const Gap(18),
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  InkWell(
                    onTap: () => ExternalLinkService.openAdmividaWeb(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.download_rounded, size: 14, color: AppColors.kPrimaryColor),
                        Gap(4),
                        AppText(
                          'Descargar Windows / Android',
                          fontSize: 12,
                          color: AppColors.kPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ],
                    ),
                  ),
                  const AppText('•', fontSize: 12, color: AppColors.kNeutral400),
                  InkWell(
                    onTap: () => ExternalLinkService.openPortfolio(),
                    child: const AppText(
                      'Por Francisco Sotelo',
                      fontSize: 12,
                      color: AppColors.kNeutral500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ButtonApple extends ConsumerWidget {
  const ButtonApple({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppButton(
      text: 'Use Apple',
      onPressed: () => ref.read(signInWithAppleProvider(context)),
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
      onPressed: () => ref.read(signInWithGoogleProvider(context)),
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
