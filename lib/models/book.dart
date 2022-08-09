import 'package:epub_reader/models/book_saved_data.dart';
import 'package:flutter/material.dart';

class Book {
  String name;
  BookIdentifier bookIdentifier;
  int? pages;
  List<String> authors;
  List<String> tags;
  String? description;
  ImageProvider? coverProvider;
  BookSavedData? savedData;
  List<String> chapters;

  getAuthors() {
    return authors.join(', ');
  }

  Book({
    required this.name,
    this.pages,
    this.savedData,
    BookIdentifier? bookIdentifier,
    List<String>? authors,
    List<String>? tags,
    List<String>? chapters,
    this.description,
    this.coverProvider,
  })  : tags = tags ?? [],
        authors = authors ?? [],
        chapters = chapters ?? [],
        bookIdentifier = bookIdentifier ?? BookIdentifier();
}

class BookIdentifier {
  String? isbn13;
  String? isbn10;
  Map<String, String?> other;

  BookIdentifier({
    this.isbn13,
    this.isbn10,
    Map<String, String?>? other,
  }) : other = other ?? {};

  String? getAnyIsbn() {
    return isbn13 ?? isbn10;
  }
}

enum BookStatus {
  planToRead,
  reading,
  completed,
}

class BookThemeData {
  Color textColor;
  Color backgroundColor;
  double lineHeightMultiplier;
  double textSizeMultiplier;
  TextAlign? textAlignment;
  String? textFont;

  BookThemeData({
    required this.backgroundColor,
    required this.textColor,
    this.lineHeightMultiplier = 1,
    this.textSizeMultiplier = 1,
    this.textAlignment,
    this.textFont,
  });
}

class BookOptions {
  // double singlePageWidth;
  BookThemeData bookThemeData;

  BookOptions(
    this.bookThemeData,
    // this.singlePageWidth,
  );
}

class BookPage {
  String content;

  BookPage(this.content);
}
