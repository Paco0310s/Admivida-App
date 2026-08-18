import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:admivida/common/models/files/asset_file.dart';
import 'package:admivida/common/models/files/local_file.dart';
import 'package:admivida/common/models/files/network_file.dart';
import 'package:admivida/common/models/files/svg_file.dart';
import 'package:image_picker/image_picker.dart';

abstract class AdaptedFile {
  final Key? key; // Unique identifier for the file, useful for widget keys

  AdaptedFile({this.key});

  /// Abstract method to get a widget representation
  Widget getWidget({BoxFit fit = BoxFit.cover, double? width, double? height});

  ImageProvider<Object>? get previewImageProvider => null;
  Widget? get previewChild => null;

  Widget withPreview(Widget child) {
    if (previewImageProvider == null && previewChild == null) return child;

    return Builder(
      builder: (context) => GestureDetector(onTap: () => _showPreview(context), child: child),
    );
  }

  void _showPreview(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => Material(
        color: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              if (previewImageProvider != null)
                PhotoView(
                  imageProvider: previewImageProvider,
                  backgroundDecoration: const BoxDecoration(color: Colors.black),
                )
              else
                PhotoView.customChild(
                  backgroundDecoration: const BoxDecoration(color: Colors.black),
                  child: previewChild!,
                ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Cerrar imagen',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String getSourceDescription();

  static AssetFile asset(String assetPath) {
    return AssetFile(assetPath: assetPath);
  }

  static LocalFile local(String localPath) {
    return LocalFile(localPath: localPath);
  }

  static NetworkFile network(String url, {String? blurHash}) {
    return NetworkFile(url: url, blurHash: blurHash);
  }

  static PickedFile picked(String path) {
    return PickedFile(path);
  }

  static SvgFile svg(String assetPath, {ColorFilter? colorFilter}) {
    return SvgFile(assetPath: assetPath, colorFilter: colorFilter);
  }

  static AdaptedFile from(AdaptedFile file) {
    return file;
  }
}
