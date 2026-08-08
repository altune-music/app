import 'dart:convert';

import 'package:altune/services/update_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateService', () {
    group('version comparison', () {
      test('detects newer major version', () async {
        final service = UpdateService(
          client: _MockClient(
            jsonEncode({
              'tag_name': 'v2.0.0',
              'name': 'v2.0.0',
              'body': 'Major update',
              'html_url':
                  'https://github.com/altune-music/app/releases/tag/v2.0.0',
            }),
          ),
          testVersion: '1.0.0',
        );

        final result = await service.checkForUpdates();

        expect(result, isNotNull);
        expect(result!.versionWithoutPrefix, '2.0.0');
      });

      test('detects newer minor version', () async {
        final service = UpdateService(
          client: _MockClient(
            jsonEncode({
              'tag_name': 'v1.1.0',
              'name': 'v1.1.0',
              'body': 'Minor update',
              'html_url':
                  'https://github.com/altune-music/app/releases/tag/v1.1.0',
            }),
          ),
          testVersion: '1.0.0',
        );

        final result = await service.checkForUpdates();

        expect(result, isNotNull);
        expect(result!.versionWithoutPrefix, '1.1.0');
      });

      test('detects newer patch version', () async {
        final service = UpdateService(
          client: _MockClient(
            jsonEncode({
              'tag_name': 'v1.0.1',
              'name': 'v1.0.1',
              'body': 'Patch update',
              'html_url':
                  'https://github.com/altune-music/app/releases/tag/v1.0.1',
            }),
          ),
          testVersion: '1.0.0',
        );

        final result = await service.checkForUpdates();

        expect(result, isNotNull);
        expect(result!.versionWithoutPrefix, '1.0.1');
      });

      test('returns null when versions match', () async {
        final service = UpdateService(
          client: _MockClient(
            jsonEncode({
              'tag_name': 'v1.0.0',
              'name': 'v1.0.0',
              'body': 'Release',
              'html_url':
                  'https://github.com/altune-music/app/releases/tag/v1.0.0',
            }),
          ),
          testVersion: '1.0.0',
        );

        final result = await service.checkForUpdates();

        expect(result, isNull);
      });

      test('returns null when installed version has v prefix', () async {
        final service = UpdateService(
          client: _MockClient(
            jsonEncode({
              'tag_name': 'v1.0.0',
              'name': 'v1.0.0',
              'body': 'Release',
              'html_url':
                  'https://github.com/altune-music/app/releases/tag/v1.0.0',
            }),
          ),
          testVersion: 'v1.0.0',
        );

        final result = await service.checkForUpdates();

        expect(result, isNull);
      });

      test('returns null when installed version is newer', () async {
        final service = UpdateService(
          client: _MockClient(
            jsonEncode({
              'tag_name': 'v0.9.0',
              'name': 'v0.9.0',
              'body': 'Old release',
              'html_url':
                  'https://github.com/altune-music/app/releases/tag/v0.9.0',
            }),
          ),
          testVersion: '1.0.0',
        );

        final result = await service.checkForUpdates();

        expect(result, isNull);
      });

      test('strips v prefix from version tag', () async {
        final service = UpdateService(
          client: _MockClient(
            jsonEncode({
              'tag_name': 'v1.0.0',
              'name': 'v1.0.0',
              'body': 'Release',
              'html_url':
                  'https://github.com/altune-music/app/releases/tag/v1.0.0',
            }),
          ),
          testVersion: '1.0.0',
        );

        final result = await service.checkForUpdates();

        expect(result, isNull);
      });

      test('handles pre-release suffixes by ignoring them', () async {
        final service = UpdateService(
          client: _MockClient(
            jsonEncode({
              'tag_name': 'v1.0.0-beta',
              'name': 'v1.0.0-beta',
              'body': 'Beta release',
              'html_url':
                  'https://github.com/altune-music/app/releases/tag/v1.0.0-beta',
            }),
          ),
          testVersion: '1.0.0',
        );

        final result = await service.checkForUpdates();

        // 1.0.0-beta is treated as 1.0.0, same as current, so no update
        expect(result, isNull);
      });

      test('handles missing body in release response', () async {
        final service = UpdateService(
          client: _MockClient(
            jsonEncode({
              'tag_name': 'v2.0.0',
              'name': 'v2.0.0',
              'html_url':
                  'https://github.com/altune-music/app/releases/tag/v2.0.0',
            }),
          ),
          testVersion: '1.0.0',
        );

        final result = await service.checkForUpdates();

        expect(result, isNotNull);
        expect(result!.body, '');
      });
    });
  });
}

/// A mock HTTP client that returns a fixed response body for GET requests.
class _MockClient extends http.BaseClient {
  _MockClient(this._body);

  final String _body;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    return http.StreamedResponse(
      Stream.value(utf8.encode(_body)),
      200,
      contentLength: _body.length,
    );
  }
}
