import 'package:html_character_entities/html_character_entities.dart';

String cleanString(String? value) {
  if (value == null || value.isEmpty) return '';
  return HtmlCharacterEntities.decode(value);
}

String buildAlbumSubtitle(String year, String? primaryArtistsId) {
  final parts = <String>[];
  if (year.isNotEmpty) parts.add(year);
  if (primaryArtistsId != null && primaryArtistsId.isNotEmpty) {
    parts.add(cleanString(primaryArtistsId));
  }
  return parts.join(' • ');
}
