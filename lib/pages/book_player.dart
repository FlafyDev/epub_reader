import 'package:bottom_inset_observer/bottom_inset_observer.dart';
import 'package:epub_reader/managers/settings_manager.dart';
import 'package:epub_reader/models/book_saved_data.dart';
import 'package:epub_reader/providers/character_metadata/character_metadata.dart';
import 'package:epub_reader/utils/get_files_from_epub_spine.dart';
import 'package:epub_reader/widgets/characters_view/characters_view.dart';
import 'package:epub_reader/widgets/epub_renderer/epub_server_files.dart';
import 'package:epubz/epubz.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'dart:math';
import 'package:epub_reader/widgets/book_player/book_player_renderer.dart';
import 'package:epub_reader/widgets/book_player/book_player_toolbar.dart';
import 'package:epubz/epubz.dart' as epubz;
import 'package:epub_reader/widgets/book_player/book_player_bottom_options.dart';
import 'package:epub_reader/widgets/book_player/book_player_customizer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import '../providers/word_dictionary/word_dictionary.dart';
import '../utils/link_spine_file_to_chapter.dart';
import '../widgets/book_player/book_player_bottom_text.dart';
import '../widgets/book_player/book_player_word_info.dart';
import 'package:stack/stack.dart' as stack;
import '../widgets/epub_renderer/epub_location.dart';
import '../widgets/epub_renderer/epub_renderer.dart';
import 'book_player_navigation_view.dart';
import 'book_player_note_editor.dart';
import 'book_player_notes_viewer.dart';
import 'book_player_search.dart';

class BookPlayer extends StatefulWidget {
  const BookPlayer({
    Key? key,
    required this.book,
    required this.bookOptions,
    required this.wordDictionaryEnum,
    required this.initialStyle,
    required this.wordsPerPage,
    required this.translatorModelManager,
    required this.settingsManager,
  }) : super(key: key);

  final Book book;
  final BookOptions bookOptions;
  final WordDictionaryEnum wordDictionaryEnum;
  final EpubStyleProperties initialStyle;
  final double wordsPerPage;
  final OnDeviceTranslatorModelManager translatorModelManager;
  final SettingsManager settingsManager;

  @override
  State<BookPlayer> createState() => _BookPlayer();
}

class _BookPlayer extends State<BookPlayer>
    with SingleTickerProviderStateMixin {
  bool showOptionsView = false;
  bool showCustomizer = false;
  epubz.EpubBook? epubBook;
  bool showToolBar = false;
  Rectangle? selectionRect;
  WordDictionary? wordDictionary;
  CharacterMetadata? characterMetadata;
  late final BottomInsetObserver _insetObserver;
  BookPlayerRendererController? bookController;
  double wordInfoAdditionalHeight = 0;
  bool showWordInfo = false;
  String highlightedText = "";
  List<SavedNoteRangeData> highlightedRanges = [];
  bool wordInfoFocused = false;
  EpubServerFiles? server;
  bool showBottomOptions = false;
  final uuid = const Uuid();
  late final List<EpubContentFile> spineFiles;
  final lastReadLocations =
      stack.Stack<EpubLocation<int, EpubConsistentInnerNavigation>>();
  bool ignoreLastReadLocation = false;
  late double pageWidth;
  late double pageHeight;

  @override
  void initState() {
    super.initState();

    _insetObserver = BottomInsetObserver()
      ..addListener((BottomInsetChanges change) {
        setState(() {
          wordInfoAdditionalHeight = change.currentInset;
        });
      });

    initialize();
  }

  Future<void> initialize() async {
    pageWidth =
        MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.width;
    pageHeight =
        MediaQueryData.fromWindow(WidgetsBinding.instance.window).size.height;
    characterMetadata = await createCharacterMetadata(
      widget.book.savedData!.data.characterMetadata,
      localCharacters: widget.settingsManager.config.localCharacters,
      characterMetadataName: widget.book.savedData!.data.characterMetadataName,
    );

    wordDictionary = await createWordDictionary(widget.wordDictionaryEnum);

    epubBook = await epubz.EpubReader.readBook(
      await widget.book.savedData!.epubFile.readAsBytes(),
    );

    spineFiles = getFilesFromEpubSpine(epubBook!);

    server = EpubServerFiles(epubBook!);
    await server!.initialize();

    setState(() {});
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    server?.close();
    _insetObserver.dispose();
    super.dispose();
  }

  void hideToolbar({bool includeWordInfo = true}) {
    bookController?.clearSelection();
    if (includeWordInfo) {
      FocusScope.of(context).unfocus();
      setState(() {
        showWordInfo = false;
      });
    }
    setState(() {
      showToolBar = showToolBar && includeWordInfo;
      selectionRect = null;
    });
    if (!showToolBar) {
      bookController!.clearSelection();
    }
  }

  Future<EpubLocation?> openChapterView() async {
    final chapters = epubBook!.Chapters!;

    return await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return BookPlayerNavigationView(
            spineFiles: spineFiles,
            chapters: chapters,
            currentChapter: linkSpineFileToChapter(
              epubBook!,
              bookController!.currentController.location.page,
              spineFiles: spineFiles,
              passedAnchors: bookController!.currentController.passedAnchors,
            ),
            currentSpineFile:
                spineFiles[bookController!.currentController.location.page],
          );
        },
      ),
    );
  }

  void closeCustomizer() {
    setState(() {
      showCustomizer = false;
    });
    bookController!.setLocation(
      bookController!.currentController.consistentLocation,
      forced: true,
    );
  }

  Future<void> openSearch({String? query}) async {
    final EpubLocation<int, EpubInnerTextNode>? location = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return BookPlayerSearch(
            epubBook: epubBook!,
            initialText: query,
          );
        },
      ),
    );

    if (location != null) {
      bookController!.setLocation(location);
    }
  }

  void onSaveLocation(consistentLocation) async {
    final innerPages = bookController!.currentController.innerPages!;

    setState(() {
      widget.book.savedData!.data.bottomTextType;
    });

    if (!ignoreLastReadLocation &&
        (widget.book.savedData!.data.consistentLocation !=
            consistentLocation)) {
      setState(() {
        lastReadLocations.push(widget.book.savedData!.data.consistentLocation);
      });
    }

    ignoreLastReadLocation = false;

    final location = bookController!.currentController.location;

    widget.book.savedData!.data.progressSpine =
        location.page >= spineFiles.length - 1 &&
                location.innerNav.page >=
                    bookController!.currentController.innerPages! - 1
            ? 1
            : location.innerNav.page / innerPages;

    widget.book.savedData!.data.consistentLocation = consistentLocation;

    await widget.book.savedData!.saveData();
  }

  void toggleBottomOptions() {
    if (!showWordInfo) {
      setState(() {
        if (showCustomizer) {
          closeCustomizer();
        } else {
          showBottomOptions = !showBottomOptions;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (epubBook == null || server?.server == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final Color backgroundColor;
    
    switch (widget.book.savedData!.data.styleProperties.theme) {
      case EpubStyleThemes.light:
        backgroundColor = Colors.white;
        break;
      case EpubStyleThemes.dark:
        backgroundColor = Colors.black;
        break;
    }

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return WillPopScope(
      onWillPop: () async {
        if (showCustomizer) {
          closeCustomizer();
          return false;
        }

        if (showWordInfo) {
          hideToolbar();
          return false;
        }

        if (showBottomOptions) {
          setState(() {
            showBottomOptions = false;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        extendBodyBehindAppBar: true,
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          color: backgroundColor,
          child: Stack(
            children: [
              // Book renderer
              AnimatedPositioned(
                curve: Curves.easeInOut,
                duration: const Duration(milliseconds: 400),
                bottom: ((selectionRect != null)
                    ? max(
                        360 -
                            (MediaQuery.of(context).size.height -
                                (selectionRect!.bottom + 30)),
                        0)
                    : 0),
                child: IgnorePointer(
                  ignoring: showBottomOptions,
                  child: Center(
                    child: Stack(
                      children: [
                        BookPlayerRenderer(
                          backgroundColor: backgroundColor,
                          nextPageOnShake: widget.settingsManager.config.nextPageOnShake,
                          width: pageWidth,
                          height: pageHeight,
                          savedNotes: widget.book.savedData!.data.notes,
                          dragAnimation:
                              widget.settingsManager.config.dragPageAnimation,
                          onNotePressed: (note) async {
                            final bool hasDesc = note.description.isNotEmpty;
                            final SavedNoteColor color = note.color;
                            bool deleted = false;
                            await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  content: SizedBox(
                                    width: 300,
                                    child: BookPlayerNoteEditor(
                                      note: note,
                                      onDelete: () {
                                        widget.book.savedData!.data.notes
                                            .remove(note);
                                        deleted = true;
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                );
                              },
                            );

                            if (deleted ||
                                hasDesc != note.description.isNotEmpty ||
                                color != note.color) {
                              bookController!.setLocation(
                                bookController!.currentController.location,
                                forced: true,
                              );
                            }

                            await widget.book.savedData!.saveData();
                          },
                          controllerCreated: (controller) {
                            bookController = controller;
                          },
                          onSaveLocation: onSaveLocation,
                          server: server!,
                          epubBook: epubBook!,
                          initialLocation:
                              widget.book.savedData!.data.consistentLocation,
                          onSelection: (selection) {
                            if (selection.text.isNotEmpty) {
                              setState(() {
                                highlightedText = selection.text;
                              });
                              highlightedRanges = selection.rangesData;
                              setState(() {
                                showWordInfo = true;

                                showToolBar = true;
                                selectionRect = selection.rect;
                              });
                            } else if (selectionRect != null) {
                              hideToolbar(includeWordInfo: !wordInfoFocused);
                            }
                          },
                          initialStyle: widget.initialStyle,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          child: Column(
                            children: [
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    widget.book.savedData!.data.bottomTextType =
                                        BookPlayerBottomTextType.values[(widget
                                                    .book
                                                    .savedData!
                                                    .data
                                                    .bottomTextType
                                                    .index +
                                                1) %
                                            BookPlayerBottomTextType
                                                .values.length];
                                  });
                                  widget.book.savedData!.saveData();
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: BookPlayerBottomText(
                                    type: widget
                                        .book.savedData!.data.bottomTextType,
                                    bookSavedData: widget.book.savedData!,
                                    wordsPerPage: widget.wordsPerPage,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: showBottomOptions ? () => toggleBottomOptions() : null,
                onLongPress: () => toggleBottomOptions(),
              ),
              AnimatedPositioned(
                curve: Curves.easeInOut,
                duration: const Duration(milliseconds: 400),
                top: showWordInfo ? -wordInfoAdditionalHeight : 360,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Column(
                  children: [
                    const Spacer(),
                    if (showToolBar)
                      Container(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          height: 50,
                          width:
                              min(400, MediaQuery.of(context).size.width - 40),
                          child: Center(
                            child: BookPlayerToolbar(
                              text: highlightedText,
                              onCopy: () {
                                Clipboard.setData(
                                    ClipboardData(text: highlightedText));
                                hideToolbar();
                              },
                              onWebSearch: () {
                                launchUrl(
                                  Uri(
                                    scheme: 'https',
                                    host: 'www.google.com',
                                    path: '/search',
                                    queryParameters: {
                                      'q': highlightedText,
                                    },
                                  ),
                                  mode: LaunchMode.externalApplication,
                                );
                              },
                              onAddNote: (color) async {
                                widget.book.savedData!.data.notes.add(
                                  SavedNote(
                                    id: uuid.v4(),
                                    color: color,
                                    highlightedText: highlightedText,
                                    page: bookController!
                                        .currentController.location.page,
                                    description: "",
                                    rangesData: highlightedRanges,
                                  ),
                                );
                                //await widget.book.savedData!.saveData();
                                bookController!.setLocation(
                                  bookController!.currentController.location,
                                  forced: true,
                                );
                              },
                              onSearch: () =>
                                  openSearch(query: highlightedText),
                              onCharacter: () {
                                hideToolbar();
                                if (characterMetadata != null) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        content: CharactersView(
                                          characterMetadata: characterMetadata!,
                                          initialQuery: highlightedText,
                                        ),
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                    if (showToolBar)
                      Container(
                        height: 10,
                        color: backgroundColor,
                      ),
                    Center(
                      child: Container(
                        color: backgroundColor,
                        width: min(400, MediaQuery.of(context).size.width - 40),
                        height: 300,
                        child: IgnorePointer(
                          ignoring: !showWordInfo,
                          child: BookPlayerWordInfo(
                              word: highlightedText,
                              wordDictionary: wordDictionary,
                              onClose: hideToolbar,
                              onFocusChange: (focused) {
                                wordInfoFocused = focused;
                              },
                              initialFromLanguage: widget.settingsManager.config
                                  .translationFromLanguage,
                              initialToLanguage: widget
                                  .settingsManager.config.translationToLanguage,
                              modelManager: widget.translatorModelManager,
                              onLanguagesChanged: (from, to) {
                                setState(() {
                                  widget.settingsManager.config
                                      .translationFromLanguage = from;
                                  widget.settingsManager.config
                                      .translationToLanguage = to;
                                });
                                widget.settingsManager.saveConfig();
                              }),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom options
              AnimatedPositioned(
                curve: Curves.easeInOut,
                duration: const Duration(milliseconds: 100),
                bottom: showBottomOptions ? 0 : -60,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      height: 60,
                      color: Theme.of(context).primaryColor,
                      width: min(500, MediaQuery.of(context).size.width),
                      child: BookPlayerBottomOptions(
                        page: widget.book.savedData!
                            .getBookPageProgress(widget.wordsPerPage),
                        pages: widget.book.savedData!
                            .getPages(widget.wordsPerPage),
                        book: widget.book,
                        onPageChanged: (a) {},
                        onSearch: () => openSearch(),
                        onExit: () {
                          Navigator.pop(context);
                        },
                        onOptions: () {
                          if (showCustomizer) {
                            closeCustomizer();
                          } else {
                            setState(() {
                              showCustomizer = true;
                            });
                          }
                        },
                        onNotesPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return BookPlayerNotesViewer(
                                  notes: widget.book.savedData!.data.notes,
                                  onPressNote: (savedNote) async {
                                    bookController!.setLocation(EpubLocation(
                                      savedNote.page,
                                      EpubInnerNode(
                                        savedNote
                                            .rangesData.first.startNodeIndex,
                                        savedNote.rangesData.first.startOffset,
                                      ),
                                    ));
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                          );
                        },
                        onChaptersViewPressed: () async {
                          if (bookController == null) {
                            return;
                          }

                          final location = await openChapterView();
                          if (location != null) {
                            bookController!.setLocation(location);
                          }
                        },
                        locationBackEnabled: lastReadLocations.isNotEmpty,
                        onLocationBack: () {
                          if (lastReadLocations.isEmpty) return;
                          ignoreLastReadLocation = true;
                          setState(() {
                            bookController!
                                .setLocation(lastReadLocations.pop());
                          });
                        },
                      ),
                    )
                  ],
                ),
              ),
              // Customizer
              IgnorePointer(
                ignoring: !showCustomizer,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  opacity: showCustomizer ? 1 : 0,
                  child: Row(
                    children: [
                      const Spacer(),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 20,
                          top: 60,
                        ),
                        child: Column(
                          children: [
                            const Spacer(),
                            SizedBox(
                              width: min(
                                  400, MediaQuery.of(context).size.width - 40),
                              height: 300,
                              child: bookController != null
                                  ? BookPlayerCustomizer(
                                      styleProperties: bookController!.style,
                                      onUpdateStyle: () {
                                        bookController!.updateStyle();
                                        setState(() {});
                                        widget.book.savedData!.data
                                                .styleProperties =
                                            bookController!.style;
                                        widget.book.savedData!.saveData();
                                      },
                                    )
                                  : Container(),
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
