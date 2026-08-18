import 'package:admivida/common/widgets/app_tap_text.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:admivida/common/features/sign_in/sign_in_provider.dart';
import 'package:admivida/common/features/sign_in/models/login_user_dto.dart';
import 'package:admivida/common/constants/app_assets.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/utils/validators.dart';
import 'package:admivida/common/widgets/app_button.dart';
import 'package:admivida/common/widgets/app_image.dart';
import 'package:admivida/common/widgets/app_password_field.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text_field.dart';

class SignInScreen extends ConsumerWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // final isLoading = ref.watch(signInLoadingProvider);

    return AppScaffold(
      appBar: AppBar(
        title: AppText(AppTexts.signInForContinue, color: AppColors.kTertiaryColor),
        backgroundColor: AppColors.kBackgroundColor,
      ),
      title: AppTexts.signIn,
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
    return Center(child: SignInWidget(ponderContainers: 0, ponderForm: 100));
  }
}

class SignInTablet extends StatelessWidget {
  final BuildContext context;

  const SignInTablet(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(flex: 100, child: SignInWidget(ponderContainers: 10, ponderForm: 90)),
        // Flexible(flex: 30, child: SignInImage()),
      ],
    );
  }
}

class SignInDesktop extends StatelessWidget {
  final BuildContext context;

  const SignInDesktop(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(flex: 45, child: SignInImage()),
        Flexible(flex: 55, child: SignInWidget()),
      ],
    );
  }
}

class SignInImage extends StatelessWidget {
  const SignInImage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppImage(AdaptedFile.local(AppAssets.logo), height: double.infinity, width: double.infinity, fit: BoxFit.contain);
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
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Flexible(flex: ponderContainers, child: Container()),
            Flexible(flex: ponderForm, child: SignInForm()),
            Flexible(flex: ponderContainers, child: Container()),
          ],
        ),
      ),
    );
  }
}

class SignInForm extends ConsumerStatefulWidget {
  const SignInForm({super.key});

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
      final emailOrPhone = _emailOrPhoneController.text.trim();
      final password = _passwordController.text;

      final LoginUserDto loginUserDto = LoginUserDto(emailOrPhone: emailOrPhone, password: password);

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
          children: [
            AppImage(AdaptedFile.asset(AppAssets.icon), height: 200, width: 200, fit: BoxFit.contain),
            AppTextField(
              text: AppTexts.emailOrPhoneLabel,
              hintText: AppTexts.emailOrPhoneHint,
              keyboardType: TextInputType.text,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              controller: _emailOrPhoneController,
              validator: (value) => ValidatorsUtil.validateEmailOrPhone(value),
              prefixIcon: Icon(Icons.email, size: 20, color: AppColors.kDark3),
            ),
            Gap(20),
            AppPasswordField(
              text: AppTexts.passwordLabel,
              hintText: AppTexts.passwordHint,
              keyboardType: TextInputType.visiblePassword,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              controller: _passwordController,
              validator: (value) => ValidatorsUtil.validatePassword(value),
              prefixIcon: Icon(Icons.lock, size: 20, color: AppColors.kDark3),
            ),
            Gap(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [AppTapText(text: AppTexts.forgotPasswordTitle, onTap: () => ref.read(goToForgotPasswordProvider(context)))],
            ),
            Gap(40),
            AppButton(
              leadingWidget: Icon(Icons.login, size: 20),
              text: AppTexts.signIn,
              onPressed: _handleSignIn,
              width: double.infinity,
              height: 55,
              backgroundColor: AppColors.kPrimaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              isLoading: isLoading,
            ),
            Gap(10),
            AppButton(
              leadingWidget: Icon(Icons.arrow_forward, size: 20),
              text: AppTexts.signUp,
              onPressed: () => ref.read(goToSignUpProvider(context)),
              width: double.infinity,
              height: 55,
              backgroundColor: AppColors.kSecondaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
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
    // final isLoading = ref.watch(signInLoadingProvider);

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
    // final isLoading = ref.watch(signInLoadingProvider);

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
