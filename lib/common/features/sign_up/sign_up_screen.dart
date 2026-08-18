import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:admivida/common/features/sign_up/sign_up_provider.dart';
import 'package:admivida/common/features/sign_up/models/create_user_dto.dart';
import 'package:admivida/common/constants/app_assets.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:admivida/common/utils/validators.dart';
import 'package:admivida/common/widgets/app_button.dart';
import 'package:admivida/common/widgets/app_image.dart';
import 'package:admivida/common/widgets/app_password_field.dart';
import 'package:admivida/common/widgets/app_scafffold.dart';
import 'package:admivida/common/widgets/app_text.dart';
import 'package:admivida/common/widgets/responsive.dart';
import 'package:intl/intl.dart';
import '../../widgets/app_text_field.dart';

class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      appBar: AppBar(
        title: AppText(AppTexts.signUpForContinue, color: AppColors.kTertiaryColor),
        backgroundColor: AppColors.kBackgroundColor,
      ),
      title: AppTexts.signUp,
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
    return Center(child: SignUpWidget(ponderContainers: 0, ponderForm: 100));
  }
}

class SignUpTablet extends StatelessWidget {
  final BuildContext context;

  const SignUpTablet(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Flexible(flex: 100, child: SignUpWidget(ponderContainers: 10, ponderForm: 90))],
    );
  }
}

class SignUpDesktop extends StatelessWidget {
  final BuildContext context;

  const SignUpDesktop(this.context, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(flex: 45, child: SignUpImage()),
        Flexible(flex: 55, child: SignUpWidget()),
      ],
    );
  }
}

class SignUpImage extends StatelessWidget {
  const SignUpImage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppImage(AdaptedFile.asset(AppAssets.logo), color: AppColors.kNeutral100, height: double.infinity, width: double.infinity, fit: BoxFit.contain);
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
        padding: EdgeInsets.all(20),
        child: Row(
          children: [
            Flexible(flex: ponderContainers, child: Container()),
            Flexible(flex: ponderForm, child: SignUpForm()),
            Flexible(flex: ponderContainers, child: Container()),
          ],
        ),
      ),
    );
  }
}

class SignUpForm extends ConsumerStatefulWidget {
  const SignUpForm({super.key});

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

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: AbsorbPointer(
        absorbing: isSignUpLoading,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppImage(AdaptedFile.asset(AppAssets.icon), height: 200, width: 200, fit: BoxFit.contain),
            Builder(
              builder: (context) {
                if (!Responsive.isDesktop(context)) {
                  return Column(
                    children: [
                      AppTextField(
                        text: AppTexts.firstNameLabel,
                        hintText: AppTexts.firstNameHint,
                        keyboardType: TextInputType.name,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        controller: _firstNameController,
                        validator: (value) => ValidatorsUtil.validateName(value),
                        prefixIcon: Icon(Icons.person, color: AppColors.kDark3),
                      ),
                      Gap(10),
                      AppTextField(
                        text: AppTexts.lastNameLabel,
                        hintText: AppTexts.lastNameHint,
                        keyboardType: TextInputType.name,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        controller: _lastNameController,
                        validator: (value) => ValidatorsUtil.validateLastName(value),
                        prefixIcon: Icon(Icons.person, color: AppColors.kDark3),
                      ),
                      Gap(10),
                      AppTextField(
                        text: AppTexts.emailLabel,
                        hintText: AppTexts.emailHint,
                        keyboardType: TextInputType.emailAddress,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        controller: _emailController,
                        validator: (value) => ValidatorsUtil.validateEmail(value),
                        prefixIcon: Icon(Icons.email, color: AppColors.kDark3),
                      ),
                      Gap(10),
                      AppTextField(
                        text: AppTexts.phoneLabel,
                        hintText: AppTexts.phoneHint,
                        keyboardType: TextInputType.phone,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        controller: _phoneController,
                        validator: (value) => ValidatorsUtil.validatePhone(value),
                        prefixIcon: Icon(Icons.phone, color: AppColors.kDark3),
                      ),
                      // AppPhoneField(
                      //   text: AppTexts.phoneLabel,
                      //   hintTextCode: AppTexts.codeExample,
                      //   hintTextPhone: AppTexts.phoneHint,
                      //   textColor: AppColors.kDark3,
                      //   fontSize: 14,
                      //   fontWeight: FontWeight.bold,
                      //   controllerCode: _countryCodeController,
                      //   controllerPhone: _phoneController,
                      //   prefixIcon: Icon(Icons.phone, color: AppColors.kDark3),
                      // ),
                      Gap(10),
                      AppPasswordField(
                        text: AppTexts.passwordLabel,
                        hintText: AppTexts.passwordHint,
                        keyboardType: TextInputType.visiblePassword,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        controller: _passwordController,
                        validator: (value) => ValidatorsUtil.validatePassword(value),
                        prefixIcon: Icon(Icons.lock, color: AppColors.kDark3),
                      ),
                      Gap(10),
                      _AppBirthdayPicker(birthdateController: _birthdateController),
                    ],
                  );
                }
                return GridView(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: MediaQuery.of(context).size.width * 0.00200005,
                  ),
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  children: [
                    AppTextField(
                      text: AppTexts.firstNameLabel,
                      hintText: AppTexts.firstNameHint,
                      keyboardType: TextInputType.name,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      controller: _firstNameController,
                      validator: (value) => ValidatorsUtil.validateName(value),
                      prefixIcon: Icon(Icons.person, color: AppColors.kDark3),
                    ),
                    AppTextField(
                      text: AppTexts.lastNameLabel,
                      hintText: AppTexts.lastNameHint,
                      keyboardType: TextInputType.name,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      controller: _lastNameController,
                      validator: (value) => ValidatorsUtil.validateLastName(value),
                      prefixIcon: Icon(Icons.person, color: AppColors.kDark3),
                    ),
                    AppTextField(
                      text: AppTexts.emailLabel,
                      hintText: AppTexts.emailHint,
                      keyboardType: TextInputType.emailAddress,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      controller: _emailController,
                      validator: (value) => ValidatorsUtil.validateEmail(value),
                      prefixIcon: Icon(Icons.email, color: AppColors.kDark3),
                    ),
                    AppTextField(
                      text: AppTexts.phoneLabel,
                      hintText: AppTexts.phoneHint,
                      keyboardType: TextInputType.phone,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      controller: _phoneController,
                      validator: (value) => ValidatorsUtil.validatePhone(value),
                      prefixIcon: Icon(Icons.phone, color: AppColors.kDark3),
                    ),
                    AppPasswordField(
                      text: AppTexts.passwordLabel,
                      hintText: AppTexts.passwordHint,
                      keyboardType: TextInputType.visiblePassword,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      controller: _passwordController,
                      validator: (value) => ValidatorsUtil.validatePassword(value),
                      prefixIcon: Icon(Icons.lock, color: AppColors.kDark3),
                    ),
                    _AppBirthdayPicker(birthdateController: _birthdateController),
                  ],
                );
              },
            ),
            Gap(40),
            AppButton(
              leadingWidget: Icon(Icons.person_add, size: 20, color: AppColors.kWhiteColor),
              text: AppTexts.signUp,
              onPressed: _handleSignUp,
              width: double.infinity,
              height: 55,
              backgroundColor: AppColors.kPrimaryColor,
              textColor: AppColors.kWhiteColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              isLoading: ref.watch(signUpLoadingProvider),
            ),
            Gap(10),
            AppButton(
              leadingWidget: Icon(Icons.arrow_back, size: 20, color: AppColors.kWhiteColor),
              text: AppTexts.signIn,
              onPressed: () => ref.read(goToSignInProvider(context)),
              width: double.infinity,
              height: 55,
              backgroundColor: AppColors.kSecondaryColor,
              textColor: AppColors.kWhiteColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBirthdayPicker extends StatelessWidget {
  const _AppBirthdayPicker({required this._birthdateController});

  final TextEditingController _birthdateController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(AppTexts.birthdateLabel, fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.kDark3),
        Gap(10),
        TextFormField(
          controller: _birthdateController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: AppTexts.birthdateHint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.kPrimary500, width: 2),
            ),
            prefixIcon: Icon(Icons.calendar_today, color: AppColors.kDark3),
            suffixIcon: Icon(Icons.arrow_drop_down, color: AppColors.kDark3),
          ),
          onTap: () async {
            final picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime.now());
            if (picked != null) {
              _birthdateController.text = DateFormat('yyyy-MM-dd').format(picked);
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
    // final isLoading = ref.watch(signInLoadingProvider);

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
    // final isLoading = ref.watch(signInLoadingProvider);

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
