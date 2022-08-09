import 'package:flutter/material.dart';

import '../../models/book_saved_data.dart';

class NoteColorButtons extends StatelessWidget {
  final SavedNoteColor? selectedColor;
  final void Function(SavedNoteColor color) onColorPressed;

  const NoteColorButtons({
    Key? key,
    this.selectedColor,
    required this.onColorPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: noteColors.asMap().entries.map(
        (entry) {
          final index = entry.key;
          final color = entry.value;
          return InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              onColorPressed(SavedNoteColor.values[index]);
            },
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Container(
                width: 30,
                height: 30,
                decoration: selectedColor?.index == index
                    ? BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      )
                    : null,
                child: Center(
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ).toList(),
    );
  }
}
