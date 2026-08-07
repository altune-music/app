import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ArtworkImage extends StatelessWidget {
  final String? imagePath;
  final String? imageUrl;
  final double size;
  final double borderRadius;

  const ArtworkImage({
    super.key,
    this.imagePath,
    this.imageUrl,
    this.size = 40,
    this.borderRadius = 4,
  });

  static Widget placeholder(BuildContext context, double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Icon(Icons.music_note, size: width * 0.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(width: size, height: size, child: _buildImage(context)),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (imagePath != null && imagePath!.isNotEmpty) {
      final file = File(imagePath!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              ArtworkImage.placeholder(context, size, size),
        );
      }
    }

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) =>
            ArtworkImage.placeholder(context, size, size),
        errorWidget: (context, url, error) =>
            ArtworkImage.placeholder(context, size, size),
      );
    }

    return ArtworkImage.placeholder(context, size, size);
  }
}
