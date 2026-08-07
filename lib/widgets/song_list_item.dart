import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import '../models/song_list_item_data.dart';
import '../widgets/artwork_image.dart';
import '../widgets/dpad_icon_button.dart';

class SongListItem extends StatelessWidget {
  final SongListItemData song;
  final VoidCallback onTap;
  final VoidCallback onMenuTap;

  const SongListItem({
    super.key,
    required this.song,
    required this.onTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: DpadFocusable(
        debugLabel: 'SongListItem ${song.name}',
        onSelect: onTap,
        excludeChildFocus: false,
        child: const SizedBox(),
        builder: (context, state, child) {
          return GestureDetector(
            onSecondaryTap: onMenuTap,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: state.focused ? colorScheme.secondaryContainer : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: ArtworkImage(
                          imagePath: song.localArtworkPath,
                          imageUrl: song.imageUrl,
                          size: 48,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            song.primaryArtists,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    DpadIconButton(
                      debugLabel: 'SongListItem Menu ${song.name}',
                      onPressed: onMenuTap,
                      icon: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
