import 'dart:convert';
import 'dart:math';
import 'package:epub_reader/models/book_saved_data.dart';
import 'package:epub_reader/utils/enum_from_index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'epub_location.dart';

class EpubPage {
  final String content;
  EpubPage(this.content);
}

class EpubMargin {
  double side;
  double top;
  double bottom;

  EpubMargin({
    required this.side,
    required this.top,
    required this.bottom,
  });

  EpubMargin.fromJson(Map<String, dynamic> json)
      : side = json['side'],
        top = json['top'],
        bottom = json['bottom'];

  Map<String, dynamic> toJson() {
    return {
      'side': side,
      'top': top,
      'bottom': bottom,
    };
  }
}

class EpubSelectionData {
  final String text;
  final List<SavedNoteRangeData> rangesData;
  final Rectangle rect;

  EpubSelectionData({
    required this.text,
    required this.rangesData,
    required this.rect,
  });
}

enum EpubStyleThemes {
  light,
  dark,
}

class EpubStyleProperties {
  EpubMargin margin;
  double fontSizeMultiplier;
  double lineHeightMultiplier;
  double weightMultiplier;
  int letterSpacingAdder;
  int wordSpacingAdder;
  String align;
  String fontFamily;
  String fontPath;
  EpubStyleThemes theme;

  EpubStyleProperties({
    required this.margin,
    required this.fontSizeMultiplier,
    required this.lineHeightMultiplier,
    required this.letterSpacingAdder,
    required this.wordSpacingAdder,
    required this.weightMultiplier,
    required this.align,
    required this.fontFamily,
    required this.fontPath,
    required this.theme,
  });

  EpubStyleProperties.fromJson(Map<String, dynamic> json)
      : margin = EpubMargin.fromJson(json['margin']),
        fontSizeMultiplier = json['fontSizeMultiplier'],
        lineHeightMultiplier = json['lineHeightMultiplier'],
        letterSpacingAdder = json['letterSpacingAdder'] ?? 0,
        wordSpacingAdder = json['wordSpacingAdder'] ?? 0,
        align = json['align'],
        fontFamily = json['fontFamily'],
        fontPath = json['fontPath'],
        weightMultiplier = json['weightMultiplier'] ?? 1,
        theme = enumFromIndex(
          EpubStyleThemes.values,
          json['theme'],
          def: EpubStyleThemes.dark,
        );

  Map<String, dynamic> toJson() {
    return {
      'margin': margin.toJson(),
      'fontSizeMultiplier': fontSizeMultiplier,
      'lineHeightMultiplier': lineHeightMultiplier,
      'letterSpacingAdder': letterSpacingAdder,
      'wordSpacingAdder': wordSpacingAdder,
      'align': align,
      'fontFamily': fontFamily,
      'fontPath': fontPath,
      'weightMultiplier': weightMultiplier,
      'theme': theme.index,
    };
  }
}

class EpubRendererController {
  final void Function(EpubLocation<int, EpubInnerNavigation>, bool forced,
      List<SavedNote> Function(int page)?) setLocation;
  final EpubLocation<int, EpubInnerPage> Function() getLocation;
  final void Function(EpubStyleProperties) _updateStyle;
  final void Function(String) _updateCss;
  final void Function() clearSelection;

  var styleProperties = EpubStyleProperties(
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
    fontFamily: 'Arial',
    fontPath: '',
    theme: EpubStyleThemes.dark,
  );
  EpubLocation<int, EpubConsistentInnerNavigation> consistentLocation =
      EpubLocation(
    0,
    EpubInnerAnchor(""),
  );
  String css = "";
  int? innerPages;
  bool _isReady = false;
  List<String> passedAnchors = [];

  EpubRendererController({
    required void Function(EpubLocation<int, EpubInnerNavigation>, bool forced,
            List<SavedNote> Function(int page)?)
        onLocation,
    required this.getLocation,
    required void Function(EpubStyleProperties) onStyle,
    required void Function(String) onCss,
    required void Function() onClearSelection,
  })  : setLocation = onLocation,
        _updateStyle = onStyle,
        _updateCss = onCss,
        clearSelection = onClearSelection;

  EpubLocation<int, EpubInnerPage> get location => getLocation();

  void updateStyle() {
    _updateStyle(styleProperties);
  }

  void updateCss() {
    _updateCss(css);
  }

  bool get isReady => _isReady;
}

class EpubRenderer extends StatefulWidget {
  const EpubRenderer({
    Key? key,
    required this.getPageFile,
    required this.onLoaded,
    required this.onReadyChanged,
    required this.onSelection,
    required this.maxPages,
    required this.onLinkPressed,
    required this.onNotePressed,
  }) : super(key: key);

  final String Function(int) getPageFile;
  final void Function(EpubRendererController) onLoaded;
  final void Function(bool isReady) onReadyChanged;
  final void Function(EpubSelectionData selection) onSelection;
  final void Function(String) onLinkPressed;
  final void Function(String) onNotePressed;
  final int maxPages;

  @override
  _EpubRendererState createState() => _EpubRendererState();
}

class _EpubRendererState extends State<EpubRenderer> {
  late InAppWebViewController webViewController;
  late EpubRendererController controller;
  bool isLoaded = false;
  bool _isReady = false;
  String noWebViewText = "";
  var currentLocation = EpubLocation(0, EpubInnerPage(0));

  bool get isReady {
    return _isReady;
  }

  set isReady(bool ready) {
    setState(() {
      _isReady = ready;
    });
    controller._isReady = ready;
    widget.onReadyChanged(ready);
  }

  void onLocation(
    EpubLocation<int, EpubInnerNavigation> newLocation,
    bool forced,
    List<SavedNote> Function(int page)? getNotes,
  ) {
    isReady = false;

    List<Map<String, Object>> notesToJson(int page) {
      return (getNotes?.call(page) ?? [])
          .map(
            (note) => {
              "id": note.id,
              "ranges": note.rangesData.map((range) => range.toJson()).toList(),
              "color": note.color.index,
              "hasDescription": note.description.isNotEmpty
            },
          )
          .toList();
    }

    if (newLocation.innerNav is EpubInnerPage) {
      var page = newLocation.page;
      var innerPage = (newLocation.innerNav as EpubInnerPage).page;
      if (controller.innerPages != null &&
          innerPage >= controller.innerPages!) {
        page++;
        innerPage = 0;
        controller.innerPages = null;
      }

      if (innerPage < 0) {
        page--;
        innerPage = -1;
        controller.innerPages = null;
      }

      page = page.clamp(0, widget.maxPages - 1);

      newLocation = EpubLocation(page, EpubInnerPage(innerPage));

      runJSFunction(
        "page",
        [widget.getPageFile(page), innerPage, forced, notesToJson(page)],
      );
    } else if (newLocation.innerNav is EpubInnerAnchor) {
      runJSFunction(
        "pageAnchor",
        [
          widget.getPageFile(newLocation.page),
          (newLocation.innerNav as EpubInnerAnchor).anchor,
          forced,
          notesToJson(newLocation.page),
        ],
      );
    } else if (newLocation.innerNav is EpubInnerTextNode) {
      final innerNav = newLocation.innerNav as EpubInnerTextNode;
      runJSFunction(
        "pageTextNode",
        [
          widget.getPageFile(newLocation.page),
          innerNav.textNodeIndex,
          innerNav.characterIndex,
          forced,
          notesToJson(newLocation.page),
        ],
      );
    } else if (newLocation.innerNav is EpubInnerNode) {
      final innerNav = newLocation.innerNav as EpubInnerNode;
      runJSFunction(
        "pageNode",
        [
          widget.getPageFile(newLocation.page),
          innerNav.nodeIndex,
          innerNav.characterIndex,
          forced,
          notesToJson(newLocation.page),
        ],
      );
    } else if (newLocation.innerNav is EpubInnerElement) {
      runJSFunction(
        "pageTextNode",
        [
          widget.getPageFile(newLocation.page),
          (newLocation.innerNav as EpubInnerElement).elementIndex,
          forced,
          notesToJson(newLocation.page),
        ],
      );
    } else {
      throw Exception("unknown innerNav type.");
    }

    currentLocation = EpubLocation(newLocation.page, EpubInnerPage(0));
  }

  void onStyle(EpubStyleProperties style) {
    runJSFunction("style", [
      style,
    ]);
  }

  void onCss(String css) {
    runJSFunction("css", [
      controller.css,
    ]);
  }

  void onLoad(List<dynamic> args) {
    isLoaded = true;
    controller = EpubRendererController(
      onLocation: onLocation,
      getLocation: () => currentLocation,
      onStyle: onStyle,
      onCss: onCss,
      onClearSelection: () {
        runJSFunction("clearSelection", []);
      },
    );
    widget.onLoaded(controller);
  }

  void onReady(args) {
    currentLocation = EpubLocation(
      currentLocation.page,
      EpubInnerPage(args[0] as int),
    );
    controller.innerPages = args[1] as int;
    controller.passedAnchors =
        (args[2] as List<dynamic>).map((e) => e.toString()).toList();
    // print("SET PASSED: ${controller.passedAnchors} ${controller.innerPages}");

    final consistentInnerNavigationJson = args[3] as Map<String, dynamic>;

    controller.consistentLocation = EpubLocation(
      currentLocation.page,
      EpubInnerNavigation.fromJson(consistentInnerNavigationJson)
          as EpubConsistentInnerNavigation,
    );

    isReady = true;
  }

  void runJSFunction(String name, List<Object> arguments) {
    String stringArguments = arguments.map((arg) => jsonEncode(arg)).join(',');
    webViewController.evaluateJavascript(
      source: "window.$name($stringArguments);",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: isReady ? 1 : 0,
          child: InAppWebView(
            initialOptions: InAppWebViewGroupOptions(
              android: AndroidInAppWebViewOptions(
                useHybridComposition: false,
              ),
            ),
            // gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            //   Factory<TapGestureRecognizer>(
            //     () {
            //       return TapGestureRecognizer();
            //     },
            //   ),
            //   Factory<LongPressGestureRecognizer>(
            //     () {
            //       return LongPressGestureRecognizer();
            //     },
            //   ),
            // },
            onWebViewCreated: (controller) async {
              webViewController = controller;
              webViewController.addJavaScriptHandler(
                handlerName: "load",
                callback: onLoad,
              );

              webViewController.addJavaScriptHandler(
                handlerName: "ready",
                callback: onReady,
              );

              webViewController.addJavaScriptHandler(
                handlerName: "notePress",
                callback: (args) {
                  widget.onNotePressed(args[0] as String);
                },
              );

              webViewController.addJavaScriptHandler(
                handlerName: "link",
                callback: (args) {
                  widget.onLinkPressed(args[0] as String);
                },
              );

              webViewController.addJavaScriptHandler(
                handlerName: "selection",
                callback: (args) {
                  widget.onSelection(
                    EpubSelectionData(
                      text: args[0] as String,
                      rangesData: (args[1] as List)
                          .map(
                            (rangeDataJson) =>
                                SavedNoteRangeData.fromJson(rangeDataJson),
                          )
                          .toList(),
                      rect: Rectangle(
                        (args[2] as int).toDouble(),
                        (args[3] as int).toDouble(),
                        (args[4] as int).toDouble(),
                        (args[5] as int).toDouble(),
                      ),
                    ),
                  );
                },
              );

              controller.loadUrl(
                urlRequest: URLRequest(
                  url: Uri.parse("http://localhost:8080"),
                ),
              );
              // await controller.loadData(
              //     data: await rootBundle.loadString(widget.htmlPath));
            },
          ),
        ),
        if (!isReady)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}
