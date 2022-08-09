import 'package:epub_reader/widgets/book_player/note_color_buttons.dart';
import 'package:flutter/material.dart';
import '../models/book_saved_data.dart';

class BookPlayerNoteEditor extends StatefulWidget {
  const BookPlayerNoteEditor({
    Key? key,
    required this.note,
    required this.onDelete,
  }) : super(key: key);

  final SavedNote note;
  final void Function() onDelete;

  @override
  _BookPlayerNoteEditorState createState() => _BookPlayerNoteEditorState();
}

class _BookPlayerNoteEditorState extends State<BookPlayerNoteEditor> {
  late final TextEditingController textEditingController;
  late SavedNoteColor noteColor;

  @override
  void initState() {
    super.initState();
    noteColor = widget.note.color;
    textEditingController = TextEditingController(
      text: widget.note.description,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                color: noteColors[noteColor.index].withOpacity(0.7),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    widget.note.highlightedText,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Center(
                  child: IconButton(
                    splashRadius: 25,
                    onPressed: widget.onDelete,
                    icon: const Icon(Icons.delete_forever_outlined, size: 24),
                  ),
                ),
              ),
            )
          ],
        ),
        const SizedBox(
          height: 16,
        ),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 5.0),
            ),
          ),
          maxLines: 7,
          keyboardType: TextInputType.multiline,
          controller: textEditingController,
          onChanged: (value) {
            widget.note.description = value;
          },
        ),
        const SizedBox(
          height: 16,
        ),
        NoteColorButtons(
          selectedColor: noteColor,
          onColorPressed: (color) {
            setState(() {
              widget.note.color = color;
              noteColor = widget.note.color;
            });
          },
        )
      ],
    );
  }
}
