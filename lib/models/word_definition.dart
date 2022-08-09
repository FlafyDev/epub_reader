class WordDefinition {
  WordDefinition({
    required this.word,
    this.phonetic,
    List<WordDefinitionMeaning>? meanings,
    List<WordDefinitionLink>? links,
  })  : meanings = meanings ?? [],
        links = links ?? [];

  String word;
  String? phonetic;
  List<WordDefinitionMeaning> meanings;
  List<WordDefinitionLink> links;
}

class WordDefinitionMeaning {
  WordDefinitionMeaning({
    required this.partOfSpeech,
    required this.definitions,
  });

  final String partOfSpeech;
  final List<String> definitions;
}

class WordDefinitionLink {
  WordDefinitionLink({
    required this.displayText,
    required this.url,
  });

  final String displayText;
  final String url;
}
