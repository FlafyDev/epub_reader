import 'dart:io';

import 'package:epub_reader/pages/home_settings.dart';
import 'package:epub_reader/providers/book_downloader/book_downloader.dart';
import 'package:epub_reader/widgets/language_manager.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:http/http.dart';
import '../managers/settings_manager.dart';
import '../models/book.dart';
import '../widgets/clean_app_bar.dart';
import '../widgets/message_popup.dart';
import 'book_player.dart';
import '../widgets/book_downloader_interface.dart';
import 'library.dart';
import 'search.dart';

class Home extends StatefulWidget {
  const Home({Key? key, required this.settingsManager}) : super(key: key);

  final SettingsManager settingsManager;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  final httpClient = Client();
  late AnimationController animationController;
  late Animation<double> opacityAnimation;
  int pageIndex = 0;
  final translatorModelManager = OnDeviceTranslatorModelManager();

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    opacityAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(animationController);

    animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      FutureBuilder(
        future: Future.wait([
          widget.settingsManager.loadAllBooks(),
          widget.settingsManager.loadShelves(),
        ]),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final books = (snapshot.data as List)[0] as List<Book>;
            final shelves = (snapshot.data as List)[1] as List<Shelf>;
            return Library(
              settingsManager: widget.settingsManager,
              onImageChanged: (book, newImageFile) async {
                await newImageFile.copy(book.savedData!.coverFile.path);

                final decodedImage = await decodeImageFromList(
                  newImageFile.readAsBytesSync(),
                );

                book.savedData!.data.coverSize = Size(
                  decodedImage.width.toDouble(),
                  decodedImage.height.toDouble(),
                );

                await book.savedData!.saveData();

                Phoenix.rebirth(context);
              },
              onDeleteBook: (book) async {
                await widget.settingsManager.deleteBook(book.savedData!.bookId);
                setState(() {});
              },
              books: books,
              shelves: shelves,
              onCreateShelf: (String name) async {
                await widget.settingsManager.createShelf(name);
                setState(() {});
              },
              onDeleteShelf: (shelf) async {
                await shelf.deleteConfig();
                setState(() {});
              },
              onReadBook: (book) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookPlayer(
                      translatorModelManager: translatorModelManager,
                      initialStyle: book.savedData!.data.styleProperties,
                      book: book,
                      wordDictionaryEnum:
                          widget.settingsManager.config.wordDictionary,
                      bookOptions: BookOptions(
                        BookThemeData(
                          backgroundColor: Colors.blueGrey[900]!,
                          textColor: Colors.grey[400]!,
                        ),
                      ),
                      settingsManager: widget.settingsManager,
                      wordsPerPage: widget.settingsManager.config.wordsPerPage,
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      Search(
        settingsManager: widget.settingsManager,
        bookMetadataEnum: widget.settingsManager.config.bookMetadata,
        onBookDownload: (book) async {
          final bookDownloader = await createBookDownloader(
              widget.settingsManager.config.bookDownloader);
          if (bookDownloader == null) {
            messagePopup(
              context,
              "Unknown book downloader",
              "Make sure you have selected a book downloader",
            );
            return;
          }

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                content: BookDownloaderInterface(
                  description: book.description,
                  getter: BookDownloaderInterfaceDownloader(
                    bookDownloader: bookDownloader,
                    bookIdentifier: book.bookIdentifier,
                  ),
                  booksDirectory: widget.settingsManager.directory,
                  onDone: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                ),
              );
            },
          );
        },
      ),
    ];

    return Scaffold(
      appBar: CleanAppBar(
        title: pageIndex == 0 ? "Library" : "Search",
        canBack: false,
        actions: [
          IconButton(
            splashRadius: 20,
            icon: const Icon(
              Icons.add_outlined,
            ),
            onPressed: () async {
              final files = (await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['epub'],
              ))
                  ?.files;

              if (files?.isEmpty ?? true) {
                return;
              }

              final getter = BookDownloaderInterfaceBytes(
                bookFileBytes: await File(files!.single.path!).readAsBytes(),
              );

              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    content: BookDownloaderInterface(
                      getter: getter,
                      booksDirectory: widget.settingsManager.directory,
                      onDone: () {
                        Navigator.of(context).pop();
                        setState(() {});
                      },
                    ),
                  );
                },
              );
            },
          ),
          IconButton(
            splashRadius: 20,
            icon: const Icon(
              Icons.settings_outlined,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeSettings(
                    settingsManager: widget.settingsManager,
                  ),
                ),
              );
              setState(() {});
            },
          ),
          IconButton(
            splashRadius: 20,
            icon: const Icon(Icons.translate_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LanguageManager(
                    modelManager: translatorModelManager,
                  ),
                ),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Opacity(
            opacity: opacityAnimation.value,
            child: child,
          );
        },
        child: pages[pageIndex],
      ),
      bottomNavigationBar: NavigationBarTheme(
        data: Theme.of(context).navigationBarTheme,
        child: NavigationBar(
          selectedIndex: pageIndex,
          onDestinationSelected: (index) {
            setState(() {
              pageIndex = index;
            });
            animationController.reset();
            animationController.forward();
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.library_books),
              label: "Library",
            ),
            NavigationDestination(
              icon: Icon(Icons.search),
              label: "Search",
            ),
          ],
        ),
      ),
    );
  }
}
