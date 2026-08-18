import 'dart:io';

import 'package:flutter/material.dart';
import 'package:admivida/common/models/files/adapted_file.dart';

class LocalFile extends AdaptedFile {
  final String localPath;

  LocalFile({required this.localPath, super.key});

  @override
  ImageProvider<Object> get previewImageProvider => FileImage(File(localPath));

  @override
  Widget getWidget({BoxFit fit = BoxFit.cover, double? width, double? height}) {
    return withPreview(Image.file(File(localPath), fit: fit, width: width, height: height));
  }

  @override
  String getSourceDescription() => 'Local File: $localPath';
}
