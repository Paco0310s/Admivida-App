import 'package:flutter/material.dart';
import 'package:admivida/common/models/files/adapted_file.dart';

class AppImage extends StatelessWidget {
  final AdaptedFile fileModel;
  final Color? color;
  final double? height;
  final double? width;
  final BoxFit fit;

  const AppImage(this.fileModel, {super.key, this.height, this.width, this.fit = BoxFit.cover, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      height: height,
      width: width,
      child: fileModel.getWidget(fit: fit),
    );
  }
}
