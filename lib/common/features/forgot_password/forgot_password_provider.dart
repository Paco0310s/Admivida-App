import 'package:flutter/material.dart';
import 'package:admivida/common/constants/app_texts.dart';
import 'package:admivida/common/routes/routes.dart';
import 'package:admivida/common/services/navigation_service.dart';
import 'package:admivida/common/utils/snackbar_util.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'forgot_password_provider.g.dart';

@riverpod
Future<void> sendResetLink(Ref ref, BuildContext context, String email) async {
  SnackbarUtil.showSuccess(context, '${AppTexts.passwordResetLinkSent} $email');
  NavigationService.replaceWith(context, Routes.signIn);
}
