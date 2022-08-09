import 'package:flutter/material.dart';

Future<String?> inputPopup(BuildContext context, String title, String hint) {
  String value = "";

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: TextField(
      onChanged: (newValue) {
        value = newValue;
      },
      decoration: const InputDecoration(hintText: "Text Field in Dialog"),
    ),
    actions: <Widget>[
      TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.pop(context);
          }),
      TextButton(
        child: const Text('OK'),
        onPressed: () {
          Navigator.pop(context, value);
        },
      ),
    ],
  );

  // show the dialog
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
