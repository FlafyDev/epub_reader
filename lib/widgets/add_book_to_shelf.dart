import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../managers/settings_manager.dart';
import '../models/book.dart';

class AddBookToShelf extends StatefulWidget {
  const AddBookToShelf({
    Key? key,
    required this.shelves,
    required this.book,
    required this.onChange,
  }) : super(key: key);

  final List<Shelf> shelves;
  final Book book;
  final void Function(Shelf shelf, bool selected) onChange;

  @override
  _AddBookToShelfState createState() => _AddBookToShelfState();
}

class _AddBookToShelfState extends State<AddBookToShelf> {
  List<bool> selectedShelves = [];

  @override
  void initState() {
    selectedShelves = widget.shelves
        .map((shelf) =>
            shelf.books.firstWhereOrNull(
              (book) => book.savedData!.bookId == widget.book.savedData!.bookId,
            ) !=
            null)
        .toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add book to shelves"),
      content: SizedBox(
        width: 500,
        height: 500,
        child: ListView.builder(
          itemCount: widget.shelves.length,
          itemBuilder: (BuildContext context, int index) {
            final shelf = widget.shelves[index];
            return CheckboxListTile(
              title: Text(shelf.name),
              value: selectedShelves[index],
              onChanged: (inShelf) {
                widget.onChange(shelf, inShelf!);
                setState(() {
                  selectedShelves[index] = inShelf;
                });
              },
            );
          },
        ),
      ),
    );
  }
}
