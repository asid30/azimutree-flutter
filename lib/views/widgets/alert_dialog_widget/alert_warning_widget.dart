import 'package:flutter/material.dart';

class AlertWarningWidget extends StatelessWidget {
  final String warningMessage;
  final Color? backgroundColor;
  const AlertWarningWidget({
    super.key,
    required this.warningMessage,
    this.backgroundColor = const Color.fromARGB(255, 248, 233, 93),
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: backgroundColor,
      title: Text("Warning!"),
      content: Text(warningMessage, style: TextStyle(color: Colors.black)),
      actions: [
        TextButton(child: Text("OK"), onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}
