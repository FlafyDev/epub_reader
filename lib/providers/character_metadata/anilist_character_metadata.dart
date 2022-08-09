import 'dart:convert';
import 'package:epub_reader/models/character.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'character_metadata.dart';

class AnilistCharacterMetadata extends CharacterMetadata {
  final Client httpClient;

  AnilistCharacterMetadata({
    required this.httpClient,
  });

  @override
  Future<List<Character>> search(String query) async {
    final res = await httpClient.post(
      Uri.parse("https://graphql.anilist.co/"),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: json.encode({
        "variables": {
          "search": query,
        },
        "query": """
query GetUserId(\$search: String) {
  Page (page: 1, perPage:20) {
  	characters (search: \$search) {
      name {
        full
      },
      description(asHtml: false),
      image {
        medium
      }
    } 
  }
}
""",
      }),
    );

    return (json.decode(res.body)["data"]["Page"]["characters"] as List)
        .map(
          (character) => Character(
            name: character["name"]["full"],
            descriptionMarkdown: character["description"] != null
                ? ((character["description"] as String)
                    .replaceAll(RegExp("~!((.|\\n)*?)!~"), "")
                    .replaceAll("\n", "\n\n"))
                : null,
            image: NetworkImage(character["image"]["medium"]),
          ),
        )
        .toList();
  }
}
