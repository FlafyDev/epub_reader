import 'dart:math';

import 'package:epub_reader/utils/get_files_from_epub_spine.dart';
import 'package:epub_reader/widgets/epub_renderer/epub_location.dart';
import 'package:epub_reader/widgets/epub_renderer/epub_server_files.dart';
import 'package:epubz/epubz.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../models/book_saved_data.dart';
import '../epub_renderer/epub_renderer.dart';
import 'package:url_launcher/url_launcher.dart';

final isUrlRegex = RegExp("^(?:[a-z+]+:)?//", caseSensitive: false);

class BookPlayerRendererController {
  final void Function() clearSelection;
  final void Function(EpubLocation, {bool forced}) setLocation;
  final EpubRendererController Function() _getCurrentController;
  final EpubStyleProperties style;
  final void Function(EpubStyleProperties) _setStyle;

  BookPlayerRendererController({
    required this.style,
    required void Function() onClearSelection,
    required void Function(EpubLocation epubLocation, {bool forced})
        onSetLocation,
    required EpubRendererController Function() getCurrentController,
    required void Function(EpubStyleProperties) onStyle,
  })  : clearSelection = onClearSelection,
        setLocation = onSetLocation,
        _getCurrentController = getCurrentController,
        _setStyle = onStyle;

  EpubRendererController get currentController {
    return _getCurrentController();
  }

  updateStyle() {
    _setStyle(style);
  }
}

class _EpubRendererContainer {
  final EpubRenderer renderer;
  late EpubRendererController controller;
  final int id;

  _EpubRendererContainer({
    required this.renderer,
    required this.id,
  });
}

class BookPlayerRenderer extends StatefulWidget {
  BookPlayerRenderer({
    Key? key,
    required this.width,
    required this.height,
    required this.epubBook,
    required this.initialLocation,
    required this.onSelection,
    required this.server,
    required this.initialStyle,
    this.onSaveLocation,
    this.controllerCreated,
    required this.savedNotes,
    this.onNotePressed,
  })  : maxPages = epubBook.Schema!.Package!.Spine!.Items!.length,
        super(key: key);

  final double width;
  final double height;
  final EpubBook epubBook;
  final EpubLocation initialLocation;
  final void Function(EpubSelectionData selection) onSelection;
  final int maxPages;
  final void Function(BookPlayerRendererController controller)?
      controllerCreated;
  final EpubServerFiles server;
  final EpubStyleProperties initialStyle;
  final void Function(
          EpubLocation<int, EpubConsistentInnerNavigation> epubLocation)?
      onSaveLocation;
  final List<SavedNote> savedNotes;
  final void Function(SavedNote)? onNotePressed;

  @override
  _BookRendererState createState() => _BookRendererState();
}

class _BookRendererState extends State<BookPlayerRenderer>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  // List<EpubRenderer> epubRenderers = [];
  // late List<EpubRendererController> epubRenderersControllers;
  // late List<bool> epubRenderersReady;
  List<_EpubRendererContainer> epubRenderers = [];
  late EpubRendererController currentEpubRendererController;

  final progress = ValueNotifier<double>(0);
  double startDraggingProgress = 0;
  late Offset startDraggingPosition;
  bool canTransitionPages = false;
  bool dragging = false;
  late Tween<double> transitionTween;

  bool settingLocation = false;
  late EpubServerFiles filesProvider;
  bool lastForced = false;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(vsync: this);
    transitionTween = Tween<double>(
      begin: 0,
      end: 1,
    );
    final _animation = transitionTween.animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOut,
      ),
    );

    filesProvider = EpubServerFiles(widget.epubBook);

    _animation.addListener(() {
      progress.value = _animation.value;

      if (_animation.isCompleted) {
        onDragAnimationEnd();
      }
    });

    const renderers = 3;

    final tempControllers = <int, EpubRendererController>{};

    for (int i = 0; i < renderers; i++) {
      epubRenderers.add(_EpubRendererContainer(
        id: i,
        renderer: EpubRenderer(
          onNotePressed: (String noteId) {
            widget.onNotePressed?.call(widget.savedNotes
                .firstWhere((savedNote) => savedNote.id == noteId));
          },
          onLinkPressed: (String link) {
            if (isUrlRegex.hasMatch(link)) {
              launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
            } else {
              final parts = link.split("#");
              setLocation(EpubLocation(
                parts[0],
                EpubInnerAnchor(parts.length > 1 ? parts[1] : ""),
              ));
            }
          },
          onLoaded: (controller) {
            tempControllers[i] = controller;
            if (tempControllers.entries.length == renderers) {
              for (var renderer in epubRenderers) {
                renderer.controller = tempControllers[renderer.id]!;
              }

              onAllLoaded();
            }
          },
          getPageFile: getPageFile,
          onReadyChanged: (bool _isReady) {
            onReadyChanged();
          },
          onSelection: widget.onSelection,
          maxPages: widget.maxPages,
        ),
      ));
    }
  }

  String getPageFile(int page) {
    return getFilesFromEpubSpine(widget.epubBook)[page].FileName!;
  }

  void clearSelection() {
    for (var renderer in epubRenderers) {
      renderer.controller.clearSelection();
    }
  }

  void onAllLoaded() {
    if (widget.controllerCreated != null) {
      widget.controllerCreated!(BookPlayerRendererController(
        onClearSelection: clearSelection,
        onSetLocation: setLocation,
        getCurrentController: () => currentEpubRendererController,
        onStyle: (style) {
          for (var renderer in epubRenderers) {
            renderer.controller.styleProperties = style;
            renderer.controller.updateStyle();
          }
        },
        style: widget.initialStyle,
      ));
    }

    currentEpubRendererController =
        epubRenderers.firstWhere((renderer) => renderer.id == 1).controller;

    for (var renderer in epubRenderers) {
      renderer.controller.styleProperties = widget.initialStyle;
      renderer.controller.updateCss();
      renderer.controller.updateStyle();
    }

    setLocation(widget.initialLocation);
  }

  void onReadyChanged() {
    final allReady = canTransitionPages =
        epubRenderers.every((renderer) => renderer.controller.isReady);

    if (allReady) {
      if (widget.onSaveLocation != null) {
        widget
            .onSaveLocation!(currentEpubRendererController.consistentLocation);
      }
    }

    if (settingLocation && currentEpubRendererController.isReady) {
      canTransitionPages = false;
      settingLocation = false;
      updatePages();
      lastForced = false;
    }
  }

  void onDragAnimationEnd() {
    // canTransitionPages = true;
    updatePages();
  }

  void updatePages() {
    progress.value = progress.value.roundToDouble() % 3;

    final currentEpubRenderer = epubRenderers.firstWhere(
        (renderer) => renderer.id == (progress.value.round() + 1) % 3);
    final rightRenderer = epubRenderers.firstWhere(
        (renderer) => renderer.id == (progress.value.round() + 2) % 3);
    final leftRenderer = epubRenderers.firstWhere(
        (renderer) => renderer.id == (progress.value.round() + 3) % 3);

    // Layering
    setState(() {
      epubRenderers = [
        rightRenderer,
        currentEpubRenderer,
        leftRenderer,
      ];
    });

    currentEpubRendererController = currentEpubRenderer.controller;

    final currentLocation = currentEpubRendererController.location;
    final currentInnerPages = currentEpubRendererController.innerPages;

    final sides = [leftRenderer.controller, rightRenderer.controller];
    for (var i = 0; i < sides.length; i++) {
      final controller = sides[i];
      controller.innerPages = currentInnerPages;
      controller.setLocation(
        EpubLocation(
          currentLocation.page,
          EpubInnerPage(currentLocation.innerNav.page + (i * 2 - 1)),
        ),
        lastForced,
        (page) => widget.savedNotes.where((note) => note.page == page).toList(),
      );
    }
  }

  double _clampProgress(double progress) {
    final location = currentEpubRendererController.location;
    return progress.clamp(
      startDraggingProgress -
          (location.page == 0 && location.innerNav.page == 0 ? 0 : 1),
      startDraggingProgress +
          (location.page == widget.maxPages - 1 &&
                  location.innerNav.page ==
                      currentEpubRendererController.innerPages! - 1
              ? 0
              : 1),
    );
  }

  void setLocation(
    EpubLocation epubLocation, {
    bool forced = false,
  }) {
    int page;
    if (epubLocation.page is String) {
      String filePath = p.normalize(epubLocation.page as String);

      page = getFilesFromEpubSpine(widget.epubBook).indexWhere(
        (element) => element.FileName == filePath,
      );

      if (page == -1) {
        throw Exception("Page file not found in spine.");
      }
    } else {
      page = epubLocation.page as int;
    }

    settingLocation = true;
    currentEpubRendererController.setLocation(
      EpubLocation(page, epubLocation.innerNav),
      forced,
      (page) => widget.savedNotes.where((note) => note.page == page).toList(),
    );
    lastForced = forced;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onHorizontalDragStart: (details) {
            if (!canTransitionPages) {
              return;
            }
            clearSelection();
            dragging = true;
            canTransitionPages = false;
            startDraggingProgress = progress.value;
            startDraggingPosition = details.globalPosition;
          },
          onHorizontalDragUpdate: (details) {
            if (!dragging) {
              return;
            }
            final moved = details.globalPosition - startDraggingPosition;
            progress.value =
                _clampProgress(startDraggingProgress - moved.dx / 300);

            // final rightRenderer = epubRenderers.firstWhere(
            //     (renderer) => renderer.id == (progress.value.round() + 2) % 3);
          },
          onHorizontalDragEnd: (details) {
            if (!dragging) {
              return;
            }
            dragging = false;
            final startValue = progress.value;
            double endValue;

            if (details.velocity.pixelsPerSecond.dx.abs() > 60) {
              endValue = progress.value.roundToDouble() -
                  details.velocity.pixelsPerSecond.dx.sign;
            } else {
              endValue = progress.value.roundToDouble();
            }

            endValue = _clampProgress(endValue);

            if (endValue == progress.value) {
              onDragAnimationEnd();
            } else {
              animationController.reset();
              transitionTween.begin = startValue;
              transitionTween.end = endValue;
              animationController.duration = Duration(
                milliseconds:
                    (max((endValue - startValue).abs(), 0.3) * 500).round(),
              );
              animationController.forward();
            }
          },
          child: Container(
            width: widget.width,
            height: widget.height,
            color: Colors.black,
            child: Stack(
              children: epubRenderers.map((renderer) {
                return ValueListenableBuilder<double>(
                  key: ValueKey(renderer.id),
                  valueListenable: progress,
                  builder: (context, value, child) {
                    var location = ((renderer.id - value) % 3 - 1);
                    return Positioned(
                      left: (location >= 0 && location <= 1 ? 0 : location) *
                          widget.width,
                      child: SizedBox(
                        width: widget.width,
                        height: widget.height,
                        child: Stack(
                          children: [
                            Container(
                              color: Colors.black,
                            ),
                            Opacity(
                              opacity:
                                  location > 0 && location <= 1 ? value % 1 : 1,
                              child: child!,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: renderer.renderer,
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
