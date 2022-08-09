import 'package:epub_reader/models/character.dart';
import 'character_metadata.dart';
import 'package:string_similarity/string_similarity.dart';

class LocalCharacterMetadata extends CharacterMetadata {
  final List<Character> characters;

  LocalCharacterMetadata({
    required this.characters,
  });

  factory LocalCharacterMetadata.fromJson(List<Map<String, dynamic>> json) {
    return LocalCharacterMetadata(
        characters: json.map((e) => Character.fromJson(e)).toList());
  }

  @override
  Future<List<Character>> search(String query) async {
    return characters
      ..sort((a, b) =>
          b.name.similarityTo(query).compareTo(a.name.similarityTo(query)));
  }
}
