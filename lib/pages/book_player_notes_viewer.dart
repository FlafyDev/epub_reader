import 'package:flutter/material.dart';

import '../models/book_saved_data.dart';
import '../widgets/clean_app_bar.dart';

class BookPlayerNotesViewer extends StatelessWidget {
  const BookPlayerNotesViewer({
    Key? key,
    required this.notes,
    required this.onPressNote,
    this.onDeleteNote,
  }) : super(key: key);

  final List<SavedNote> notes;
  final void Function(SavedNote) onPressNote;
  final void Function(SavedNote)? onDeleteNote;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CleanAppBar(
        title: 'Notes',
      ),
      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return ListTile(
            title: Text(
              note.highlightedText,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              note.description,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            tileColor: noteColors[note.color.index].withOpacity(0.3),
            onTap: () => onPressNote(note),
            trailing: onDeleteNote == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      onDeleteNote!(note);
                    },
                  ),
          );
        },
      ),
    );
  }
}
