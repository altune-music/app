import 'package:flutter_test/flutter_test.dart';
import 'package:altune/utils/string_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildAlbumSubtitle', () {
    test('returns year and artist joined by bullet', () {
      expect(buildAlbumSubtitle('2024', 'Arijit Singh'), '2024 • Arijit Singh');
    });

    test('returns only year when artist is null', () {
      expect(buildAlbumSubtitle('2024', null), '2024');
    });

    test('returns only year when artist is empty', () {
      expect(buildAlbumSubtitle('2024', ''), '2024');
    });

    test('returns only artist when year is empty', () {
      expect(buildAlbumSubtitle('', 'Arijit Singh'), 'Arijit Singh');
    });

    test('returns empty string when both are empty', () {
      expect(buildAlbumSubtitle('', ''), '');
    });

    test('returns empty string when both are absent', () {
      expect(buildAlbumSubtitle('', null), '');
    });

    test('returns only artist when year is empty and artist is null', () {
      expect(buildAlbumSubtitle('', null), '');
    });

    test('decodes HTML entities in artist name', () {
      expect(
        buildAlbumSubtitle('2024', 'Arijit &amp; Singh'),
        '2024 • Arijit & Singh',
      );
    });
  });
}
