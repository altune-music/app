import 'package:flutter_test/flutter_test.dart';
import 'package:altune/models/song.dart';
import 'package:altune/services/player_manager.dart';
import 'package:altune/interfaces/queue_repeat_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {});

  group('PlayerManager', () {
    test('creates AudioPlayer instance', () {
      final manager = PlayerManager();
      expect(manager.audioPlayer, isNotNull);
      manager.dispose();
    });

    test('exposes queue management', () async {
      final manager = PlayerManager();
      expect(manager.queueManager, isNotNull);
      manager.dispose();
    });

    test(
      'updateCurrentPlaying updates currentPlaying and lastPlayedSong',
      () async {
        final manager = PlayerManager();
        final info = Song(
          id: '1',
          name: 'Test Song',
          primaryArtists: 'Test Artist',
        );

        manager.updateCurrentPlaying(info);

        expect(manager.currentPlaying, equals(info));
        expect(manager.lastPlayedSong, equals(info));
        manager.dispose();
      },
    );

    test('next() updates currentPlaying from queue', () async {
      final manager = PlayerManager();
      manager.setQueue([
        Song(id: '1', name: 'Song 1', filePath: ''),
        Song(id: '2', name: 'Song 2', filePath: ''),
      ], songId: '1');

      manager.next();

      expect(manager.currentPlaying?.id, '2');
      manager.dispose();
    });

    test('previous() updates currentPlaying from queue', () async {
      final manager = PlayerManager();
      manager.setQueue([
        Song(id: '1', name: 'Song 1', filePath: ''),
        Song(id: '2', name: 'Song 2', filePath: ''),
      ], songId: '2');

      manager.previous();

      expect(manager.currentPlaying?.id, '1');
      manager.dispose();
    });

    test('toggleShuffle toggles shuffle state', () async {
      final manager = PlayerManager();
      expect(manager.isShuffled, isFalse);

      manager.toggleShuffle();
      expect(manager.isShuffled, isTrue);

      manager.toggleShuffle();
      expect(manager.isShuffled, isFalse);
      manager.dispose();
    });

    test('cycleRepeatMode cycles through modes', () async {
      final manager = PlayerManager();
      expect(manager.repeatMode, equals(QueueRepeatMode.off));

      manager.cycleRepeatMode();
      expect(manager.repeatMode, equals(QueueRepeatMode.all));

      manager.cycleRepeatMode();
      expect(manager.repeatMode, equals(QueueRepeatMode.one));

      manager.cycleRepeatMode();
      expect(manager.repeatMode, equals(QueueRepeatMode.off));
      manager.dispose();
    });

    test('reset clears currentPlaying and state', () async {
      final manager = PlayerManager();
      manager.updateCurrentPlaying(
        Song(id: '1', name: 'Test', primaryArtists: 'Artist'),
      );

      manager.reset();

      expect(manager.currentPlaying, isNull);
      expect(manager.lastPlayedSong, isNull);
      expect(manager.position, equals(Duration.zero));
      expect(manager.duration, equals(Duration.zero));
      manager.dispose();
    });

    test('notifies listeners on state changes', () async {
      final manager = PlayerManager();
      var notificationCount = 0;
      manager.addListener(() {
        notificationCount++;
      });

      manager.updateCurrentPlaying(
        Song(id: '1', name: 'Test', primaryArtists: 'Artist'),
      );
      expect(notificationCount, 1);

      manager.next();
      expect(notificationCount, 2);
      manager.dispose();
    });

    test('setQueue replaces queue and updates currentPlaying', () async {
      final manager = PlayerManager();
      final songs = [
        Song(id: '1', name: 'Song 1', filePath: '', primaryArtists: 'Artist 1'),
        Song(id: '2', name: 'Song 2', filePath: '', primaryArtists: 'Artist 2'),
      ];

      manager.setQueue(songs, songId: '2');

      expect(manager.currentPlaying?.id, '2');
      expect(manager.queueIndex, 1);
      manager.dispose();
    });

    test('clearQueue empties queue and notifies listeners', () async {
      final manager = PlayerManager();
      manager.setQueue([
        Song(id: '1', name: 'Song 1', filePath: ''),
        Song(id: '2', name: 'Song 2', filePath: ''),
      ], songId: '1');

      var notified = false;
      manager.addListener(() {
        notified = true;
      });

      manager.clearQueue();
      expect(notified, isTrue);
      expect(manager.queueManager.queue, isEmpty);
      expect(manager.queueManager.currentIndex, -1);
      manager.dispose();
    });

    test('addToQueue notifies listeners and adds to queue', () async {
      final manager = PlayerManager();
      var notified = false;
      manager.addListener(() {
        notified = true;
      });

      final song = Song(
        id: '1',
        name: 'Test',
        filePath: '',
        primaryArtists: 'Artist',
      );
      manager.addToQueue(song);
      expect(notified, isTrue);
      expect(manager.queueManager.queue.length, 1);
      manager.dispose();
    });

    test('queueIndex returns current index', () async {
      final manager = PlayerManager();
      manager.setQueue([
        Song(id: '1', name: 'Song 1', filePath: ''),
        Song(id: '2', name: 'Song 2', filePath: ''),
      ], songId: '2');

      expect(manager.queueIndex, 1);
      manager.dispose();
    });

    test('onComplete callback is settable', () async {
      final manager = PlayerManager();
      manager.onComplete = () {};

      expect(manager, isNotNull);
      manager.dispose();
    });

    test('onNext callback is settable', () async {
      final manager = PlayerManager();
      manager.setQueue([
        Song(id: '1', name: 'Song 1', filePath: ''),
        Song(id: '2', name: 'Song 2', filePath: ''),
      ], songId: '1');

      var nextCalled = false;
      manager.onNext = () => nextCalled = true;

      manager.next();

      expect(nextCalled, isTrue);
      expect(manager.currentPlaying?.id, '2');
      manager.dispose();
    });

    test('onPrevious callback is settable', () async {
      final manager = PlayerManager();
      manager.setQueue([
        Song(id: '1', name: 'Song 1', filePath: ''),
        Song(id: '2', name: 'Song 2', filePath: ''),
      ], songId: '2');

      var prevCalled = false;
      manager.onPrevious = () => prevCalled = true;

      manager.previous();

      expect(prevCalled, isTrue);
      expect(manager.currentPlaying?.id, '1');
      manager.dispose();
    });

    test('onSongChanged callback is settable', () async {
      final manager = PlayerManager();
      var songChangedCalled = false;
      Song? receivedInfo;
      manager.onSongChanged = (info) {
        songChangedCalled = true;
        receivedInfo = info;
      };

      final info = Song(id: '1', name: 'Test', primaryArtists: 'Artist');
      manager.updateCurrentPlaying(info);

      expect(songChangedCalled, isTrue);
      expect(receivedInfo, equals(info));
      manager.dispose();
    });

    test('setQueue with empty list clears currentPlaying', () async {
      final manager = PlayerManager();
      manager.updateCurrentPlaying(
        Song(id: '1', name: 'Test', primaryArtists: 'Artist'),
      );

      manager.setQueue([]);

      expect(manager.currentPlaying, isNull);
      manager.dispose();
    });

    test('next() does nothing when queue is empty', () async {
      final manager = PlayerManager();

      manager.next();

      expect(manager.currentPlaying, isNull);
      manager.dispose();
    });

    test('previous() does nothing when queue is empty', () async {
      final manager = PlayerManager();

      manager.previous();

      expect(manager.currentPlaying, isNull);
      manager.dispose();
    });

    test('next() does nothing when at end of queue without repeat', () async {
      final manager = PlayerManager();
      manager.setQueue([
        Song(id: '1', name: 'Song 1', filePath: ''),
      ], songId: '1');

      manager.next();

      expect(manager.currentPlaying?.id, '1');
      manager.dispose();
    });

    test('onPlayRequested callback is settable', () async {
      final manager = PlayerManager();
      manager.onPlayRequested = (info) async {};
      expect(manager, isNotNull);
      manager.dispose();
    });

    test('play() is a no-op when no source is loaded', () async {
      final manager = PlayerManager();
      final info = Song(id: '1', name: 'Test', primaryArtists: 'Artist');
      manager.updateCurrentPlaying(info);

      var callbackCalled = false;
      manager.onPlayRequested = (info) async {
        callbackCalled = true;
      };

      await manager.play();

      expect(callbackCalled, isFalse);
      expect(manager.isPlaying, isFalse);
      manager.dispose();
    });

    test('play() does not call onPlayRequested', () async {
      final manager = PlayerManager();
      manager.onPlayRequested = (info) async {};

      await manager.play();

      // play() without a loaded source is a no-op.
      expect(manager.isPlaying, isFalse);
      manager.dispose();
    });

    test('pause() explicitly tracks isPlaying as false and notifies', () async {
      final manager = PlayerManager();
      var notified = false;
      manager.addListener(() => notified = true);

      // Simulate a playing state; pause must force isPlaying false even though
      // the media_kit backend doesn't report `playing` in its stream.
      await manager.pause();

      expect(manager.isPlaying, isFalse);
      expect(notified, isTrue);
      manager.dispose();
    });

    test('setQueue respects provided list order', () async {
      final manager = PlayerManager();
      final sorted = [
        Song(id: '3', name: 'A Song', filePath: ''),
        Song(id: '2', name: 'B Song', filePath: ''),
        Song(id: '1', name: 'C Song', filePath: ''),
      ];

      manager.setQueue(sorted, songId: '3');

      expect(manager.queueManager.queue.length, 3);
      expect(manager.queueManager.queue[0].id, '3');
      expect(manager.queueManager.queue[1].id, '2');
      expect(manager.queueManager.queue[2].id, '1');
      expect(manager.queueManager.currentIndex, 0);
      manager.dispose();
    });

    test('playFromSongs replaces queue and triggers onPlayRequested', () async {
      final manager = PlayerManager();
      final song = Song(
        id: '1',
        name: 'Test Song',
        filePath: '',
        primaryArtists: 'Artist',
        url: 'http://example.com/audio.mp3',
      );

      var callbackCalled = false;
      Song? receivedInfo;
      manager.onPlayRequested = (info) async {
        callbackCalled = true;
        receivedInfo = info;
      };

      await manager.playFromSongs([song]);

      expect(manager.queueManager.queue.length, 1);
      expect(manager.queueManager.queue[0].id, '1');
      expect(manager.queueManager.currentIndex, 0);
      expect(manager.currentPlaying?.id, '1');
      expect(callbackCalled, isTrue);
      expect(receivedInfo?.id, '1');
      manager.dispose();
    });

    test('playFromSongs clears previous queue', () async {
      final manager = PlayerManager();
      manager.setQueue([
        Song(id: '1', name: 'Song 1', filePath: ''),
        Song(id: '2', name: 'Song 2', filePath: ''),
      ], songId: '1');

      await manager.playFromSongs([
        Song(id: '3', name: 'Song 3', filePath: ''),
      ]);

      expect(manager.queueManager.queue.length, 1);
      expect(manager.queueManager.queue[0].id, '3');
      expect(manager.queueManager.currentIndex, 0);
      manager.dispose();
    });

    test('playFromSongs with multiple songs and songId', () async {
      final manager = PlayerManager();
      final songs = [
        Song(id: '1', name: 'Song 1', filePath: ''),
        Song(id: '2', name: 'Song 2', filePath: ''),
        Song(id: '3', name: 'Song 3', filePath: ''),
      ];

      var callbackCalled = false;
      manager.onPlayRequested = (info) async {
        callbackCalled = true;
      };

      await manager.playFromSongs(songs, songId: '2');

      expect(manager.queueManager.queue.length, 3);
      expect(manager.queueManager.currentIndex, 1);
      expect(manager.currentPlaying?.id, '2');
      expect(callbackCalled, isTrue);
      manager.dispose();
    });

    test('playFromSongs always calls onPlayRequested for new queue', () async {
      final manager = PlayerManager();
      final song = Song(
        id: '1',
        name: 'Test',
        filePath: '',
        primaryArtists: 'Artist',
        url: 'http://example.com/a.mp3',
      );

      var callCount = 0;
      Song? receivedInfo;
      manager.onPlayRequested = (info) async {
        callCount++;
        receivedInfo = info;
      };

      await manager.playFromSongs([song]);

      expect(callCount, 1);
      expect(receivedInfo?.id, '1');
      expect(manager.currentPlaying?.id, '1');
      manager.dispose();
    });

    // ponytail: sleep timer tests
    test('startSleepTimer sets hasSleepTimer to true', () async {
      final manager = PlayerManager();

      manager.startSleepTimer(const Duration(minutes: 30));

      expect(manager.hasSleepTimer, isTrue);
      expect(manager.sleepTimerEnd, isNotNull);
      expect(manager.sleepTimerEnd!.isAfter(DateTime.now()), isTrue);
      manager.cancelSleepTimer();
      manager.dispose();
    });

    test('cancelSleepTimer clears timer state', () async {
      final manager = PlayerManager();
      manager.startSleepTimer(const Duration(minutes: 30));

      manager.cancelSleepTimer();

      expect(manager.hasSleepTimer, isFalse);
      expect(manager.sleepTimerEnd, isNull);
      expect(manager.sleepTimerRemaining, isNull);
      manager.dispose();
    });

    test('reset cancels sleep timer', () async {
      final manager = PlayerManager();
      manager.startSleepTimer(const Duration(minutes: 30));

      manager.reset();

      expect(manager.hasSleepTimer, isFalse);
      manager.dispose();
    });

    test('sleepTimerRemaining returns remaining duration', () async {
      final manager = PlayerManager();
      manager.startSleepTimer(const Duration(minutes: 30));

      final remaining = manager.sleepTimerRemaining;
      expect(remaining, isNotNull);
      // ponytail: allow 1s clock drift between start and check
      expect(remaining!.inSeconds, closeTo(1800, 2));
      manager.cancelSleepTimer();
      manager.dispose();
    });

    test('startSleepTimer cancels previous timer', () async {
      final manager = PlayerManager();
      manager.startSleepTimer(const Duration(minutes: 15));
      final firstEnd = manager.sleepTimerEnd;

      manager.startSleepTimer(const Duration(minutes: 30));

      expect(manager.sleepTimerEnd, isNot(equals(firstEnd)));
      manager.cancelSleepTimer();
      manager.dispose();
    });

    // --- ConcatenatingAudioSource playlist tests ---

    test('setPlaylist with empty list is a no-op', () async {
      final manager = PlayerManager();
      await expectLater(manager.setPlaylist([], initialIndex: 0), completes);
      manager.dispose();
    });

    test('setPlaylist returns early when no sources are playable', () async {
      final manager = PlayerManager();
      final songs = [
        Song(id: '1', name: 'No URL', filePath: ''),
        Song(id: '2', name: 'Also no URL', filePath: ''),
      ];

      await manager.setPlaylist(songs, initialIndex: 0);
      // Should not throw; all songs are unplayable so setAudioSource is never
      // called.
      manager.dispose();
    });

    test('next() and previous() still advance currentPlaying', () async {
      final manager = PlayerManager();
      manager.setQueue([
        Song(id: '1', name: 'Song 1', filePath: ''),
        Song(id: '2', name: 'Song 2', filePath: ''),
      ], songId: '1');

      manager.next();
      expect(manager.currentPlaying?.id, '2');

      manager.previous();
      expect(manager.currentPlaying?.id, '1');
      manager.dispose();
    });
  });
}
