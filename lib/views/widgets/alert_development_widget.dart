import 'package:flutter/material.dart';

class AlertDevelopmentWidget extends StatelessWidget {
  const AlertDevelopmentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.red,
      title: Text("Warning!"),
      content: Text(
        "This feature is not available yet 😔",
        style: TextStyle(color: Colors.black),
      ),
      actions: [
        TextButton(child: Text("OK"), onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}
