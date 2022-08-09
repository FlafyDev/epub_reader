import 'package:epub_reader/models/word_definition.dart';
import 'package:http/http.dart' as http;

import 'dictionary_api.dart';

abstract class WordDictionary {
  http.Client httpClient;
  WordDictionary({required this.httpClient});

  Future<List<WordDefinition>> getDefinition(String word);
}

enum WordDictionaryEnum {
  none,
  dictionaryApi,
}

extension WordDictionaryEnumExtension on WordDictionaryEnum {
  String get name {
    switch (this) {
      case WordDictionaryEnum.none:
        return 'None';
      case WordDictionaryEnum.dictionaryApi:
        return 'Dictionary API';
    }
  }
}

Future<WordDictionary?> createWordDictionary(
    WordDictionaryEnum wordDictionary) async {
  switch (wordDictionary) {
    case WordDictionaryEnum.none:
      return null;
    case WordDictionaryEnum.dictionaryApi:
      return DictionaryApi(
        httpClient: http.Client(),
      );
  }
}
