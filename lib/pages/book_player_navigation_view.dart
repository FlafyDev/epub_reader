import 'package:collection/collection.dart';
import 'package:epubz/epubz.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../widgets/custom_expansion_tile.dart';
import '../widgets/clean_app_bar.dart';
import '../widgets/epub_renderer/epub_location.dart';

class _Chapter {
  final String title;
  final int depth;
  final EpubLocation<String, EpubInnerAnchor> location;
  final EpubChapter original;

  _Chapter({
    required this.title,
    required this.depth,
    required this.location,
    required this.original,
  });

  factory _Chapter.fromEpubChapter(EpubChapter chapter, int depth) {
    return _Chapter(
      title: chapter.Title ?? "Unnamed chapter",
      depth: depth,
      location: EpubLocation.fromEpubChapter(chapter),
      original: chapter,
    );
  }
}

class BookPlayerNavigationView extends StatefulWidget {
  const BookPlayerNavigationView({
    Key? key,
    required this.chapters,
    required this.spineFiles,
    this.currentChapter,
    this.currentSpineFile,
  }) : super(key: key);

  final List<EpubChapter> chapters;
  final List<EpubContentFile> spineFiles;
  final EpubChapter? currentChapter;
  final EpubContentFile? currentSpineFile;

  @override
  _BookPlayerNavigationViewState createState() =>
      _BookPlayerNavigationViewState();
}

class _BookPlayerNavigationViewState extends State<BookPlayerNavigationView>
    with SingleTickerProviderStateMixin {
  late final List<_Chapter> chapters;
  late final List<List<_Chapter>> subChapters;
  late final TabController tabController;

  @override
  void initState() {
    super.initState();

    tabController = TabController(
      length: 2,
      initialIndex: 0,
      vsync: this,
    );

    chapters =
        widget.chapters.map((e) => _Chapter.fromEpubChapter(e, 0)).toList();

    subChapters = widget.chapters
        .map((e) => transformChapters(e.SubChapters, 1))
        .toList();
  }

  List<_Chapter> transformChapters(List<EpubChapter>? chapters, int depth) {
    final result = <_Chapter>[];
    if (chapters == null) {
      return result;
    }

    for (final chapter in chapters) {
      result.add(_Chapter.fromEpubChapter(chapter, depth));
      result.addAll(transformChapters(chapter.SubChapters!, depth + 1));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    const currentStyle = TextStyle(color: Colors.blue);

    return Scaffold(
      appBar: const CleanAppBar(
        title: 'Navigation',
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).backgroundColor,
            height: 50,
            child: TabBar(
              controller: tabController,
              labelStyle: Theme.of(context).textTheme.titleSmall,
              tabs: const [
                Tab(text: "Chapters"),
                Tab(text: "Spine"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                _ChaptersView(
                  chapters: chapters,
                  subChapters: subChapters,
                  currentStyle: currentStyle,
                  currentChapter: widget.currentChapter,
                ),
                _SpineView(
                  allChapters: widget.chapters,
                  currentSpineFile: widget.currentSpineFile,
                  spineFiles: widget.spineFiles,
                  currentStyle: currentStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SpineView extends StatefulWidget {
  const _SpineView({
    Key? key,
    required this.allChapters,
    required this.spineFiles,
    required this.currentSpineFile,
    required this.currentStyle,
  }) : super(key: key);

  final List<EpubChapter> allChapters;
  final List<EpubContentFile> spineFiles;
  final EpubContentFile? currentSpineFile;
  final TextStyle currentStyle;

  @override
  State<_SpineView> createState() => _SpineViewState();
}

class _SpineViewState extends State<_SpineView>
    with AutomaticKeepAliveClientMixin {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      itemScrollController.jumpTo(
        index: widget.spineFiles
            .indexWhere((file) => file == widget.currentSpineFile),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ScrollablePositionedList.builder(
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      itemCount: widget.spineFiles.length,
      itemBuilder: (context, index) {
        final spineFile = widget.spineFiles[index];
        final chapter = widget.allChapters
            .firstWhereOrNull((e) => e.ContentFileName == spineFile.FileName);

        return ListTile(
          tileColor: chapter == null
              ? (Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.1))
              : null,
          title: Row(
            children: [
              if (chapter == null) const SizedBox(width: 16),
              Expanded(
                child: Text(
                  chapter?.Title ?? spineFile.FileName ?? "Unnamed spine file",
                  style: widget.currentSpineFile == spineFile
                      ? widget.currentStyle
                      : null,
                ),
              ),
            ],
          ),
          onTap: () {
            Navigator.pop(
              context,
              EpubLocation(
                spineFile.FileName!,
                EpubInnerPage(0),
              ),
            );
          },
        );
      },
    );
  }
}

class _ChaptersView extends StatefulWidget {
  const _ChaptersView({
    Key? key,
    required this.chapters,
    required this.subChapters,
    required this.currentStyle,
    required this.currentChapter,
  }) : super(key: key);

  final List<_Chapter> chapters;
  final List<List<_Chapter>> subChapters;
  final TextStyle currentStyle;
  final EpubChapter? currentChapter;

  @override
  State<_ChaptersView> createState() => _ChaptersViewState();
}

class _ChaptersViewState extends State<_ChaptersView>
    with AutomaticKeepAliveClientMixin {
  final currentChapterKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (currentChapterKey.currentContext != null) {
        Scrollable.ensureVisible(
          currentChapterKey.currentContext!,
          alignment: 0.5,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return ListView(
      children:
          Iterable<int>.generate(widget.chapters.length).toList().map((i) {
        final chapter = widget.chapters[i];
        final subChapters = widget.subChapters[i];

        if (subChapters.isEmpty) {
          return ListTile(
            key: widget.currentChapter == chapter.original
                ? currentChapterKey
                : null,
            title: Text(
              chapter.title,
              style: widget.currentChapter == chapter.original
                  ? widget.currentStyle
                  : null,
            ),
            onTap: () {
              Navigator.pop(context, chapter.location);
            },
          );
        }

        bool expand = false;

        final children = subChapters.map((chapter) {
          expand = expand || chapter.original == widget.currentChapter;
          return Row(
            children: [
              SizedBox(
                width: 30.0 * chapter.depth,
              ),
              Expanded(
                child: ListTile(
                  key: widget.currentChapter == chapter.original
                      ? currentChapterKey
                      : null,
                  title: Text(
                    chapter.title,
                    style: widget.currentChapter == chapter.original
                        ? widget.currentStyle
                        : null,
                  ),
                  onTap: () {
                    Navigator.pop(context, chapter.location);
                  },
                ),
              ),
            ],
          );
        }).toList();

        return CustomExpansionTile(
          key: widget.currentChapter == chapter.original
              ? currentChapterKey
              : null,
          hideBorder: true,
          title: Text(
            chapter.title,
            style: widget.currentChapter == chapter.original
                ? widget.currentStyle
                : null,
          ),
          onContentTap: () {
            Navigator.pop(context, chapter.location);
          },
          initiallyExpanded: expand,
          children: children,
        );
      }).toList(),
    );
  }
}
