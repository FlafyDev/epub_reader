import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../models/character.dart';
import '../../providers/character_metadata/character_metadata.dart';

class CharactersView extends StatefulWidget {
  const CharactersView({
    Key? key,
    required this.characterMetadata,
    this.initialQuery,
  }) : super(key: key);

  final CharacterMetadata characterMetadata;
  final String? initialQuery;

  @override
  _CharactersViewState createState() => _CharactersViewState();
}

class _CharactersViewState extends State<CharactersView> {
  final PageController pageController = PageController();
  final TextEditingController textEditingController = TextEditingController();
  List<Character> characters = [];

  Future<void> search(String query) async {
    final chars = await widget.characterMetadata.search(query);
    setState(() {
      characters = chars;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      textEditingController.text = widget.initialQuery!;
      search(widget.initialQuery!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 500,
      color: Theme.of(context).primaryColor,
      child: Column(
        children: [
          TextField(
            controller: textEditingController,
            decoration: const InputDecoration(
              labelText: "Character name",
            ),
            onSubmitted: (query) async {
              await search(query);
              pageController.jumpToPage(0);
            },
          ),
          Expanded(
            child: PageView.builder(
              controller: pageController,
              itemCount: characters.length,
              itemBuilder: (context, index) {
                final character = characters[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image(
                          image: (character.image ??
                                  const AssetImage("assets/images/cover.png"))
                              as ImageProvider,
                          height: 150,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 8.0,
                        right: 8.0,
                        bottom: 8.0,
                      ),
                      child: Text(
                        character.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Expanded(
                      child: Markdown(
                        data: character.descriptionMarkdown ?? "",
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Html(
            data: "",
          ),
        ],
      ),
    );
  }
}
