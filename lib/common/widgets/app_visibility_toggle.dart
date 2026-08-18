import 'package:flutter/material.dart';
import 'package:admivida/common/constants/app_colors.dart';

class AppVisibilityToggle extends StatelessWidget {
  final bool isObscure;
  final void Function() onPressed;

  const AppVisibilityToggle({super.key, required this.isObscure, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: AppColors.kDark3),
      onPressed: onPressed,
    );
  }
}
