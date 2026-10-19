import 'package:admivida/common/constants/app_assets.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/features/forgot_password/forgot_password_provider.dart';
import 'package:admivida/common/features/sign_in/sign_in_provider.dart';
import 'package:admivida/common/features/sign_up/sign_up_provider.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/utils/validators.dart';
import 'package:admivida/common/widgets/app_button.dart';
import 'package:admivida/common/widgets/app_card.dart';
import 'package:admivida/common/widgets/app_image.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/app_text_field.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

class ForgotPasswordScreen extends ConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      showAppBar: false,
      showDashboardShell: false,
      title: AppTexts.forgotPasswordTitle,
      mobile: ForgotPasswordMobile(context),
      tablet: ForgotPasswordTablet(context),
      desktop: ForgotPasswordDesktop(context),
      marginDesktop: 0,
      marginTablet: 0,
    );
  }
}

class ForgotPasswordMobile extends StatelessWidget {
  final BuildContext context;

  const ForgotPasswordMobile(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: ForgotPasswordForm(showHeaderLogo: true),
      ),
    );
  }
}

class ForgotPasswordTablet extends StatelessWidget {
  final BuildContext context;

  const ForgotPasswordTablet(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: const AppCard(
            padding: EdgeInsets.all(32),
            child: ForgotPasswordForm(showHeaderLogo: true),
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordDesktop extends StatelessWidget {
  final BuildContext context;

  const ForgotPasswordDesktop(this.context, {super.key});

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
                  '¿Olvidaste tu contraseña? Ingresa tu correo electrónico y te enviaremos un enlace seguro para restablecer tu acceso.',
                  fontSize: 14.5,
                  color: Color(0xE0FFFFFF),
                ),
                const Gap(28),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_reset_rounded, color: AppColors.kPrimary100, size: 18),
                      Gap(10),
                      Flexible(
                        child: AppText(
                          'Recuperación rápida por correo',
                          fontSize: 12.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
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
                  child: ForgotPasswordForm(showHeaderLogo: false),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ForgotPasswordImage extends StatelessWidget {
  const ForgotPasswordImage({super.key});

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

class ForgotPasswordWidget extends StatelessWidget {
  final int ponderContainers;
  final int ponderForm;

  const ForgotPasswordWidget({super.key, this.ponderContainers = 20, this.ponderForm = 60});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Flexible(flex: ponderContainers, child: Container()),
            Flexible(flex: ponderForm, child: const ForgotPasswordForm()),
            Flexible(flex: ponderContainers, child: Container()),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordForm extends ConsumerStatefulWidget {
  final bool showHeaderLogo;

  const ForgotPasswordForm({super.key, this.showHeaderLogo = true});

  @override
  ConsumerState<ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends ConsumerState<ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleForgotPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      final email = _emailController.text.trim();

      if (email.isNotEmpty) {
        ref.read(sendResetLinkProvider(context, email));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: AbsorbPointer(
        absorbing: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showHeaderLogo) ...[
              Center(
                child: AppImage(
                  AdaptedFile.asset(AppAssets.icon),
                  height: 110,
                  width: 110,
                  fit: BoxFit.contain,
                ),
              ),
              const Gap(16),
            ],
            const AppText(
              AppTexts.forgotPasswordTitle,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.kNeutral900,
            ),
            const Gap(6),
            const AppText(
              'Ingresa el correo asociado a tu cuenta para recibir instrucciones de recuperación.',
              fontSize: 13.5,
              color: AppColors.kNeutral600,
            ),
            const Gap(24),
            AppTextField(
              text: AppTexts.emailLabel,
              hintText: AppTexts.emailHint,
              keyboardType: TextInputType.emailAddress,
              textColor: AppColors.kDark3,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              controller: _emailController,
              validator: (value) => ValidatorsUtil.validateEmail(value),
              prefixIcon: const Icon(Icons.email_rounded, size: 20, color: AppColors.kDark3),
            ),
            const Gap(28),
            AppButton(
              leadingWidget: const Icon(Icons.send_rounded, size: 19, color: AppColors.kWhiteColor),
              text: AppTexts.sendResetLink,
              onPressed: _handleForgotPassword,
              width: double.infinity,
              height: 52,
              backgroundColor: AppColors.kPrimaryColor,
              textColor: AppColors.kWhiteColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              isLoading: false,
            ),
            const Gap(12),
            AppButton(
              leadingWidget: const Icon(Icons.arrow_back_rounded, size: 19, color: AppColors.kWhiteColor),
              text: AppTexts.backToSignIn,
              onPressed: () => ref.read(goToSignInProvider(context)),
              width: double.infinity,
              height: 52,
              backgroundColor: AppColors.kSecondaryColor,
              textColor: AppColors.kWhiteColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              isLoading: false,
            ),
            const Gap(22),
            Center(
              child: RichText(
                text: TextSpan(
                  text: AppTexts.dontHaveAccount,
                  style: const TextStyle(fontSize: 14, color: AppColors.kNeutral700),
                  children: [
                    TextSpan(
                      recognizer: TapGestureRecognizer()..onTap = () => ref.read(goToSignUpProvider(context)),
                      text: ' ${AppTexts.signUp}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.kPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
