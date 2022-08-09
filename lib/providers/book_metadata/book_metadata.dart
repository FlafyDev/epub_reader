import 'package:http/http.dart';
import 'package:epub_reader/models/book.dart';

abstract class BookMetadata {
  Client httpClient;
  BookMetadata({required this.httpClient});

  Future<List<Book>> searchBooks(String query);
  Future<Book?> getBookData(BookIdentifier bookIdentifier);
}

enum BookMetadataEnum {
  none,
}

extension BookMetadataEnumExtension on BookMetadataEnum {
  String get name {
    switch (this) {
      case BookMetadataEnum.none:
        return 'None';
    }
  }
}

Future<BookMetadata?> createBookMetadata(BookMetadataEnum bookMetadata) async {
  switch (bookMetadata) {
    case BookMetadataEnum.none:
      return null;
  }
}
