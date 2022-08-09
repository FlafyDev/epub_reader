// Where in the book you currently are.
import 'package:epubz/epubz.dart';
import 'package:equatable/equatable.dart';

class EpubLocation<PageType, Nav extends EpubInnerNavigation>
    extends Equatable {
  final PageType page;
  final Nav innerNav;

  const EpubLocation(
    this.page,
    this.innerNav,
  );

  // from EpubChapter
  static EpubLocation<String, EpubInnerAnchor> fromEpubChapter(
          EpubChapter chapter) =>
      EpubLocation(
        chapter.ContentFileName!,
        EpubInnerAnchor(chapter.Anchor ?? ""),
      );

  Map<String, dynamic> toJson() => {
        'page': page,
        'innerNav': innerNav.toJson(),
      };

  static EpubLocation<PageType, Nav>
      fromJson<PageType, Nav extends EpubInnerNavigation>(
          Map<String, dynamic> json) {
    return EpubLocation<PageType, Nav>(
      json['page'],
      EpubInnerNavigation.fromJson(json['innerNav'] as Map<String, dynamic>)
          as Nav,
    );
  }

  @override
  List<Object?> get props => [page, innerNav];
}

abstract class EpubInnerNavigation extends Equatable {
  Map<String, dynamic> toJson();

  static EpubInnerNavigation fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String) {
      case 'page':
        return EpubInnerPage.fromJson(json);
      case 'anchor':
        return EpubInnerAnchor.fromJson(json);
      case 'textNode':
        return EpubInnerTextNode.fromJson(json);
      case 'node':
        return EpubInnerNode.fromJson(json);
      case 'element':
        return EpubInnerElement.fromJson(json);
      default:
        throw Exception('Unknown inner navigation type');
    }
  }
}

abstract class EpubConsistentInnerNavigation extends EpubInnerNavigation {}

class EpubInnerPage extends EpubInnerNavigation {
  final int page;

  EpubInnerPage(this.page);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'page',
        'page': page,
      };

  static EpubInnerPage fromJson(Map<String, dynamic> json) {
    return EpubInnerPage(json['page'] as int);
  }

  @override
  List<Object?> get props => [page];
}

class EpubInnerAnchor extends EpubConsistentInnerNavigation {
  final String anchor;

  EpubInnerAnchor(this.anchor);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'anchor',
        "anchor": anchor,
      };

  static EpubInnerAnchor fromJson(Map<String, dynamic> json) =>
      EpubInnerAnchor(json["anchor"]);

  @override
  List<Object?> get props => [anchor];
}

class EpubInnerNode extends EpubConsistentInnerNavigation {
  final int nodeIndex;
  final int characterIndex;

  EpubInnerNode(this.nodeIndex, this.characterIndex);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'node',
        "nodeIndex": nodeIndex,
        "characterIndex": characterIndex,
      };

  static EpubConsistentInnerNavigation fromJson(Map<String, dynamic> json) =>
      EpubInnerNode(json["nodeIndex"], json["characterIndex"]);

  @override
  List<Object?> get props => [nodeIndex, characterIndex];
}

class EpubInnerTextNode extends EpubConsistentInnerNavigation {
  final int textNodeIndex;
  final int characterIndex;

  EpubInnerTextNode(this.textNodeIndex, this.characterIndex);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'textNode',
        "textNodeIndex": textNodeIndex,
        "characterIndex": characterIndex,
      };

  static EpubConsistentInnerNavigation fromJson(Map<String, dynamic> json) =>
      EpubInnerTextNode(json["textNodeIndex"], json["characterIndex"]);

  @override
  List<Object?> get props => [textNodeIndex, characterIndex];
}

class EpubInnerElement extends EpubConsistentInnerNavigation {
  final int elementIndex;

  EpubInnerElement(this.elementIndex);

  @override
  Map<String, dynamic> toJson() => {
        'type': 'element',
        "elementIndex": elementIndex,
      };

  static EpubConsistentInnerNavigation fromJson(Map<String, dynamic> json) =>
      EpubInnerElement(json["elementIndex"]);

  @override
  List<Object?> get props => [elementIndex];
}

// EpubConsistentInnerNavigation epubConsistentInnerNavigationFromJson(
//     Map<String, dynamic> json) {
//   if (json.containsKey("textNodeIndex")) {
//     return EpubInnerTextNode(
//       json["textNodeIndex"] as int,
//       json["characterIndex"] as int,
//     );
//   } else if (json.containsKey("elementIndex")) {
//     return EpubInnerElement(
//       json["elementIndex"] as int,
//     );
//   } else if (json.containsKey("anchor")) {
//     return EpubInnerAnchor(
//       json["anchor"] as String,
//     );
//   } else {
//     throw Exception("Unknown consistent inner navigation type");
//   }
// }
