import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import '../models/song.dart';
import '../services/player_manager.dart';
import '../services/queue_manager.dart';
import '../widgets/app_back_button.dart';
import '../widgets/equalizer_bars.dart';

class QueueScreen extends StatefulWidget {
  final QueueManager queueManager;
  final PlayerManager? playerManager;
  final Song? playingInfo;
  final VoidCallback? onBack;
  final void Function(int index)? onPlayAtIndex;

  const QueueScreen({
    super.key,
    required this.queueManager,
    this.playerManager,
    this.playingInfo,
    this.onBack,
    this.onPlayAtIndex,
  });

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  @override
  void initState() {
    super.initState();
    widget.queueManager.addListener(_onQueueChanged);
    widget.playerManager?.addListener(_onQueueChanged);
  }

  @override
  void dispose() {
    widget.queueManager.removeListener(_onQueueChanged);
    widget.playerManager?.removeListener(_onQueueChanged);
    super.dispose();
  }

  void _onQueueChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final queue = widget.queueManager.queue;
    final currentIndex = widget.queueManager.currentIndex;

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(onPressed: widget.onBack),
        title: const Text('Queue'),
      ),
      body: SafeArea(
        child: queue.isEmpty
            ? const Center(child: Text('Queue is empty'))
            : ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  widget.queueManager.reorderQueue(oldIndex, newIndex);
                },
                children: [
                  for (int i = 0; i < queue.length; i++)
                    GestureDetector(
                      key: ValueKey(queue[i].id),
                      onTap: () {
                        _playAtIndex(context, i);
                      },
                      child: DpadFocusable(
                        debugLabel: 'QueueItem ${queue[i].title}',
                        onSelect: () {
                          _playAtIndex(context, i);
                        },
                        child: const SizedBox(),
                        builder: (context, state, child) {
                          return Dismissible(
                            key: ValueKey('${queue[i].id}-dismissible'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Icon(
                                Icons.delete,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                            ),
                            onDismissed: (direction) {
                              widget.queueManager.removeAt(i);
                            },
                            child: ListTile(
                              tileColor: state.focused
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.secondaryContainer
                                  : null,
                              leading: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: queue[i].imageUrl.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: queue[i].imageUrl,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Container(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .secondaryContainer,
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    ),
                                                  ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .secondaryContainer,
                                                        child: const Icon(
                                                          Icons.music_note,
                                                          size: 20,
                                                        ),
                                                      ),
                                            )
                                          : Container(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondaryContainer,
                                              child: const Icon(
                                                Icons.music_note,
                                                size: 20,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              title: Row(
                                children: [
                                  if (i == currentIndex)
                                    EqualizerBars(
                                      playing:
                                          widget.playerManager?.isPlaying ??
                                          true,
                                      size: 16,
                                    ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      queue[i].title,
                                      style: TextStyle(
                                        fontWeight: i == currentIndex
                                            ? FontWeight.bold
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(queue[i].artist),
                              // ponytail: no manual drag handle — ReorderableListView
                              // adds its own Icons.drag_handle on desktop and supports
                              // long-press reorder on mobile. A manual one would duplicate it.
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  void _playAtIndex(BuildContext context, int index) {
    if (index < 0 || index >= widget.queueManager.queue.length) return;
    widget.onPlayAtIndex?.call(index);
  }
}
