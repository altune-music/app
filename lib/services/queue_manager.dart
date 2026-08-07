import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/song.dart';
import '../interfaces/queue_repeat_mode.dart';

/// Handles queue ordering, shuffle, and repeat logic.
/// Callers work with song IDs, not indices — [playFromSongs] and [setQueue] accept songId.
///
/// Persistence: QueueManager holds NO storage of its own. Every mutation fires
/// [onPersist], which MainController wires to saveState() so the whole app state
/// (including the queue + current index + shuffle/repeat) lands in one JSON file.
/// This keeps a single source of truth instead of a drift-prone second file.
class QueueManager extends ChangeNotifier {
  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _shuffle = false;
  QueueRepeatMode _repeatMode = QueueRepeatMode.off;

  /// Called after any queue/settings mutation so the owner can persist state.
  void Function()? onPersist;

  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  int get length => _queue.length;
  bool get shuffle => _shuffle;
  QueueRepeatMode get repeatMode => _repeatMode;
  Song? get currentSong => _currentIndex >= 0 && _currentIndex < _queue.length
      ? _queue[_currentIndex]
      : null;

  // ponytail: non-mutating check for timer cancel on queue end
  bool get hasNextSong {
    if (_queue.isEmpty) return false;
    if (_repeatMode == QueueRepeatMode.one ||
        _repeatMode == QueueRepeatMode.all) {
      return true;
    }
    return _currentIndex + 1 < _queue.length;
  }

  int getIndexById(String id) => _queue.indexWhere((s) => s.id == id);

  /// Restore persisted queue + settings (called by MainController.loadState).
  /// Deliberately does not fire [onPersist] — this is the load path, not a mutation.
  void restoreState({
    required List<Song> queue,
    required int index,
    required bool shuffle,
    required QueueRepeatMode repeat,
  }) {
    _queue = List.from(queue);
    _currentIndex = index;
    _shuffle = shuffle;
    _repeatMode = repeat;
    notifyListeners();
  }

  /// Returns the serializable queue + settings for MainController.saveState.
  Map<String, dynamic> toStateJson() => {
    'ids': _queue.map((s) => s.id).toList(),
    'index': _currentIndex,
    'shuffle': _shuffle,
    'repeat': _repeatMode.index,
  };

  void _persist() => onPersist?.call();

  Song? setCurrentIndex(int index) {
    if (index < 0 || index >= _queue.length) return null;
    _currentIndex = index;
    _persist();
    notifyListeners();
    return _queue[_currentIndex];
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
    _persist();
    notifyListeners();
  }

  void setQueue(List<Song> songs, {int initialIndex = 0}) {
    _queue = List.from(songs);
    _currentIndex = initialIndex;
    if (_shuffle) {
      _shuffleQueue();
    }
    _persist();
    notifyListeners();
  }

  void addToQueue(List<Song> songs, {bool atEnd = true}) {
    if (atEnd) {
      _queue.addAll(songs);
    } else {
      if (_currentIndex >= 0) {
        final insertPos = _currentIndex + 1;
        _queue.insertAll(insertPos, songs);
        _currentIndex += songs.length;
      } else {
        _queue.addAll(songs);
      }
    }
    _persist();
    notifyListeners();
  }

  Song? getNextSong() {
    if (_queue.isEmpty) return null;

    if (_repeatMode == QueueRepeatMode.one) {
      return _queue[_currentIndex];
    }

    int nextIndex = _currentIndex + 1;
    if (nextIndex >= _queue.length) {
      if (_repeatMode == QueueRepeatMode.all) {
        nextIndex = 0;
      } else {
        return null;
      }
    }
    _currentIndex = nextIndex;
    _persist();
    // Notify so UI (e.g. the queue screen's playing dot) follows the new index
    notifyListeners();
    return _queue[nextIndex];
  }

  Song? getPreviousSong() {
    if (_queue.isEmpty) return null;

    int prevIndex = _currentIndex - 1;
    if (prevIndex < 0) {
      if (_repeatMode == QueueRepeatMode.all) {
        prevIndex = _queue.length - 1;
      } else {
        return null;
      }
    }
    _currentIndex = prevIndex;
    _persist();
    // Notify so UI (e.g. the queue screen's playing dot) follows the new index
    notifyListeners();
    return _queue[prevIndex];
  }

  void playNext(Song song) {
    if (_currentIndex >= 0) {
      final existingIndex = _queue.indexWhere((s) => s.id == song.id);
      if (existingIndex >= 0) {
        _queue.removeAt(existingIndex);
        if (existingIndex < _currentIndex) {
          _currentIndex--;
        }
      }
      _queue.insert(_currentIndex + 1, song);
    } else {
      _queue.add(song);
      _currentIndex = 0;
    }
    _persist();
    notifyListeners();
  }

  void addToQueueEnd(Song song) {
    _queue.add(song);
    _persist();
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    if (_shuffle) {
      _shuffleQueue();
    }
    _persist();
    notifyListeners();
  }

  // Fisher-Yates shuffle. When a current song exists, extract it first,
  // shuffle the rest, then reinsert at the same index. This keeps
  // _currentIndex valid without extra index tracking.
  void _shuffleQueue() {
    if (_queue.isEmpty) {
      _currentIndex = -1;
      return;
    }

    final random = Random();
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      final current = _queue[_currentIndex];
      _queue.removeAt(_currentIndex);
      for (int i = _queue.length - 1; i > 0; i--) {
        final j = random.nextInt(i + 1);
        final temp = _queue[i];
        _queue[i] = _queue[j];
        _queue[j] = temp;
      }
      _queue.insert(_currentIndex, current);
      return;
    }

    for (int i = _queue.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = _queue[i];
      _queue[i] = _queue[j];
      _queue[j] = temp;
    }
    _currentIndex = _queue.isEmpty ? -1 : 0;
  }

  void cycleRepeatMode() {
    _repeatMode = QueueRepeatMode
        .values[(_repeatMode.index + 1) % QueueRepeatMode.values.length];
    _persist();
    notifyListeners();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _queue.length ||
        newIndex < 0 ||
        newIndex >= _queue.length) {
      return;
    }

    final song = _queue.removeAt(oldIndex);

    if (_currentIndex == oldIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex) {
      _currentIndex--;
      if (newIndex <= _currentIndex) {
        _currentIndex++;
      }
    } else if (oldIndex > _currentIndex) {
      if (newIndex <= _currentIndex) {
        _currentIndex++;
      }
    }

    _queue.insert(newIndex, song);
    _persist();
    notifyListeners();
  }

  void removeAt(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (_currentIndex == index) {
      _currentIndex = -1;
    } else if (index < _currentIndex) {
      _currentIndex--;
    }
    _persist();
    notifyListeners();
  }
}
