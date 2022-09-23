import 'dart:convert';
import 'dart:io';
import 'package:epub_reader/widgets/epub_renderer/epub_location.dart';
import 'package:epubz/epubz.dart';
import 'package:flutter/services.dart';
import 'package:html/parser.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import '../providers/character_metadata/character_metadata.dart';
import '../utils/get_files_from_epub_spine.dart';
import '../utils/hex_color.dart';
import '../widgets/book_player/book_player_bottom_text.dart';
import '../widgets/epub_renderer/epub_renderer.dart';
import 'book.dart';

class SavedNoteRangeData {
  int startNodeIndex;
  int startOffset;
  int endNodeIndex;
  int endOffset;

  SavedNoteRangeData({
    required this.startNodeIndex,
    required this.startOffset,
    required this.endNodeIndex,
    required this.endOffset,
  });

  factory SavedNoteRangeData.fromJson(Map<String, dynamic> json) {
    return SavedNoteRangeData(
      startNodeIndex: json['startNodeIndex'] as int,
      startOffset: json['startOffset'] as int,
      endNodeIndex: json['endNodeIndex'] as int,
      endOffset: json['endOffset'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startNodeIndex': startNodeIndex,
      'startOffset': startOffset,
      'endNodeIndex': endNodeIndex,
      'endOffset': endOffset,
    };
  }
}

const noteColors = [
  Colors.yellow,
  Colors.green,
  Colors.blue,
  Colors.red,
];

enum SavedNoteColor {
  yellow,
  green,
  blue,
  red,
}

class SavedNote {
  final String id;
  final String highlightedText;
  SavedNoteColor color;
  String description;
  final int page;
  final List<SavedNoteRangeData> rangesData;

  SavedNote({
    required this.id,
    required this.highlightedText,
    required this.color,
    required this.page,
    required this.rangesData,
    String? description,
  }) : description = description ?? "";

  factory SavedNote.fromJson(Map<String, dynamic> json) {
    return SavedNote(
      id: json['id'] as String,
      highlightedText: json['highlightedText'] as String,
      color: SavedNoteColor.values[json["color"]],
      page: json['page'] as int,
      rangesData: (json['rangesData'] as List)
          .map((e) => SavedNoteRangeData.fromJson(e as Map<String, dynamic>))
          .toList(),
      description: json['description'] as String,
    );
  }

  factory SavedNote.fromJsonDefault(Map<String, dynamic> json, SavedNote def) {
    try {
      return SavedNote.fromJson(json);
    } catch (e) {
      return def;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'highlightedText': highlightedText,
      'color': color.index,
      'page': page,
      'rangesData': rangesData.map((e) => e.toJson()).toList(),
      'description': description,
    };
  }
}

class BookSavedDataData {
  String name;
  List<String> authors;
  List<int> wordsPerSpineItem;
  String description;
  List<String> chapters;
  Size coverSize;
  Color coverColor;
  CharacterMetadataEnum characterMetadata;
  EpubLocation<int, EpubConsistentInnerNavigation> consistentLocation;
  EpubStyleProperties styleProperties;
  List<SavedNote> notes;
  double? rating;
  double progressSpine;
  BookPlayerBottomTextType bottomTextType;
  String? characterMetadataName;

  BookSavedDataData({
    required this.name,
    required this.authors,
    required this.wordsPerSpineItem,
    required this.description,
    required this.chapters,
    required this.coverSize,
    required this.coverColor,
    required this.characterMetadata,
    required this.consistentLocation,
    required this.styleProperties,
    required this.notes,
    required this.rating,
    required this.progressSpine,
    required this.bottomTextType,
    required this.characterMetadataName,
  });

  BookSavedDataData.fromJson(Map<String, dynamic> json)
      : name = json["name"],
        authors =
            json["authors"].map<String>((name) => name.toString()).toList(),
        wordsPerSpineItem =
            (json["wordsPerSpineItem"] as List).map((e) => e as int).toList(),
        chapters = json["chapters"]
            .map<String>((chapter) => chapter.toString())
            .toList(),
        description = json["description"],
        coverSize = Size(json["coverSize"][0], json["coverSize"][1]),
        coverColor = HexColor.fromHex(json["coverColor"]),
        characterMetadata =
            CharacterMetadataEnum.values[json["characterMetadata"]],
        consistentLocation = EpubLocation.fromJson(
            json["consistentLocation"] as Map<String, dynamic>),
        styleProperties = EpubStyleProperties.fromJson(json["styleProperties"]),
        notes = (json["notes"] as List)
            .map((note) => SavedNote.fromJson(note))
            .toList(),
        rating = json["rating"],
        progressSpine = json["progressSpine"] as double,
        bottomTextType =
            BookPlayerBottomTextType.values[json["bottomTextType"]],
        characterMetadataName = json["characterMetadataName"];

  Map<String, dynamic> toJson() => {
        'name': name,
        'authors': authors,
        'wordsPerSpineItem': wordsPerSpineItem,
        'chapters': chapters,
        'description': description,
        'coverSize': [coverSize.width, coverSize.height],
        'coverColor': coverColor.toHex(),
        'characterMetadata': characterMetadata.index,
        'consistentLocation': consistentLocation.toJson(),
        'styleProperties': styleProperties.toJson(),
        'notes': notes,
        'rating': rating,
        'progressSpine': progressSpine,
        'bottomTextType': bottomTextType.index,
        'characterMetadataName': characterMetadataName,
      };
}

class BookSavedData {
  Directory directory;
  String bookId;
  BookSavedDataData data;
  File dataFile;
  File coverFile;
  File epubFile;

  BookSavedData({
    required this.directory,
    required this.bookId,
    required this.data,
    required this.dataFile,
    required this.coverFile,
    required this.epubFile,
  });

  static Future<void> writeFromEpub({
    required Directory directory,
    required List<int> epubBytes,
    String? description,
  }) async {
    final epubBook = await EpubReader.readBook(epubBytes);

    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }

    await directory.create(recursive: true);
    final path = directory.path;
    final File dataFile = File(p.join(path, "data.json"));
    final File coverFile = File(p.join(path, "cover.png"));
    final File epubFile = File(p.join(path, "book.epub"));

    final wordsPerSpineItem = getFilesFromEpubSpine(epubBook).map((file) {
      if (file is EpubTextContentFile && file.Content != null) {
        return RegExp("[\\w-]+")
            .allMatches(parse(file.Content!).body!.text)
            .length;
      }
      return 0;
    }).toList();

    late final img.Image coverImageData;
    late final Size coverImageSize;

    if (epubBook.CoverImage == null) {
      final data = await rootBundle.load("assets/images/cover.png");

      coverImageData = img.decodeImage(data.buffer.asUint8List())!;
    } else {
      coverImageData = epubBook.CoverImage!;
    }

    coverImageSize = Size(
      coverImageData.width.toDouble(),
      coverImageData.height.toDouble(),
    );

    await coverFile.writeAsBytes(img.encodePng(coverImageData));

    Color coverColor = (await PaletteGenerator.fromByteData(EncodedImage(
          ByteData.sublistView(coverImageData.data),
          width: coverImageSize.width.toInt(),
          height: coverImageSize.height.toInt(),
        )))
            .dominantColor
            ?.color ??
        const Color.fromARGB(255, 169, 169, 169);

    await epubFile.writeAsBytes(epubBytes);
    await dataFile.writeAsString(
      jsonEncode(BookSavedDataData(
        name: epubBook.Title ?? "",
        authors: [if (epubBook.Author != null) epubBook.Author!],
        wordsPerSpineItem: wordsPerSpineItem,
        chapters: epubBook.Chapters!.map((chapter) => chapter.Title!).toList(),
        description: description ?? "",
        coverSize: coverImageSize,
        coverColor: coverColor,
        characterMetadata: CharacterMetadataEnum.none,
        consistentLocation: EpubLocation(0, EpubInnerAnchor("")),
        notes: [],
        styleProperties: EpubStyleProperties(
          margin: EpubMargin(
            side: 28,
            top: 50,
            bottom: 20,
          ),
          fontSizeMultiplier: 1.3,
          lineHeightMultiplier: 1.5,
          weightMultiplier: 1,
          letterSpacingAdder: 0,
          wordSpacingAdder: 0,
          align: 'left',
          fontFamily: 'Default',
          fontPath: '',
          theme: EpubStyleThemes.dark,
        ),
        progressSpine: 0,
        rating: null,
        bottomTextType: BookPlayerBottomTextType.page,
        characterMetadataName: null,
      ).toJson()),
    );
  }

  static Future<BookSavedData> load(Directory directory) async {
    final path = directory.path;
    final File dataFile = File(p.join(path, "data.json"));
    final File coverFile = File(p.join(path, "cover.png"));
    final File epubFile = File(p.join(path, "book.epub"));

    if (!await dataFile.exists() ||
        !await epubFile.exists() ||
        !await coverFile.exists()) {
      throw Exception();
    }

    final BookSavedDataData data = BookSavedDataData.fromJson(
        await dataFile.readAsString().then((data) => json.decode(data)));

    return BookSavedData(
      directory: directory,
      bookId: p.basename(path),
      data: data,
      dataFile: dataFile,
      coverFile: coverFile,
      epubFile: epubFile,
      // epubBook:
      //     await compute(EpubReader.readBook, await epubFile.readAsBytes()),
    );
  }

  Book toBook(double wordsPerPage) {
    return Book(
      name: data.name,
      authors: data.authors,
      description: data.description,
      pages: getPages(wordsPerPage),
      coverProvider: FileImage(coverFile),
      savedData: this,
      chapters: data.chapters,
    );
  }

  Future<void> saveData() async {
    await dataFile.writeAsString(
      jsonEncode(data.toJson()),
    );
  }

  // double get readProgress =>
  //     (data.consistentLocation.page + data.progressSpine) /
  //     (data.wordsPerSpineItem.length);

  bool get isFinished =>
      data.consistentLocation.page >= (data.wordsPerSpineItem.length - 1) &&
      data.progressSpine >= 1;

  double get readProgress => isFinished
      ? 1
      : (currentEstimatedWordsRead /
          data.wordsPerSpineItem.reduce((value, element) => element + value));

  double get currentEstimatedWordsRead {
    if (isFinished) {
      return data.wordsPerSpineItem
          .reduce((value, element) => element + value)
          .toDouble();
    }

    final readSpineItems =
        data.wordsPerSpineItem.take(data.consistentLocation.page);
    return (readSpineItems.isNotEmpty
            ? readSpineItems.reduce((value, element) => value + element)
            : 0) +
        data.wordsPerSpineItem[data.consistentLocation.page] *
            data.progressSpine;
  }

  int getPages(double wordsPerPage) =>
      (data.wordsPerSpineItem.reduce((value, element) => element + value) /
              wordsPerPage)
          .round();

  int getBookPageProgress(double wordsPerPage) => isFinished
      ? getPages(wordsPerPage)
      : (currentEstimatedWordsRead / wordsPerPage).round();
}
