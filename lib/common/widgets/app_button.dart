// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/constants/app_texts.dart';

import 'app_loading_widget.dart';
import 'app_text.dart';

class AppButton extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isLoading;
  final double fontSize;
  final Widget? leadingWidget;
  final double width;
  final double height;
  final double elevation;
  final Color? borderColor;
  final FontWeight fontWeight;
  final Function() onPressed;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = AppColors.kPrimary500,
    this.textColor = AppColors.kWhiteColor,
    this.isLoading = false,
    this.fontSize = 16.0,
    this.leadingWidget,
    this.width = double.infinity,
    this.height = 50.0,
    this.elevation = 0.0,
    this.borderColor,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        disabledBackgroundColor: backgroundColor?.withAlpha(200),
        minimumSize: Size(width, height),
        maximumSize: Size(width, height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        foregroundColor: textColor,
        elevation: elevation,
        side: borderColor != null ? BorderSide(color: borderColor!, width: 1.0) : BorderSide.none,
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const LoadingButton()
          : Builder(
              builder: (context) {
                if (leadingWidget != null) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(flex: 10, child: leadingWidget!),
                      Flexible(flex: 5, child: Container()),
                      Flexible(
                        flex: 85,
                        child: AppText(text, fontSize: fontSize, fontWeight: fontWeight),
                      ),
                    ],
                  );
                }
                return AppText(text, fontSize: fontSize, fontWeight: fontWeight);
              },
            ),
    );
  }
}

class LoadingButton extends StatefulWidget {
  const LoadingButton({super.key});

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1200), vsync: this)..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBouncingText() {
    const text = AppTexts.loading;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(text.length, (i) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // There's a 0.2s delay between each letter, so we add (i * 0.2) to the animation value
            final t = (_controller.value + (i * 0.2)) % 1.0;
            final offset = -4 * (1 - ((t * 2 - 1).abs()));
            return Transform.translate(
              offset: Offset(0, offset),
              child: Text(
                text[i],
                style: const TextStyle(color: AppColors.kWhiteColor, fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: 0.2),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildBouncingDot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // We use a 0.2s delay between each dot, so we add (index * 0.2) to the animation value
        final t = (_controller.value + (index * 0.2)) % 1.0;
        final scale = 1.0 + 0.4 * (1 - ((t * 2 - 1).abs()));
        return Transform.scale(
          scale: scale,
          child: Text(
            '.',
            style: const TextStyle(color: AppColors.kWhiteColor, fontWeight: FontWeight.w600, fontSize: 22, letterSpacing: 0.2),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 30, height: 30, child: AppLoadingWidget(color: AppColors.kWhiteColor)),
        // SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.kWhiteColor))),
        // const SizedBox(width: 12),
        // _buildBouncingText(),
        // ...List.generate(3, (i) => _buildBouncingDot(i)),
      ],
    );
  }
}
