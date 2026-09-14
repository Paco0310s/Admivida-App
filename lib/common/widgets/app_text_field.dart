import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:admivida/common/constants/app_colors.dart';

import 'app_text.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String text;
  final double fontSize;
  final Color? textColor;
  final FontWeight fontWeight;
  final String? hintText;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final bool obscureText;
  final void Function(String)? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final AppTextFieldType type;
  final int maxLines;
  final bool isRequired;
  final bool readOnly;
  final void Function()? onTap;

  const AppTextField({
    super.key,
    required this.text,
    this.maxLines = 1,
    this.hintText,
    this.controller,
    this.inputFormatters,
    this.keyboardType,
    this.obscureText = false,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.type = AppTextFieldType.withoutBorder,
    this.fontSize = 14.0,
    this.textColor = AppColors.kPrimary500,
    this.fontWeight = FontWeight.normal,
    this.isRequired = false,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (type == AppTextFieldType.withoutBorder) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              AppText(text, color: textColor, fontSize: fontSize, fontWeight: fontWeight),
              if (isRequired) ...[const Gap(4), AppText('*', color: Colors.red, fontSize: fontSize, fontWeight: fontWeight)],
            ],
          ),
          const Gap(10),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            decoration: InputDecoration(
              hintText: hintText,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.kPrimary500, width: 2),
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
            ),
            cursorColor: AppColors.kPrimary500,
            validator: validator,
            inputFormatters: inputFormatters,
            keyboardType: keyboardType,
            obscureText: obscureText,
            onChanged: onChanged,
          ),
        ],
      );
    }

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        // filled: true,
        // fillColor: AppColors.accent.withOpacity(0.1),
        label: isRequired
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(text, color: AppColors.kPrimary500),
                  const Gap(2),
                  AppText('*', color: Colors.red),
                ],
              )
            : Text(text),
        floatingLabelStyle: const TextStyle(color: AppColors.kPrimary500),

        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.kPrimary500, width: 2),
        ),
      ),
      cursorColor: AppColors.kPrimary500,
      validator: validator,
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
    );
  }
}

enum AppTextFieldType { withBorder, withoutBorder }
