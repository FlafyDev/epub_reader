import 'dart:math';

import 'package:collection/collection.dart';
import 'package:epubz/epubz.dart';

import 'get_all_sub_epub_chapters.dart';
import 'get_files_from_epub_spine.dart';

EpubChapter? linkSpineFileToChapter(EpubBook epubBook, int spineFileIndex,
    {List<EpubContentFile>? spineFiles, List<String>? passedAnchors}) {
  final allChapters = epubBook.Chapters!
      .map((chapter) => getAllSubEpubChapters(chapter)..insert(0, chapter))
      .expand((subChapters) => subChapters)
      .toList();
  spineFiles = spineFiles ?? getFilesFromEpubSpine(epubBook);
  final chaptersAsSpineFilesIndexes = allChapters
      .map((chapter) => spineFiles!
          .indexWhere((file) => file.FileName == chapter.ContentFileName))
      .toList();

  final mapped = {
    for (var entry in chaptersAsSpineFilesIndexes.asMap().entries)
      entry.key: entry.value
  };

  final ordered = (mapped.keys.toList()..sort((a, b) => b.compareTo(a)));

  final currentChapters = ordered
      .where((key) => mapped[key]! == spineFileIndex)
      .map((key) => allChapters[key])
      .toList();

  if (currentChapters.isEmpty) {
    final latestChapterPassed = allChapters[
        ordered.firstWhereOrNull((key) => mapped[key]! <= spineFileIndex) ?? 0];
    return latestChapterPassed;
  } else if (passedAnchors == null) {
    return currentChapters.first;
  } else {
    final currentChaptersValues = currentChapters
        .map(
          (subChapter) => subChapter.Anchor == null
              ? 0
              : passedAnchors.indexOf(subChapter.Anchor!),
        )
        .toList();

    final highestIndex = currentChaptersValues.indexOf(
      currentChaptersValues.reduce(max),
    );

    final currentChapter = currentChapters[highestIndex];
    return currentChapter;
  }
}

/*

*/
