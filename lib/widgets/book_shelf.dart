import 'dart:math';

import 'package:epub_reader/pages/book_info.dart';
import 'package:epub_reader/widgets/book_3d.dart';
import 'package:flutter/material.dart';
import '../managers/settings_manager.dart';
import '../models/book.dart';

class BookShelf extends StatefulWidget {
  const BookShelf({
    Key? key,
    required this.shelf,
    required this.height,
    required this.onBookSelected,
    required this.onPressDelete,
    required this.onChangeBookShelves,
  }) : super(key: key);

  final Shelf shelf;
  final double height;
  final void Function(
    Book,
    Book3DData, {
    BookInfoPreviousBookData? previousBookData,
  }) onBookSelected;
  final void Function() onPressDelete;
  final void Function(Book) onChangeBookShelves;

  @override
  _BookShelfState createState() => _BookShelfState();
}

class _BookShelfState extends State<BookShelf> {
  late PageController pageController;
  final ValueNotifier<double> notifier = ValueNotifier<double>(0);
  List<Book3DData> books3dData = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final books = widget.shelf.books;

    return Column(
      children: [
        InkWell(
          onTap: widget.onPressDelete,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              widget.shelf.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        const SizedBox(height: 10),
        books.isEmpty
            ? Container()
            : LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  pageController = PageController(
                    initialPage: 0,
                    viewportFraction: constraints.maxWidth / 1200,
                  )..addListener(() {
                      notifier.value = pageController.page ?? 0;
                    });

                  return SizedBox(
                    height: widget.height,
                    child: PageView.builder(
                      controller: pageController,
                      itemCount: books.length,
                      itemBuilder: (context, index) {
                        final book = books[index];
                        final book3dData = Book3DData.fromSavedData(book);
                        final sizedBoxKey = GlobalKey();

                        double getRotateY() {
                          final double middle = notifier.value - index;
                          return pi / 15 * middle;
                        }

                        final heroTag = "book3d-${book.savedData!.bookId}";

                        return InkWell(
                          onTap: () {
                            widget.onBookSelected(
                              book,
                              book3dData,
                              previousBookData: BookInfoPreviousBookData(
                                rotateY: getRotateY(),
                                heroTag: heroTag,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(4),
                                  bottomRight: Radius.circular(4),
                                  topLeft: Radius.circular(0),
                                  bottomLeft: Radius.circular(0),
                                ),
                              ),
                            );
                          },
                          onLongPress: () => widget.onChangeBookShelves(book),
                          child: Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.all(8),
                                height: widget.height - 40 - 16,
                                key: sizedBoxKey,
                                child: AnimatedBuilder(
                                  animation: notifier,
                                  builder: (context, w) {
                                    return LayoutBuilder(
                                        builder: (context, constraints) {
                                      return SizedBox(
                                        width: constraints.maxWidth,
                                        height: constraints.maxHeight,
                                        child: Center(
                                          child: Hero(
                                            tag: heroTag,
                                            child: Book3D(
                                              rotateY: getRotateY(),
                                              book3dData: book3dData,
                                              borderRadius:
                                                  const BorderRadius.only(
                                                topRight: Radius.circular(4),
                                                bottomRight: Radius.circular(4),
                                                topLeft: Radius.circular(0),
                                                bottomLeft: Radius.circular(0),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    });
                                  },
                                ),
                              ),
                              SizedBox(
                                height: 40,
                                width: 120,
                                child: Text(
                                  book.name,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ],
    );
  }
}
