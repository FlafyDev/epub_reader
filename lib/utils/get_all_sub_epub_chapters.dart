import 'package:epubz/epubz.dart';

List<EpubChapter> getAllSubEpubChapters(EpubChapter chapter) {
  final List<EpubChapter> chapters = [];
  chapters.add(chapter);
  chapter.SubChapters?.forEach((subChapter) {
    chapters.addAll(getAllSubEpubChapters(subChapter));
  });
  return chapters;
}
