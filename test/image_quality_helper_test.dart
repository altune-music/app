import 'package:flutter_test/flutter_test.dart';
import 'package:jiosaavn/jiosaavn.dart';
import 'package:altune/utils/image_quality_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageQualityHelper.getHighestQualityImageUrl', () {
    test('returns null for null images', () {
      expect(ImageQualityHelper.getHighestQualityImageUrl(null), isNull);
    });

    test('returns null for empty images list', () {
      expect(ImageQualityHelper.getHighestQualityImageUrl([]), isNull);
    });

    test('returns the link for a single image', () {
      final images = [
        DownloadLink(quality: '500', link: 'https://example.com/500.jpg'),
      ];
      expect(
        ImageQualityHelper.getHighestQualityImageUrl(images),
        'https://example.com/500.jpg',
      );
    });

    test('selects the image with the highest numeric quality', () {
      final images = [
        DownloadLink(quality: '50', link: 'https://example.com/50.jpg'),
        DownloadLink(quality: '150', link: 'https://example.com/150.jpg'),
        DownloadLink(quality: '500', link: 'https://example.com/500.jpg'),
      ];
      expect(
        ImageQualityHelper.getHighestQualityImageUrl(images),
        'https://example.com/500.jpg',
      );
    });

    test('handles quality strings with non-numeric suffixes', () {
      final images = [
        DownloadLink(quality: '50x50', link: 'https://example.com/50.jpg'),
        DownloadLink(quality: '150x150', link: 'https://example.com/150.jpg'),
        DownloadLink(quality: '500x500', link: 'https://example.com/500.jpg'),
      ];
      expect(
        ImageQualityHelper.getHighestQualityImageUrl(images),
        'https://example.com/500.jpg',
      );
    });

    test('handles unsorted image lists', () {
      final images = [
        DownloadLink(quality: '500', link: 'https://example.com/500.jpg'),
        DownloadLink(quality: '50', link: 'https://example.com/50.jpg'),
        DownloadLink(quality: '150', link: 'https://example.com/150.jpg'),
      ];
      expect(
        ImageQualityHelper.getHighestQualityImageUrl(images),
        'https://example.com/500.jpg',
      );
    });

    test('falls back to first image when no quality can be parsed', () {
      final images = [
        DownloadLink(quality: 'abc', link: 'https://example.com/fallback.jpg'),
        DownloadLink(quality: 'xyz', link: 'https://example.com/other.jpg'),
      ];
      expect(
        ImageQualityHelper.getHighestQualityImageUrl(images),
        'https://example.com/fallback.jpg',
      );
    });

    test('treats unparseable quality as 0 and prefers parseable ones', () {
      final images = [
        DownloadLink(quality: 'abc', link: 'https://example.com/abc.jpg'),
        DownloadLink(quality: '150', link: 'https://example.com/150.jpg'),
      ];
      expect(
        ImageQualityHelper.getHighestQualityImageUrl(images),
        'https://example.com/150.jpg',
      );
    });
  });
}
