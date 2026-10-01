import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:admivida/common/models/files/adapted_file.dart';
import 'package:image_picker/image_picker.dart';

class PickerFile extends AdaptedFile {
  final XFile xFile;

  PickerFile({required this.xFile, super.key});

  @override
  Widget getWidget({BoxFit fit = BoxFit.cover, double? width, double? height}) {
    return _PickedFileImage(xFile: xFile, fit: fit, width: width, height: height);
  }

  @override
  String getSourceDescription() => 'Picker File: ${xFile.path}';
}

class _PickedFileImage extends StatefulWidget {
  final XFile xFile;
  final BoxFit fit;
  final double? width;
  final double? height;

  const _PickedFileImage({required this.xFile, required this.fit, this.width, this.height});

  @override
  State<_PickedFileImage> createState() => _PickedFileImageState();
}

class _PickedFileImageState extends State<_PickedFileImage> {
  late Future<Uint8List> _bytesFuture;

  @override
  void initState() {
    super.initState();
    _bytesFuture = widget.xFile.readAsBytes();
  }

  @override
  void didUpdateWidget(covariant _PickedFileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.xFile.path != widget.xFile.path) {
      _bytesFuture = widget.xFile.readAsBytes();
    }
  }

  void _showPreview(ImageProvider<Object> imageProvider) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => Material(
        color: Colors.black,
        child: SafeArea(
          child: Stack(
            children: [
              PhotoView(
                imageProvider: imageProvider,
                backgroundDecoration: const BoxDecoration(color: Colors.black),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _bytesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final bytes = snapshot.data;
        if (snapshot.hasError || bytes == null) {
          return const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey));
        }

        final imageProvider = MemoryImage(bytes);
        return GestureDetector(
          onTap: () => _showPreview(imageProvider),
          child: Image(image: imageProvider, fit: widget.fit, width: widget.width, height: widget.height),
        );
      },
    );
  }
}
