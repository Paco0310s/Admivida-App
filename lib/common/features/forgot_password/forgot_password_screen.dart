import 'package:admivida/common/features/sign_up/sign_up_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:admivida/common/features/forgot_password/forgot_password_provider.dart';
import 'package:admivida/common/features/sign_in/sign_in_provider.dart';
import 'package:admivida/common/constants/app_assets.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/utils/validators.dart';
import 'package:admivida/common/widgets/app_button.dart';
import 'package:admivida/common/widgets/app_image.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/app_text_field.dart';

class ForgotPasswordScreen extends ConsumerWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final isLoading = ref.watch(signInLoadingProvider);

    return AppScaffold(
      appBar: AppBar(
        title: AppText(AppTexts.forgotPasswordTitle, color: AppColors.kTertiaryColor),
        backgroundColor: AppColors.kBackgroundColor,
      ),
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
    return Center(child: ForgotPasswordWidget(ponderContainers: 0, ponderForm: 100));
  }
}

class ForgotPasswordTablet extends StatelessWidget {
  final BuildContext context;

  const ForgotPasswordTablet(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Flexible(flex: 30, child: ForgotPasswordImage()),
        Flexible(flex: 100, child: ForgotPasswordWidget(ponderContainers: 10, ponderForm: 90)),
      ],
    );
  }
}

class ForgotPasswordDesktop extends StatelessWidget {
  final BuildContext context;

  const ForgotPasswordDesktop(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(flex: 50, child: ForgotPasswordImage()),
        Flexible(flex: 45, child: ForgotPasswordWidget(ponderContainers: 10, ponderForm: 90)),
      ],
    );
  }
}

class ForgotPasswordImage extends StatelessWidget {
  const ForgotPasswordImage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppImage(AdaptedFile.asset(AppAssets.logo), color: AppColors.kNeutral100, height: double.infinity, width: double.infinity, fit: BoxFit.contain);
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
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Flexible(flex: ponderContainers, child: Container()),
            Flexible(flex: ponderForm, child: ForgotPasswordForm()),
            Flexible(flex: ponderContainers, child: Container()),
          ],
        ),
      ),
    );
  }
}

class ForgotPasswordForm extends ConsumerStatefulWidget {
  const ForgotPasswordForm({super.key});

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
    // final isLoginLoading = ref.watch(signInLoadingProvider);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: AbsorbPointer(
        absorbing: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(AppTexts.forgotPasswordTitle, fontSize: 22, fontWeight: FontWeight.bold),
            Gap(20),
            AppTextField(
              text: AppTexts.emailLabel,
              hintText: AppTexts.emailHint,
              keyboardType: TextInputType.emailAddress,
              textColor: AppColors.kDark3,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              controller: _emailController,
              validator: (value) => ValidatorsUtil.validateEmail(value),
            ),
            Gap(20),
            AppButton(
              text: AppTexts.sendResetLink,
              onPressed: _handleForgotPassword,
              width: double.infinity,
              height: 50,
              backgroundColor: AppColors.kPrimary500,
              textColor: AppColors.kWhiteColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              isLoading: false,
            ),
            Gap(10),
            AppButton(
              text: AppTexts.backToSignIn,
              onPressed: () => ref.read(goToSignInProvider(context)),
              width: double.infinity,
              height: 50,
              backgroundColor: AppColors.kNeutral200,
              textColor: AppColors.kPrimary600,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              isLoading: false,
            ),
            Gap(20),
            RichText(
              text: TextSpan(
                text: AppTexts.dontHaveAccount,
                style: TextStyle(fontSize: 16, color: AppColors.kDark3),
                children: [
                  TextSpan(
                    recognizer: TapGestureRecognizer()..onTap = () => ref.read(goToSignUpProvider(context)),
                    text: ' ${AppTexts.signUp}',
                    style: TextStyle(fontSize: 16, color: AppColors.kPrimary500),
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
