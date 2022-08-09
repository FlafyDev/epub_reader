import 'package:epubz/epubz.dart';
// ignore: implementation_imports
import 'package:epubz/src/schema/opf/epub_manifest_item.dart';

List<EpubManifestItem> getSpineItemsFromEpub(EpubBook epubBook) {
  return epubBook.Schema!.Package!.Spine!.Items!
      .map((item) => epubBook.Schema!.Package!.Manifest!.Items!
          .where((element) => element.Id == item.IdRef)
          .first)
      .toList();
}
