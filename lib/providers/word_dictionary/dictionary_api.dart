import 'dart:convert';

import 'package:epub_reader/models/word_definition.dart';
import 'package:http/http.dart';
import 'word_dictionary.dart';

class DictionaryApi extends WordDictionary {
  DictionaryApi({required Client httpClient}) : super(httpClient: httpClient);

  @override
  Future<List<WordDefinition>> getDefinition(String word) async {
    try {
      final res = (await httpClient.get(
          Uri.parse("https://api.dictionaryapi.dev/api/v2/entries/en/$word")));

      if (res.statusCode != 200) {
        return [
          WordDefinition(
            word: word,
          )
        ];
      }

      final bodyDefinitions = jsonDecode(res.body) as List<dynamic>?;
      return (bodyDefinitions ?? [])
          .map(
            (bodyDefinition) => WordDefinition(
              word: bodyDefinition["word"],
              phonetic:
                  ((bodyDefinition["phonetic"] as String?)?.length ?? 0) > 1
                      ? bodyDefinition["phonetic"]
                      : null,
              meanings: (bodyDefinition["meanings"] as List<dynamic>? ?? [])
                  .map(
                    (meaning) => WordDefinitionMeaning(
                      partOfSpeech: meaning["partOfSpeech"],
                      definitions:
                          (meaning["definitions"] as List<dynamic>? ?? [])
                              .map((def) => def["definition"] as String)
                              .toList(),
                    ),
                  )
                  .toList(),
              links: (bodyDefinition["sourceUrls"] as List<dynamic>? ?? [])
                  .map((url) => WordDefinitionLink(url: url, displayText: url))
                  .toList(),
            ),
          )
          .toList();
    } catch (e) {
      return [
        WordDefinition(
          word: word,
        )
      ];
    }
  }
}
