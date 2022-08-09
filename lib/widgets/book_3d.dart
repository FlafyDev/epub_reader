import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'dart:ui' as ui;
import '../models/book.dart';
import '../utils/lighten_color.dart';
import '../utils/progress_value.dart';

enum Side {
  front,
  back,
  starboard,
  port,
}

class Book3DData {
  Size coverSize;
  Color coverColor;
  int? pages;
  ImageProvider? coverProvider;

  Book3DData({
    required this.coverSize,
    required this.coverColor,
    this.pages,
    this.coverProvider,
  });

  static Future<Book3DData> fromBook(Book book) async {
    if (book.savedData != null) {
      return fromSavedData(book);
    } else {
      return await fromImageProvider(book);
    }
  }

  static Book3DData fromSavedData(Book book) {
    assert(book.savedData != null);

    return Book3DData(
      coverSize: book.savedData!.data.coverSize,
      coverColor: book.savedData!.data.coverColor,
      // pages: book.pages,
      pages: 500,
      coverProvider: book.coverProvider,
    );
  }

  static Future<Book3DData> fromImageProvider(Book book) async {
    assert(book.coverProvider != null);

    final completer = Completer<ui.Image?>();

    book.coverProvider!
        .resolve(const ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo info, bool _) async {
          completer.complete(info.image);
        }, onError: (e, a) {
          completer.complete(null);
        }));

    ui.Image? coverImg = await completer.future;

    if (coverImg == null) {
      throw Exception();
    }

    final coverColor =
        (await PaletteGenerator.fromImage(coverImg)).dominantColor!.color;

    return Book3DData(
      coverSize: Size(coverImg.width.toDouble(), coverImg.height.toDouble()),
      coverColor: coverColor,
      pages: book.pages,
      coverProvider: book.coverProvider!,
    );
  }
}

class Book3D extends StatefulWidget {
  const Book3D({
    Key? key,
    required this.book3dData,
    double rotateY = 0.0,
    this.pageDepth = 4.0,
    coverOpenRotate = 0.0,
    this.spreadRadius,
    this.borderRadius,
  })  : rotateY = rotateY % (pi * 2),
        coverOpenRotate = coverOpenRotate % (pi * 2),
        assert(!(coverOpenRotate != 0 && rotateY != 0)),
        super(key: key);

  final Book3DData book3dData;
  final double rotateY;
  final double coverOpenRotate;
  final double pageDepth;
  final BorderRadius? borderRadius;
  final double? spreadRadius;

  @override
  State<Book3D> createState() => _Book3DState();
}

class _Book3DState extends State<Book3D> {
  // Color? dominantColor;

  // @override
  // void initState() {
  //   (() async {
  //     final pallette = await PaletteGenerator.(
  //       widget.book.cover
  //     );
  //     setState(() {
  //       dominantColor = pallette.dominantColor!.color;
  //     });
  //   })();

  //   super.initState();
  // }

  double width = 0, height = 0, depth = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      double diff = max(
          widget.book3dData.coverSize.width / constraints.maxWidth,
          widget.book3dData.coverSize.height / constraints.maxHeight);
      bool coverOpen = widget.coverOpenRotate != 0;

      width = widget.book3dData.coverSize.width / diff;
      height = widget.book3dData.coverSize.height / diff;
      // depth = min(max(10, (widget.book.pages ?? 100).toDouble() / 15), 60);
      depth = width /
          5 *
          min(max(0.1, (widget.book3dData.pages ?? 400).toDouble() / 400), 3);

      final front = _buildSide(Side.front);
      final back = _buildSide(Side.back);
      final starboard = _buildSide(Side.starboard);
      final port = _buildSide(Side.port);

      late final List<Widget> children;
      if (widget.rotateY < pi / 2) {
        children = [back, starboard, front];
      } else if (widget.rotateY < pi / 1) {
        children = [front, starboard, back];
      } else if (widget.rotateY < pi * 1.5) {
        children = [front, port, back];
      } else if (widget.rotateY < pi * 2) {
        children = [port, front];
      } else {
        children = [front];
      }

      var prog = widget.rotateY % pi / (pi / 2);

      if (prog > 1) {
        prog = 1 - (prog % 1);
      }

      return Stack(
        children: [
          Center(
            child: Container(
              height: height,
              width: min(
                progressValue(
                      width,
                      depth,
                      prog,
                    ) +
                    (1 - prog) * (width / 2),
                width,
              ),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.black.withOpacity(0.2)
                        : Colors.white.withOpacity(0.2),
                    spreadRadius: widget.spreadRadius ?? 0,
                    blurRadius: 20,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Transform(
              transform: coverOpen
                  ? Matrix4.identity()
                  : (Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(widget.rotateY)),
              alignment: Alignment.center,
              child: Stack(children: children),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSide(Side side) {
    final bool coverOpen = widget.coverOpenRotate != 0;
    final double rotation = coverOpen ? widget.coverOpenRotate : widget.rotateY;

    switch (side) {
      case Side.front:
      case Side.back:
        final bool isFront = side == Side.front;
        final Matrix4 matrix =
            Matrix4.translationValues(0.0, 0.0, depth / 2 * (isFront ? -1 : 1));

        if (coverOpen) {
          matrix
            ..setEntry(3, 2, 0.001)
            ..rotateY(isFront ? rotation : 0);
        }

        return Transform(
          origin: Offset(-width / 2, 0),
          transform: matrix,
          alignment: Alignment.center,
          child: (isFront && !(rotation > pi / 2 && rotation < pi * 1.5))
              ? widget.book3dData.coverProvider == null
                  ? SizedBox(
                      width: width,
                      height: height,
                      child: const Text("no image"),
                    )
                  : Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        borderRadius: widget.borderRadius,
                        image: DecorationImage(
                          image: widget.book3dData.coverProvider!,
                          isAntiAlias: true,
                          filterQuality: FilterQuality.medium,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
              : Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: widget.borderRadius,
                    color: coverOpen && !isFront
                        ? Colors.white
                        : lightenColor(widget.book3dData.coverColor, 0.02),
                  ),
                ),
        );
      case Side.starboard:
      case Side.port:
        final double translate;
        translate = width / 2 * (side == Side.starboard ? 1 : -1) -
            (rotation > pi ? 0 : widget.pageDepth);

        final Matrix4 transform;

        transform = Matrix4.identity()
          ..translate(translate)
          ..rotateY(pi / 2);

        return Positioned.fill(
          child: Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: rotation > pi
                      ? widget.book3dData.coverColor
                      : Colors.grey[300],
                ),
                width: depth,
                height: side == Side.port ? height : height - 5,
              ),
            ),
          ),
        );
    }
  }
}
