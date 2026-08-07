import 'package:flutter_test/flutter_test.dart';
import 'package:altune/controllers/main_controller.dart';

void main() {
  group('MainController.isMissingAudioBackend', () {
    test('detects mpv loader error', () {
      expect(
        MainController.isMissingAudioBackend(
          Exception('mpv: error while loading shared libraries'),
        ),
        isTrue,
      );
    });

    test('detects shared library error', () {
      expect(
        MainController.isMissingAudioBackend(
          Exception('error while loading shared libraries: libmpv.so.2'),
        ),
        isTrue,
      );
    });

    test('detects cannot open error', () {
      expect(
        MainController.isMissingAudioBackend(
          Exception('Cannot open libmpv.so'),
        ),
        isTrue,
      );
    });

    test('returns false for unrelated playback errors', () {
      expect(
        MainController.isMissingAudioBackend(
          Exception('Network request failed: timeout'),
        ),
        isFalse,
      );
    });
  });
}
