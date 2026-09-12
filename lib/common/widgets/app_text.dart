import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final Color? color;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;
  final FontStyle? fontStyle;

  const AppText(this.text, {super.key, this.fontSize, this.color, this.fontWeight, this.textAlign, this.overflow, this.maxLines, this.fontStyle});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: fontSize, color: color, fontWeight: fontWeight, fontStyle: fontStyle),
      textAlign: textAlign,
      overflow: overflow,
      maxLines: maxLines,
    );
  }
}
