import 'package:epub_reader/widgets/message_popup.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../../models/word_definition.dart';
import '../../providers/word_dictionary/word_dictionary.dart';

class BookPlayerWordInfo extends StatefulWidget {
  const BookPlayerWordInfo({
    Key? key,
    required this.word,
    this.wordDictionary,
    this.onClose,
    this.onFocusChange,
    required this.initialFromLanguage,
    required this.initialToLanguage,
    required this.modelManager,
    this.onLanguagesChanged,
  }) : super(key: key);

  final String word;
  final WordDictionary? wordDictionary;
  final void Function()? onClose;
  final void Function(bool)? onFocusChange;
  final TranslateLanguage initialFromLanguage;
  final TranslateLanguage initialToLanguage;
  final OnDeviceTranslatorModelManager modelManager;
  final void Function(TranslateLanguage from, TranslateLanguage to)?
      onLanguagesChanged;

  @override
  State<BookPlayerWordInfo> createState() => _BookPlayerWordInfoState();
}

class _BookPlayerWordInfoState extends State<BookPlayerWordInfo>
    with SingleTickerProviderStateMixin {
  late TabController tabController;
  late String inputWord;
  late String previousWord;
  late TextEditingController textEditingController;

  @override
  void initState() {
    super.initState();
    tabController = TabController(
      length: 2,
      initialIndex: 0,
      vsync: this,
    );
    inputWord = widget.word;
    previousWord = widget.word;
    textEditingController = TextEditingController(text: widget.word);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.word != previousWord) {
      inputWord = widget.word;
      textEditingController.text = widget.word;
      previousWord = widget.word;
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Focus(
                    child: TextFormField(
                      controller: textEditingController,
                      onFieldSubmitted: (String value) {
                        setState(() {
                          inputWord = value;
                        });
                      },
                      style: Theme.of(context).textTheme.headline6,
                    ),
                    onFocusChange: widget.onFocusChange,
                  ),
                ),
                if (widget.onClose != null)
                  Material(
                    color: Colors.transparent,
                    child: IconButton(
                      splashRadius: 20,
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClose!,
                    ),
                  ),
              ],
            ),
            SizedBox(
              height: 30,
              child: TabBar(
                controller: tabController,
                labelStyle: Theme.of(context).textTheme.titleSmall,
                tabs: const [
                  Tab(text: "Definition"),
                  Tab(text: "Translation"),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  widget.wordDictionary == null
                      ? const Center(child: Text("No word dictionary"))
                      : FutureBuilder(
                          future:
                              widget.wordDictionary!.getDefinition(inputWord),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final wordDefinitions =
                                  snapshot.data as List<WordDefinition>;
                              return _WordDefinitionDisplay(
                                  wordDefinition: wordDefinitions.first);
                            } else if (snapshot.hasError) {
                              return Text(
                                "Error: ${snapshot.error}",
                                style: Theme.of(context).textTheme.headline6,
                              );
                            } else {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                          },
                        ),
                  _TranslationDisplay(
                    text: inputWord,
                    initialFromLanguage: widget.initialFromLanguage,
                    initialToLanguage: widget.initialToLanguage,
                    modelManager: widget.modelManager,
                    onFocusChange: widget.onFocusChange,
                    onLanguagesChanged: widget.onLanguagesChanged,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _TranslationDisplay extends StatefulWidget {
  const _TranslationDisplay({
    Key? key,
    required this.text,
    required this.initialFromLanguage,
    required this.initialToLanguage,
    required this.modelManager,
    this.onFocusChange,
    this.onLanguagesChanged,
  }) : super(key: key);

  final String text;
  final TranslateLanguage initialFromLanguage;
  final TranslateLanguage initialToLanguage;
  final OnDeviceTranslatorModelManager modelManager;
  final void Function(bool)? onFocusChange;
  final void Function(TranslateLanguage from, TranslateLanguage to)?
      onLanguagesChanged;

  @override
  State<_TranslationDisplay> createState() => _TranslationDisplayState();
}

class _TranslationDisplayState extends State<_TranslationDisplay> {
  late TranslateLanguage fromLanguage;
  late TranslateLanguage toLanguage;
  OnDeviceTranslator? translator;

  @override
  void initState() {
    super.initState();
    makeTranslator(widget.initialFromLanguage, widget.initialToLanguage);
  }

  void makeTranslator(
    TranslateLanguage from,
    TranslateLanguage to,
  ) async {
    if (!await widget.modelManager.isModelDownloaded(from.bcpCode) ||
        !await widget.modelManager.isModelDownloaded(to.bcpCode)) {
      messagePopup(
        context,
        "Can't find language.",
        "The selected language haven't been downloaded.",
      );
      return;
    }

    setState(() {
      fromLanguage = from;
      toLanguage = to;
      translator = OnDeviceTranslator(
        sourceLanguage: fromLanguage,
        targetLanguage: toLanguage,
      );
    });
    widget.onLanguagesChanged?.call(from, to);
  }

  @override
  Widget build(BuildContext context) {
    final allLanguages =
        TranslateLanguage.values.map((TranslateLanguage value) {
      return DropdownMenuItem<TranslateLanguage>(
        value: value,
        child: Text(value.name),
      );
    }).toList();

    if (translator == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            const Text("from: "),
            const Spacer(),
            DropdownButton<TranslateLanguage>(
              onTap: () {
                widget.onFocusChange?.call(true);
              },
              value: fromLanguage,
              onChanged: (TranslateLanguage? newFrom) {
                if (newFrom == null) {
                  return;
                }

                makeTranslator(newFrom, toLanguage);
              },
              items: allLanguages,
            ),
          ],
        ),
        Row(
          children: [
            const Text("to: "),
            const Spacer(),
            DropdownButton<TranslateLanguage>(
              onTap: () {
                widget.onFocusChange?.call(true);
              },
              value: toLanguage,
              onChanged: (TranslateLanguage? newTo) {
                if (newTo == null) {
                  return;
                }
                makeTranslator(fromLanguage, newTo);
              },
              items: allLanguages,
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: FutureBuilder(
            future: translator!.translateText(
              widget.text,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final translation = snapshot.data as String;
                return Text(
                  translation,
                  style: Theme.of(context).textTheme.headline6,
                );
              } else if (snapshot.hasError) {
                return Text(
                  "Error: ${snapshot.error}",
                  style: Theme.of(context).textTheme.headline6,
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

class _WordDefinitionDisplay extends StatelessWidget {
  const _WordDefinitionDisplay({
    Key? key,
    required this.wordDefinition,
  }) : super(key: key);

  final WordDefinition wordDefinition;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView.separated(
        // padding: const EdgeInsets.only(top: 10),
        padding: EdgeInsets.zero,
        itemCount: wordDefinition.meanings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final meaning = wordDefinition.meanings[index];
          return Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: Text(meaning.partOfSpeech,
                    style: Theme.of(context).textTheme.bodyLarge!),
              ),
              ...meaning.definitions.asMap().entries.map(
                    (entry) => Row(
                      children: [
                        const SizedBox(width: 20),
                        Expanded(
                          child: Text(
                            "${entry.key + 1}: ${entry.value}",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
