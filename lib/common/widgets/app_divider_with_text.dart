import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/widgets/app_text.dart';

class AppDividerWithText extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double height;

  const AppDividerWithText({
    super.key,
    required this.text,
    this.color = AppColors.kNeutral300,
    this.textColor = AppColors.kDark3,
    this.fontSize = 14,
    this.fontWeight = FontWeight.normal,
    this.height = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Divider(color: color, height: height),
        ),
        Gap(10),
        AppText(text, fontSize: fontSize, color: textColor),
        Gap(10),
        Expanded(
          child: Divider(color: color, height: height),
        ),
      ],
    );
  }
}
