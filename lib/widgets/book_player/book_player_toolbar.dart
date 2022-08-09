import 'package:epub_reader/widgets/book_player/note_color_buttons.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../models/book_saved_data.dart';

enum _ToolBarViews {
  normal,
  noteColors,
}

class BookPlayerToolbar extends StatefulWidget {
  const BookPlayerToolbar({
    Key? key,
    this.text,
    required this.onCopy,
    required this.onAddNote,
    required this.onSearch,
    required this.onCharacter,
    required this.onWebSearch,
  }) : super(key: key);

  final String? text;
  final void Function() onCopy;
  final void Function(SavedNoteColor) onAddNote;
  final void Function() onSearch;
  final void Function() onCharacter;
  final void Function() onWebSearch;

  @override
  _BookPlayerToolbarState createState() => _BookPlayerToolbarState();
}

class _BookPlayerToolbarState extends State<BookPlayerToolbar> {
  _ToolBarViews view = _ToolBarViews.normal;
  String? text;

  @override
  Widget build(BuildContext context) {
    if (text != widget.text) {
      text = widget.text;
      view = _ToolBarViews.normal;
    }

    const double buttonSize = 50;
    final buttons = [
      _ToolBarButton(
        icon: const Icon(Icons.copy),
        onPressed: widget.onCopy,
        size: buttonSize,
      ),
      _ToolBarButton(
        icon: const Icon(Icons.note_add_outlined),
        onPressed: () {
          setState(() {
            view = _ToolBarViews.noteColors;
          });
        },
        size: buttonSize,
      ),
      _ToolBarButton(
        icon: const Icon(Icons.search),
        onPressed: widget.onSearch,
        size: buttonSize,
      ),
      _ToolBarButton(
        icon: const Icon(Icons.account_circle_outlined),
        onPressed: widget.onCharacter,
        size: buttonSize,
      ),
      _ToolBarButton(
        icon: const Icon(FontAwesomeIcons.google, size: 20),
        onPressed: widget.onWebSearch,
        size: buttonSize,
      ),
    ];

    return Container(
      height: buttonSize,
      width: buttonSize * buttons.length,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: IntrinsicWidth(
        child: view == _ToolBarViews.normal
            ? Row(
                children: buttons,
              )
            : NoteColorButtons(onColorPressed: widget.onAddNote),
      ),
    );
  }
}

class _ToolBarButton extends StatelessWidget {
  const _ToolBarButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    required this.size,
  }) : super(key: key);

  final Icon icon;
  final void Function() onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: IconButton(
            icon: icon,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
