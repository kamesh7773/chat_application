import 'package:flutter/material.dart';

class PopUpWidgets {
  // Displays a dialog box with the specified title and content
  static void diologbox({
    required BuildContext context,
    required String title,
    required String content,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: const BeveledRectangleBorder(),
          titlePadding: const EdgeInsets.only(top: 20, bottom: 18),
          contentPadding: const EdgeInsets.only(bottom: 26),
          actionsPadding: EdgeInsets.zero,
          title: SizedBox(
            width: 40,
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ),
          content: SizedBox(
            width: 320,
            child: Text(
              content,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
              ),
            ),
          ),
          actions: [
            const Divider(
              height: 0,
              thickness: 0.4,
            ),
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const ListTile(
                minVerticalPadding: 0,
                contentPadding: EdgeInsets.zero,
                isThreeLine: false,
                title: Center(
                  child: Text(
                    "OK",
                    style: TextStyle(
                      fontSize: 17,
                      color: Color.fromARGB(255, 2, 239, 159),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
