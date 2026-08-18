import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:admivida/common/constants/app_colors.dart';
import 'package:admivida/common/models/files/adapted_file.dart';

class NetworkFile extends AdaptedFile {
  final String url;
  final String? blurHash;

  NetworkFile({required this.url, this.blurHash, super.key});

  @override
  ImageProvider<Object> get previewImageProvider => NetworkImage(url);

  @override
  Widget getWidget({BoxFit fit = BoxFit.cover, double? width, double? height, double borderRadius = 10}) {
    final imageWidget = SizedBox(
      width: width,
      height: height,
      child: Image.network(
        url,
        fit: fit,
        width: width,
        height: height,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(opacity: frame == null ? 0.0 : 1.0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut, child: child);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;

          if (blurHash != null && blurHash!.isNotEmpty) {
            return BlurHash(hash: blurHash!, imageFit: fit);
          }

          return Container(
            width: width,
            height: height,
            color: AppColors.kNeutral200,
            child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.0))),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: AppColors.kNeutral200,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.broken_image_rounded, color: AppColors.kNeutral400, size: 28)],
            ),
          );
        },
      ),
    );

    if (borderRadius > 0) {
      return withPreview(ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: imageWidget));
    }

    return withPreview(imageWidget);
  }

  @override
  String getSourceDescription() => 'Network File: $url${blurHash != null ? " (with BlurHash)" : ""}';
}
