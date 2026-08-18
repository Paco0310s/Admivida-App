import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:admivida/common/models/files/adapted_file.dart';

class SvgFile extends AdaptedFile {
  final String assetPath;
  ColorFilter? colorFilter;

  SvgFile({required this.assetPath, this.colorFilter, super.key});

  @override
  Widget get previewChild => SvgPicture.asset(assetPath, colorFilter: colorFilter);

  @override
  Widget getWidget({BoxFit fit = BoxFit.cover, double? width, double? height}) {
    return withPreview(SvgPicture.asset(assetPath, fit: fit, width: width, height: height, colorFilter: colorFilter));
  }

  @override
  String getSourceDescription() => 'SVG File: $assetPath';
}
