import 'dart:math';
import 'package:epub_reader/widgets/minimal_book_info_bar.dart';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../utils/progress_value.dart';
import '../widgets/book_3d.dart';
import '../widgets/book_3d_interactive.dart';
import '../widgets/clean_app_bar.dart';

PageRouteBuilder createBookInfoPageRoute(BookInfo bookInfo) {
  return PageRouteBuilder(
    reverseTransitionDuration: const Duration(milliseconds: 1000),
    transitionDuration: const Duration(milliseconds: 1000),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween<double>(begin: 0, end: 1);
      final isReverse = animation.status == AnimationStatus.reverse;
      const pageSpeedUp = 3;

      return AnimatedBuilder(
        animation: animation.drive(tween),
        builder: (context, child) {
          final double x = 1 -
              min(
                max(
                  (animation.value * pageSpeedUp) -
                      (isReverse ? (pageSpeedUp - 1) : 0),
                  0,
                ),
                1,
              );
          return FractionalTranslation(
            translation: Offset(
              Curves.easeInOut.transform(x),
              0,
            ),
            child: child,
          );
        },
        child: child,
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) => bookInfo,
  );
}

class BookInfoPreviousBookData {
  final double rotateY;
  final String heroTag;
  final BorderRadius? borderRadius;

  BookInfoPreviousBookData({
    required this.rotateY,
    required this.heroTag,
    this.borderRadius,
  });
}

class BookInfo extends StatefulWidget {
  const BookInfo({
    Key? key,
    required this.book,
    required this.book3dData,
    this.previousBookData,
    this.onPressDownload,
    this.onPressRead,
    this.onPressAddToShelf,
    this.onPressSettings,
    required this.wordsPerPage,
  }) : super(key: key);

  final Book book;
  final Book3DData book3dData;
  final void Function()? onPressDownload;
  final void Function()? onPressRead;
  final void Function()? onPressAddToShelf;
  final void Function()? onPressSettings;
  final BookInfoPreviousBookData? previousBookData;
  final double wordsPerPage;

  @override
  State<BookInfo> createState() => _BookInfo();
}

class _BookInfo extends State<BookInfo> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: CleanAppBar(
        title: widget.book.name,
        color: Colors.transparent,
        actions: [
          if (widget.onPressSettings != null)
            IconButton(
              splashRadius: 20,
              icon: const Icon(
                Icons.settings_outlined,
              ),
              onPressed: widget.onPressSettings!,
            ),
        ],
      ),
      body: Container(
        color: Theme.of(context).backgroundColor,
        child: Stack(
          children: [
            widget.book.coverProvider == null
                ? Container()
                : ShaderMask(
                    shaderCallback: (rect) {
                      return LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).backgroundColor.withOpacity(0.25),
                          Colors.transparent,
                        ],
                      ).createShader(
                        Rect.fromLTRB(0, 0, rect.width, rect.height),
                      );
                    },
                    blendMode: BlendMode.dstIn,
                    child: Image(
                      width: size.width,
                      height: 600,
                      image: widget.book.coverProvider!,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      alignment: Alignment.topCenter,
                    ),
                  ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: size.width * 0.05),
              child: Column(
                children: [
                  const SizedBox(height: 70),
                  Expanded(
                    child: LayoutBuilder(builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: SizedBox(
                          height: max(700, constraints.maxHeight),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Top(
                                book: widget.book,
                                book3dData: widget.book3dData,
                                previousBookData: widget.previousBookData,
                                wordsPerPage: widget.wordsPerPage,
                              ),
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 10),
                                width: size.width,
                                height: 80,
                                child:
                                    MinimalBookInfoBar(book: widget.book),
                              ),
                              Expanded(
                                child: _Bottom(
                                  book: widget.book,
                                  onMainButtonPress: () {
                                    if (widget.book.savedData == null) {
                                      widget.onPressDownload!();
                                    } else {
                                      widget.onPressRead!();
                                    }
                                  },
                                  onSecondaryButtonPress:
                                      widget.onPressAddToShelf,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bottom extends StatefulWidget {
  const _Bottom({
    Key? key,
    required this.book,
    required this.onMainButtonPress,
    required this.onSecondaryButtonPress,
  }) : super(key: key);

  final Book book;
  final void Function() onMainButtonPress;
  final void Function()? onSecondaryButtonPress;

  @override
  State<_Bottom> createState() => _BottomState();
}

class _BottomState extends State<_Bottom> with SingleTickerProviderStateMixin {
  late bool showDescription;
  late bool showReviews;
  late bool showMarkers;
  late bool showChapters;
  late TabController _tabController;

  @override
  void initState() {
    showDescription = widget.book.description?.isNotEmpty ?? false;
    showReviews = false;
    showMarkers = false;
    showChapters = widget.book.chapters.isNotEmpty;
    _tabController = TabController(
      length: (showDescription ? 1 : 0) +
          (showReviews ? 1 : 0) +
          (showMarkers ? 1 : 0) +
          (showChapters ? 1 : 0),
      vsync: this,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Container(
      width: size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 50,
            child: TabBar(
              controller: _tabController,
              labelStyle: Theme.of(context).textTheme.titleSmall,
              tabs: [
                if (showDescription) const Tab(text: 'Description'),
                if (showReviews) const Tab(text: 'Reviews'),
                if (showMarkers) const Tab(text: 'Markers'),
                if (showChapters) const Tab(text: 'Chapters'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                if (showDescription)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SingleChildScrollView(
                      child: Text(
                        widget.book.description!,
                      ),
                    ),
                  ),
                if (showReviews) const Text('Reviews'),
                if (showMarkers) const Text("Markers"),
                if (showChapters)
                  MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      child: ListView.separated(
                        itemBuilder: (_, i) {
                          return Text(widget.book.chapters[i]);
                        },
                        separatorBuilder: (_, i) => const SizedBox(height: 10),
                        itemCount: widget.book.chapters.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                if (widget.onSecondaryButtonPress != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 8,
                      right: 0,
                    ),
                    child: TextButton(
                      onPressed: widget.onSecondaryButtonPress!,
                      child: const SizedBox(
                        height: 64,
                        width: 64,
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextButton(
                      onPressed: widget.onMainButtonPress,
                      child: SizedBox(
                        height: 64,
                        child: Center(
                          child: Text(
                            widget.book.savedData == null ? "Download" : "Read",
                            style: const TextStyle(
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _Top extends StatefulWidget {
  const _Top({
    Key? key,
    required this.book,
    required this.book3dData,
    this.previousBookData,
    required this.wordsPerPage,
  }) : super(key: key);

  final Book book;
  final Book3DData book3dData;
  final BookInfoPreviousBookData? previousBookData;
  final double wordsPerPage;

  @override
  State<_Top> createState() => _TopState();
}

enum ProgressDisplayType {
  percentage,
  pagesLeft,
}

class _TopState extends State<_Top> {
  ProgressDisplayType progressDisplayType = ProgressDisplayType.percentage;
  // Book3DData? book3dData;

  // @override
  // void initState() {
  //   if (widget.book.coverProvider != null) {
  //     (() async {
  //       book3dData =
  //           await Book3DData.fromImageProvider(widget.book.coverProvider!);
  //       setState(() {
  //         book3dData = book3dData;
  //       });
  //     })();
  //   }
  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final tags = widget.book.tags;
    double currentRotation = 0;

    double bookProgress = 0;
    int bookPageProgress = 0;

    if (widget.book.savedData != null) {
      bookProgress = widget.book.savedData!.readProgress;
      bookPageProgress = widget.book.savedData!.getPages(widget.wordsPerPage) -
          widget.book.savedData!.getBookPageProgress(widget.wordsPerPage);
    }

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 170),
          width: size.width,
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.transparent,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            color: Theme.of(context).primaryColor,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Visibility(
                  visible: widget.book.pages != null,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Progress"),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            progressDisplayType = progressDisplayType ==
                                    ProgressDisplayType.percentage
                                ? ProgressDisplayType.pagesLeft
                                : ProgressDisplayType.percentage;
                          });
                        },
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: widget.book.savedData == null
                              ? Container()
                              : Stack(
                                  children: [
                                    Center(
                                      child: Text(
                                        progressDisplayType ==
                                                ProgressDisplayType.percentage
                                            ? "${(bookProgress * 100).floor()}%"
                                            : "$bookPageProgress \nleft",
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge,
                                      ),
                                    ),
                                    Center(
                                      child: SizedBox(
                                        width: 50,
                                        height: 50,
                                        child: Transform(
                                          alignment: Alignment.center,
                                          transform: Matrix4.rotationY(pi),
                                          child: CircularProgressIndicator(
                                            value: bookProgress,
                                            strokeWidth: 6,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.only(left: 10, right: 10),
          height: 270,
          child: Row(
            children: [
              SizedBox(
                width: 150,
                height: 200,
                child: Center(
                  child: HeroMode(
                    enabled: widget.previousBookData != null,
                    child: Hero(
                      flightShuttleBuilder: (
                        BuildContext flightContext,
                        Animation<double> animation,
                        HeroFlightDirection flightDirection,
                        BuildContext fromHeroContext,
                        BuildContext toHeroContext,
                      ) {
                        final borderRadiusTween = BorderRadiusTween(
                          begin: widget.previousBookData!.borderRadius,
                          end: const BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                            topLeft: Radius.circular(0),
                            bottomLeft: Radius.circular(0),
                          ),
                        );
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            return Center(
                              child: Book3D(
                                book3dData: widget.book3dData,
                                spreadRadius:
                                    progressValue(0, 7, animation.value),
                                borderRadius:
                                    borderRadiusTween.lerp(animation.value),
                                rotateY: progressValue(
                                  widget.previousBookData!.rotateY,
                                  (currentRotation % (2 * pi)) + 2 * pi,
                                  animation.value,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      tag: widget.previousBookData?.heroTag ?? "",
                      child: Book3dInteractive(
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                        spreadRadius: 7,
                        pageDepth: 5,
                        book3dData: widget.book3dData,
                        onRotationChanged: (rotateY) =>
                            currentRotation = rotateY,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Text(
                          "By ${widget.book.getAuthors()}",
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.titleMedium,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ShaderMask(
                        shaderCallback: (rect) {
                          return LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Theme.of(context)
                                  .backgroundColor
                                  .withOpacity(0.25),
                              Colors.transparent,
                            ],
                          ).createShader(
                            Rect.fromLTRB(0, 0, rect.width, rect.height),
                          );
                        },
                        blendMode: BlendMode.dstIn,
                        child: SizedBox(
                          height: 30,
                          child: ListView.separated(
                            separatorBuilder: (context, index) =>
                                const SizedBox(width: 10),
                            scrollDirection: Axis.horizontal,
                            itemCount: tags.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(5),
                                  ),
                                ),
                                child: Center(child: Text(tags[index])),
                              );
                            },
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
