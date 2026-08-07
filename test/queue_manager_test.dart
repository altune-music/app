import 'package:flutter_test/flutter_test.dart';
import "package:altune/models/song.dart";
import 'package:altune/services/queue_manager.dart';
import 'package:altune/interfaces/queue_repeat_mode.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {});

  group('QueueManager', () {
    QueueManager createManager() {
      return QueueManager();
    }

    test(
      'reorderQueue updates order, current index, and notifies listeners',
      () {
        final manager = createManager();
        var notified = false;
        manager.addListener(() {
          notified = true;
        });

        manager.setQueue([
          Song(id: 'a', name: 'A', filePath: ''),
          Song(id: 'b', name: 'B', filePath: ''),
          Song(id: 'c', name: 'C', filePath: ''),
        ], initialIndex: 0);

        notified = false;
        manager.reorderQueue(0, 2);

        expect(manager.queue.map((song) => song.id), ['b', 'c', 'a']);
        expect(manager.currentIndex, 2);
        expect(notified, isTrue);
      },
    );

    test(
      'reorderQueue adjusts currentIndex when moving items before current',
      () {
        final manager = createManager();
        manager.setQueue([
          Song(id: 'a', name: 'A', filePath: ''),
          Song(id: 'b', name: 'B', filePath: ''),
          Song(id: 'c', name: 'C', filePath: ''),
          Song(id: 'd', name: 'D', filePath: ''),
        ], initialIndex: 2);

        manager.reorderQueue(0, 1);
        expect(manager.currentIndex, 2);
      },
    );

    test('reorderQueue handles moving current song to new position', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
        Song(id: 'b', name: 'B', filePath: ''),
        Song(id: 'c', name: 'C', filePath: ''),
        Song(id: 'd', name: 'D', filePath: ''),
      ], initialIndex: 0);

      manager.reorderQueue(0, 3);
      expect(manager.queue.map((s) => s.id), ['b', 'c', 'd', 'a']);
      expect(manager.currentIndex, 3);
    });

    test('reorderQueue handles moving later item before current', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
        Song(id: 'b', name: 'B', filePath: ''),
        Song(id: 'c', name: 'C', filePath: ''),
        Song(id: 'd', name: 'D', filePath: ''),
      ], initialIndex: 2);

      manager.reorderQueue(3, 0);
      expect(manager.queue.map((s) => s.id), ['d', 'a', 'b', 'c']);
      expect(manager.currentIndex, 3);
    });

    test('removeAt updates queue and currentIndex', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
        Song(id: 'b', name: 'B', filePath: ''),
        Song(id: 'c', name: 'C', filePath: ''),
      ], initialIndex: 1);

      var notified = false;
      manager.addListener(() {
        notified = true;
      });

      notified = false;
      manager.removeAt(0);

      expect(manager.queue.length, 2);
      expect(manager.queue.first.id, 'b');
      expect(manager.currentIndex, 0);
      expect(notified, isTrue);
    });

    test('removeAt clears currentIndex when removing current song', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
        Song(id: 'b', name: 'B', filePath: ''),
      ], initialIndex: 0);

      manager.removeAt(0);
      expect(manager.currentIndex, -1);
    });

    test('setQueue replaces queue and sets initial index', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'x', name: 'X', filePath: ''),
        Song(id: 'y', name: 'Y', filePath: ''),
      ], initialIndex: 1);

      expect(manager.queue.length, 2);
      expect(manager.currentIndex, 1);
    });

    test('clearQueue empties queue and resets currentIndex', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
        Song(id: 'b', name: 'B', filePath: ''),
      ], initialIndex: 0);

      manager.clearQueue();

      expect(manager.queue, isEmpty);
      expect(manager.currentIndex, -1);
    });

    test('clearQueue notifies listeners', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
      ], initialIndex: 0);

      var notified = false;
      manager.addListener(() {
        notified = true;
      });

      manager.clearQueue();
      expect(notified, isTrue);
    });

    test('playNext adds song after current', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
      ], initialIndex: 0);

      manager.playNext(Song(id: 'b', name: 'B', filePath: ''));
      expect(manager.queue.length, 2);
      expect(manager.currentIndex, 0);
      expect(manager.queue[1].id, 'b');
    });

    test('playNext moves existing song to after current', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
        Song(id: 'b', name: 'B', filePath: ''),
        Song(id: 'c', name: 'C', filePath: ''),
      ], initialIndex: 0);

      manager.playNext(Song(id: 'c', name: 'C', filePath: ''));
      expect(manager.queue.length, 3);
      expect(manager.queue[0].id, 'a');
      expect(manager.queue[1].id, 'c');
      expect(manager.queue[2].id, 'b');
      expect(manager.currentIndex, 0);
    });

    test('playNext moves current song to after current', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
        Song(id: 'b', name: 'B', filePath: ''),
      ], initialIndex: 0);

      manager.playNext(Song(id: 'a', name: 'A', filePath: ''));
      expect(manager.queue.length, 2);
      expect(manager.queue[0].id, 'b');
      expect(manager.queue[1].id, 'a');
      expect(manager.currentIndex, 0);
    });

    test('playNext moves song before current and adjusts index', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
        Song(id: 'b', name: 'B', filePath: ''),
        Song(id: 'c', name: 'C', filePath: ''),
      ], initialIndex: 2);

      manager.playNext(Song(id: 'a', name: 'A', filePath: ''));
      expect(manager.queue.length, 3);
      expect(manager.queue[0].id, 'b');
      expect(manager.queue[1].id, 'c');
      expect(manager.queue[2].id, 'a');
      expect(manager.currentIndex, 1);
    });

    test('addToQueueEnd appends song to end', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
      ], initialIndex: 0);

      manager.addToQueueEnd(Song(id: 'b', name: 'B', filePath: ''));
      expect(manager.queue.length, 2);
      expect(manager.queue.last.id, 'b');
    });

    test('toggleShuffle toggles shuffle state', () {
      final manager = createManager();
      expect(manager.shuffle, isFalse);

      manager.toggleShuffle();
      expect(manager.shuffle, isTrue);

      manager.toggleShuffle();
      expect(manager.shuffle, isFalse);
    });

    test('cycleRepeatMode cycles through modes', () {
      final manager = createManager();
      expect(manager.repeatMode, QueueRepeatMode.off);

      manager.cycleRepeatMode();
      expect(manager.repeatMode, QueueRepeatMode.all);

      manager.cycleRepeatMode();
      expect(manager.repeatMode, QueueRepeatMode.one);

      manager.cycleRepeatMode();
      expect(manager.repeatMode, QueueRepeatMode.off);
    });

    test('getNextSong returns next song and updates currentIndex', () {
      final manager = createManager();
      var notified = false;
      manager.addListener(() {
        notified = true;
      });
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
        Song(id: 'b', name: 'B', filePath: ''),
        Song(id: 'c', name: 'C', filePath: ''),
      ], initialIndex: 0);

      notified = false;
      final nextSong = manager.getNextSong();
      expect(nextSong?.id, 'b');
      expect(manager.currentIndex, 1);
      // Notify lets the queue screen's playing dot follow the new index
      expect(notified, isTrue);
    });

    test('getNextSong wraps to first song in repeat all mode', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
        Song(id: 'b', name: 'B', filePath: ''),
      ], initialIndex: 1);
      manager.cycleRepeatMode();

      final nextSong = manager.getNextSong();
      expect(nextSong?.id, 'a');
      expect(manager.currentIndex, 0);
    });

    test('getNextSong returns null when no next song and repeat off', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
      ], initialIndex: 0);

      final nextSong = manager.getNextSong();
      expect(nextSong, isNull);
    });

    test('getPreviousSong returns previous song and updates currentIndex', () {
      final manager = createManager();
      var notified = false;
      manager.addListener(() {
        notified = true;
      });
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
        Song(id: 'b', name: 'B', filePath: ''),
        Song(id: 'c', name: 'C', filePath: ''),
      ], initialIndex: 2);

      notified = false;
      final prevSong = manager.getPreviousSong();
      expect(prevSong?.id, 'b');
      expect(manager.currentIndex, 1);
      // Notify lets the queue screen's playing dot follow the new index
      expect(notified, isTrue);
    });

    test('getPreviousSong wraps to last song in repeat all mode', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
        Song(id: 'b', name: 'B', filePath: ''),
      ], initialIndex: 0);
      manager.cycleRepeatMode();

      final prevSong = manager.getPreviousSong();
      expect(prevSong?.id, 'b');
      expect(manager.currentIndex, 1);
    });

    test(
      'getPreviousSong returns null when no previous song and repeat off',
      () {
        final manager = createManager();
        manager.setQueue([
          Song(id: 'a', name: 'A', filePath: ''),
        ], initialIndex: 0);

        final prevSong = manager.getPreviousSong();
        expect(prevSong, isNull);
      },
    );

    test('getNextSong returns next song in repeat all mode', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
        Song(id: 'b', name: 'B', filePath: ''),
      ], initialIndex: 0);
      manager.cycleRepeatMode();

      final nextSong = manager.getNextSong();
      expect(nextSong?.id, 'b');
      expect(manager.currentIndex, 1);
    });

    test('getNextSong returns same song in repeat one mode', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
        Song(id: 'b', name: 'B', filePath: ''),
      ], initialIndex: 0);
      manager.cycleRepeatMode();
      manager.cycleRepeatMode();

      final nextSong = manager.getNextSong();
      expect(nextSong?.id, 'a');
      expect(manager.currentIndex, 0);
    });

    test('getIndexById returns correct index for existing song', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'x', filePath: ''),
        Song(id: 'y', filePath: ''),
        Song(id: 'z', filePath: ''),
      ]);

      expect(manager.getIndexById('x'), 0);
      expect(manager.getIndexById('y'), 1);
      expect(manager.getIndexById('z'), 2);
    });

    test('getIndexById returns -1 for non-existent song', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', filePath: ''),
        Song(id: 'b', filePath: ''),
      ]);

      expect(manager.getIndexById('c'), -1);
    });

    test('getIndexById returns -1 when queue is empty', () {
      final manager = createManager();
      expect(manager.getIndexById('anything'), -1);
    });

    test('length returns correct queue size', () {
      final manager = createManager();
      expect(manager.length, 0);

      manager.setQueue([
        Song(id: 'a', filePath: ''),
        Song(id: 'b', filePath: ''),
      ]);
      expect(manager.length, 2);
    });

    // ponytail: sleep timer support
    test('hasNextSong returns false when queue is empty', () {
      final manager = createManager();
      expect(manager.hasNextSong, isFalse);
    });

    test('hasNextSong returns false at end of queue with repeat off', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
      ], initialIndex: 0);
      expect(manager.hasNextSong, isFalse);
    });

    test('hasNextSong returns true when not at end', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
        Song(id: 'b', name: 'B', filePath: ''),
      ], initialIndex: 0);
      expect(manager.hasNextSong, isTrue);
    });

    test('hasNextSong returns true at end with repeat all', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
      ], initialIndex: 0);
      manager.cycleRepeatMode(); // all
      expect(manager.hasNextSong, isTrue);
    });

    test('hasNextSong returns true at end with repeat one', () {
      final manager = createManager();
      manager.setQueue([
        Song(id: 'a', name: 'A', filePath: ''),
      ], initialIndex: 0);
      manager.cycleRepeatMode(); // all
      manager.cycleRepeatMode(); // one
      expect(manager.hasNextSong, isTrue);
    });
  });
}
