import 'package:http/http.dart';
import '../../models/book.dart';

abstract class BookDownloader {
  Client httpClient;
  BookDownloader({required this.httpClient});

  Future<Uri?> getEpubDownload(BookIdentifier bookIdentifier);
}

enum BookDownloaderEnum {
  none,
}

extension BookDownloaderEnumExtension on BookDownloaderEnum {
  String get name {
    switch (this) {
      case BookDownloaderEnum.none:
        return 'None';
    }
  }
}

Future<BookDownloader?> createBookDownloader(
    BookDownloaderEnum bookDownloader) async {
  switch (bookDownloader) {
    case BookDownloaderEnum.none:
      return null;
  }
}
