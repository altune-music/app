import 'package:jiosaavn/jiosaavn.dart';

class ImageQualityHelper {
  static String? getImageUrl(
    List<DownloadLink>? images, {
    int targetWidth = 500,
  }) {
    if (images == null || images.isEmpty) return null;

    return images
        .firstWhere(
          (img) => img.quality.contains(targetWidth.toString()),
          orElse: () => images.last,
        )
        .link;
  }

  static String? getExtraSmallImageUrl(List<DownloadLink>? images) {
    return getImageUrl(images, targetWidth: 50);
  }

  static String? getSmallImageUrl(List<DownloadLink>? images) {
    return getImageUrl(images, targetWidth: 150);
  }

  static String? getMediumImageUrl(List<DownloadLink>? images) {
    return getImageUrl(images, targetWidth: 500);
  }

  static String? getLargeImageUrl(List<DownloadLink>? images) {
    return getHighestQualityImageUrl(images);
  }

  static String? getHighestQualityImageUrl(List<DownloadLink>? images) {
    if (images == null || images.isEmpty) return null;
    DownloadLink best = images.first;
    int bestQuality = 0;
    for (final img in images) {
      final q = int.tryParse(img.quality.replaceAll(RegExp(r'[^0-9]'), ''));
      final quality = q ?? 0;
      if (quality > bestQuality) {
        bestQuality = quality;
        best = img;
      }
    }
    return best.link;
  }

  // ponytail: generic alias — same logic as image helper, works for audio links too
  static String? getHighestQualityLink(List<DownloadLink>? links) {
    return getHighestQualityImageUrl(links);
  }

  // ponytail: returns the full DownloadLink when callers need bitrate/quality too
  static DownloadLink? getHighestQualityDownloadLink(
    List<DownloadLink>? links,
  ) {
    if (links == null || links.isEmpty) return null;
    DownloadLink best = links.first;
    int bestQuality = 0;
    for (final link in links) {
      final q = int.tryParse(link.quality.replaceAll(RegExp(r'[^0-9]'), ''));
      final quality = q ?? 0;
      if (quality > bestQuality) {
        bestQuality = quality;
        best = link;
      }
    }
    return best;
  }
}
