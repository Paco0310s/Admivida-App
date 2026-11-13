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
    final bool hasBlurHash = blurHash != null && blurHash!.isNotEmpty;

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
          final bool isLoaded = frame != null;

          return Stack(
            fit: StackFit.passthrough,
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: isLoaded ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOut,
                    child: hasBlurHash
                        ? BlurHash(
                            hash: blurHash!,
                            imageFit: fit,
                            color: AppColors.kNeutral200,
                            decodingWidth: 32,
                            decodingHeight: 32,
                          )
                        : Container(
                            color: AppColors.kNeutral100,
                            child: const Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2.0),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: isLoaded ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                child: child,
              ),
            ],
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
