import 'package:epub_reader/widgets/book_3d.dart';
import 'package:epub_reader/widgets/message_popup.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import '../managers/settings_manager.dart';
import '../models/book.dart';
import '../providers/book_metadata/book_metadata.dart';
import '../widgets/books_viewer.dart';
import 'book_info.dart';

class Search extends StatefulWidget {
  const Search({
    Key? key,
    required this.onBookDownload,
    required this.bookMetadataEnum,
    required this.settingsManager,
  }) : super(key: key);

  final void Function(Book book) onBookDownload;
  final BookMetadataEnum bookMetadataEnum;
  final SettingsManager settingsManager;

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  List<Book> books = [];
  final httpClient = http.Client();
  BookMetadata? bookMetadata;

  @override
  void initState() {
    super.initState();
  }

  void search(String query) async {
    bookMetadata = await createBookMetadata(widget.bookMetadataEnum);
    if (bookMetadata == null) {
      messagePopup(
        context,
        "No book metadata",
        "Please choose a book metadata before searching anything.",
      );
      return;
    }
    books = await bookMetadata!.searchBooks(query);
    setState(() {
      books = books;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(
          left: 10,
          right: 10,
          top: 10,
        ),
        color: Theme.of(context).backgroundColor,
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Search',
              ),
              onSubmitted: search,
            ),
            Expanded(
              child: BooksViewer(
                settingsManager: widget.settingsManager,
                books: books,
                canSort: false,
                onPressBook: (book) async {
                  final Book? fullBook =
                      await bookMetadata?.getBookData(book.bookIdentifier);
                  if (fullBook != null) {
                    final book3dData = await Book3DData.fromBook(fullBook);
                    Navigator.push(
                      context,
                      createBookInfoPageRoute(
                        BookInfo(
                          wordsPerPage:
                              widget.settingsManager.config.wordsPerPage,
                          book: fullBook,
                          book3dData: book3dData,
                          onPressDownload: () =>
                              widget.onBookDownload(fullBook),
                        ),
                      ),
                    );
                  } else {
                    messagePopup(
                      context,
                      "Couldn't find book.",
                      "The current book metadata couldn't find the requested book.",
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
