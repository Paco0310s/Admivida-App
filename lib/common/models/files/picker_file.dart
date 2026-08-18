import 'dart:io';

import 'package:flutter/material.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:image_picker/image_picker.dart';

class PickerFile extends AdaptedFile {
  final XFile xFile;

  PickerFile({required this.xFile, super.key});

  @override
  ImageProvider<Object> get previewImageProvider => FileImage(File(xFile.path));

  @override
  Widget getWidget({BoxFit fit = BoxFit.cover, double? width, double? height}) {
    return withPreview(Image.file(File(xFile.path), fit: fit, width: width, height: height));
  }

  @override
  String getSourceDescription() => 'Picker File: ${xFile.path}';
}
