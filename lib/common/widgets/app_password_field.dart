import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:admivida/common/constants/app_colors.dart';

import 'app_text_field.dart';
import 'app_visibility_toggle.dart';

class AppPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String text;
  final double fontSize;
  final Color? textColor;
  final FontWeight fontWeight;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final void Function(String)? onChanged;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final AppTextFieldType type;

  const AppPasswordField({
    super.key,
    this.text = 'Contraseña',
    this.hintText,
    this.controller,
    this.inputFormatters,
    this.keyboardType,
    this.onChanged,
    this.prefixIcon,
    this.validator,
    this.type = AppTextFieldType.withoutBorder,
    this.fontSize = 14.0,
    this.textColor = AppColors.kPrimary500,
    this.fontWeight = FontWeight.normal,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool isObscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      text: widget.text,
      controller: widget.controller,
      validator: widget.validator,
      inputFormatters: widget.inputFormatters,
      keyboardType: widget.keyboardType,
      obscureText: isObscure,
      onChanged: widget.onChanged,
      prefixIcon: widget.prefixIcon,
      hintText: widget.hintText,
      type: widget.type,
      fontSize: widget.fontSize,
      textColor: widget.textColor,
      fontWeight: widget.fontWeight,

      suffixIcon: AppVisibilityToggle(
        isObscure: isObscure,
        onPressed: () {
          setState(() {
            isObscure = !isObscure;
          });
        },
      ),
    );
  }
}
