import 'package:flutter/material.dart';
import 'package:dpad/dpad.dart';
import 'package:jiosaavn/jiosaavn.dart';
import '../utils/image_quality_helper.dart';
import '../utils/string_utils.dart';
import '../widgets/dpad_icon_button.dart';

class AlbumListItem extends StatelessWidget {
  final AlbumResponse album;
  final VoidCallback onTap;
  final bool showMenuButton;

  const AlbumListItem({
    super.key,
    required this.album,
    required this.onTap,
    this.showMenuButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = _buildSubtitle();

    return DpadFocusable(
      debugLabel: 'AlbumListItem ${album.name}',
      onSelect: onTap,
      child: const SizedBox(),
      builder: (context, state, child) {
        return InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: state.focused
                        ? colorScheme.secondaryContainer
                        : null,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: _buildImage(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: showMenuButton ? 50 : 0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                cleanString(album.name),
                                style: Theme.of(context).textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (showMenuButton)
                  Positioned(
                    right: 16,
                    child: DpadIconButton(
                      debugLabel: 'AlbumListItem Menu ${album.name}',
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildSubtitle() {
    return buildAlbumSubtitle(album.year, album.primaryArtistsId);
  }

  Widget _buildImage(BuildContext context) {
    final imageUrl = album.image?.isNotEmpty == true
        ? ImageQualityHelper.getSmallImageUrl(album.image)
        : null;

    if (imageUrl != null) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholder(context),
      );
    }
    return _buildPlaceholder(context);
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: const Icon(Icons.album, size: 24),
    );
  }
}
