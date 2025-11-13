import 'package:flutter/material.dart';

class AlertDevelopmentWidget extends StatelessWidget {
  final String title;
  final String warningMessage;
  const AlertDevelopmentWidget({
    super.key,
    this.title = "Sorry!",
    this.warningMessage = "This feature is not available yet 😔",
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text(title),
      content: Text(warningMessage, style: TextStyle(color: Colors.black)),
      actions: [
        TextButton(child: Text("OK"), onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}
