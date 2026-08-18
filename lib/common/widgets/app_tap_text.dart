import 'package:flutter/material.dart';
import 'package:admivida/common/constants/app_colors.dart';

import 'app_text.dart';

class AppTapText extends StatelessWidget {
  final String text;
  final Color color;
  final FontWeight fontWeight;
  final double fontSize;
  final void Function() onTap;

  const AppTapText({
    super.key,
    required this.text,
    required this.onTap,
    this.color = AppColors.kPrimary500,
    this.fontWeight = FontWeight.bold,
    this.fontSize = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AppText(text, color: color, fontWeight: fontWeight, fontSize: fontSize),
    );
  }
}
