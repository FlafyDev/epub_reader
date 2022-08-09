import 'package:flutter/material.dart';

import '../../models/book_saved_data.dart';

enum BookPlayerBottomTextType {
  none,
  page,
}

class BookPlayerBottomText extends StatelessWidget {
  final BookPlayerBottomTextType type;
  final BookSavedData bookSavedData;
  final double wordsPerPage;

  const BookPlayerBottomText({
    Key? key,
    required this.type,
    required this.bookSavedData,
    required this.wordsPerPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    late final String left;
    late final String right;
    switch (type) {
      case BookPlayerBottomTextType.none:
        left = right = "";
        break;
      case BookPlayerBottomTextType.page:
        left =
            "Page ${bookSavedData.getBookPageProgress(wordsPerPage)} / ${bookSavedData.getPages(wordsPerPage)}";

        right = "${(bookSavedData.readProgress * 100).floor()}%";
        break;
    }
    final TextStyle textStyle = Theme.of(context)
        .textTheme
        .bodySmall!
        .merge(const TextStyle(color: Color.fromARGB(255, 201, 201, 201)));

    return Row(
      children: [
        Text(
          left,
          style: textStyle,
        ),
        const Spacer(),
        Text(
          right,
          style: textStyle,
        ),
      ],
    );
  }
}
