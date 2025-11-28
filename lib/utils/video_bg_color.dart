// lib/utils/video_bg_color.dart
import 'dart:io';
import 'package:palette_generator/palette_generator.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:flutter/material.dart';

Future<Color> videoDominantColor(String assetPath) async {
  // ❶ Write a 128×128 JPEG of the first frame to the cache directory
  final thumbPath = await VideoThumbnail.thumbnailFile(
    video: assetPath,
    imageFormat: ImageFormat.JPEG,
    maxHeight: 128,
    maxWidth: 128,
    quality: 25,
    timeMs: 0,          // first frame
  );

  if (thumbPath == null) return Colors.black;

  // ❷ Load it as an ImageProvider…
  final imageProvider = FileImage(File(thumbPath));

  // ❸ …and let PaletteGenerator find the dominant colour
  final palette = await PaletteGenerator.fromImageProvider(imageProvider);
  return palette.dominantColor?.color ?? Colors.black;
}
