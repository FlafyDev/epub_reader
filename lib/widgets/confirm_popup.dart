import 'package:flutter/material.dart';

Future<bool?> confirmPopup(BuildContext context, String title, String message) {
  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: <Widget>[
      TextButton(
          child: const Text('No'),
          onPressed: () {
            Navigator.pop(context, false);
          }),
      TextButton(
        child: const Text('Yes'),
        onPressed: () {
          Navigator.pop(context, true);
        },
      ),
    ],
  );

  // show the dialog
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}
