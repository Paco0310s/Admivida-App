import 'package:flutter/material.dart';
import 'package:admivida/common/models/files/adapted_file.dart';

class AssetFile extends AdaptedFile {
  final String assetPath; // Asset path for the image, e.g., 'assets/images/photo.png'

  AssetFile({required this.assetPath, super.key});

  @override
  ImageProvider<Object> get previewImageProvider => AssetImage(assetPath);

  @override
  Widget getWidget({BoxFit fit = BoxFit.cover, double? width, double? height}) {
    return withPreview(Image.asset(assetPath, fit: fit, width: width, height: height));
  }

  @override
  String getSourceDescription() => 'Asset File: $assetPath';
}
