import '../../models/character.dart';
import 'anilist_character_metadata.dart';
import 'local_character_metadata.dart';
import 'package:http/http.dart' as http;

abstract class CharacterMetadata {
  Future<List<Character>> search(String query);
}

enum CharacterMetadataEnum {
  anilist,
  local,
  none,
}

extension CharacterMetadataEnumExtension on CharacterMetadataEnum {
  String get name {
    switch (this) {
      case CharacterMetadataEnum.anilist:
        return 'Anilist';
      case CharacterMetadataEnum.local:
        return 'Local';
      case CharacterMetadataEnum.none:
        return 'None';
    }
  }
}

Future<CharacterMetadata?> createCharacterMetadata(
  CharacterMetadataEnum characterMetadata, {
  Map<String, List<Character>>? localCharacters,
  String? characterMetadataName,
}) async {
  switch (characterMetadata) {
    case CharacterMetadataEnum.anilist:
      return AnilistCharacterMetadata(httpClient: http.Client());

    case CharacterMetadataEnum.local:
      final characters = localCharacters?[characterMetadataName];

      if (characters == null) {
        return null;
      }

      return LocalCharacterMetadata(characters: characters);
    case CharacterMetadataEnum.none:
      return null;
  }
}
