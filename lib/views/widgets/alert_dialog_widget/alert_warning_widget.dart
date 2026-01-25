import 'package:flutter/material.dart';

class AlertWarningWidget extends StatelessWidget {
  final String title;
  final String warningMessage;
  final Color? backgroundColor;
  final Color? textColor;
  const AlertWarningWidget({
    super.key,
    this.title = "Warning!",
    required this.warningMessage,
    this.backgroundColor = const Color.fromARGB(255, 248, 233, 93),
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final contentColor = textColor ?? Colors.black;
    return AlertDialog(
      backgroundColor: backgroundColor,
      title: Text(title, style: TextStyle(color: contentColor)),
      content: Text(warningMessage, style: TextStyle(color: contentColor)),
      actions: [
        TextButton(
          child: Text("OK", style: TextStyle(color: contentColor)),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
