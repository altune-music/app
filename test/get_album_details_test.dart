import 'dart:typed_data';
import 'package:altune/services/state_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiosaavn/jiosaavn.dart';
import 'package:altune/controllers/main_controller.dart';
import 'package:altune/services/player_manager.dart';

class _FailingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
      error: 'Simulated Dio failure',
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {});

  group('getAlbumDetails', () {
    test('returns fallback with empty songs when detailsById throws', () async {
      final client = JioSaavnClient();
      client.albums.dio.httpClientAdapter = _FailingAdapter();

      final controller = MainController(
        stateService: StateService(),
        client: client,
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      final fallback = AlbumResponse(
        id: '123',
        name: 'Fallback Album',
        year: '2024',
        url: 'https://example.com/album/fallback',
        songCount: '0',
        image: null,
        primaryArtists: [],
        artists: [],
        featuredArtists: [],
        songs: [],
      );

      final result = await controller.getAlbumDetails(
        '123',
        fallback: fallback,
      );
      expect(result.songs, isEmpty);
      expect(result.name, 'Fallback Album');
    });

    test('throws when detailsById fails and no fallback provided', () async {
      final client = JioSaavnClient();
      client.albums.dio.httpClientAdapter = _FailingAdapter();

      final controller = MainController(
        stateService: StateService(),
        client: client,
        playerManager: PlayerManager(),
        localSongs: [],
      );
      addTearDown(() => controller.playerManager.dispose());

      await expectLater(controller.getAlbumDetails('123'), throwsException);
    });
  });
}
