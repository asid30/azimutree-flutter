import 'package:flutter/material.dart';

class AlertErrorWidget extends StatelessWidget {
  final Object errorMessage;
  const AlertErrorWidget({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color.fromARGB(255, 241, 111, 101),
      title: Text("Error!"),
      content: Text(
        "Error Message: $errorMessage",
        style: TextStyle(color: Colors.black),
      ),
      actions: [
        TextButton(child: Text("OK"), onPressed: () => Navigator.pop(context)),
      ],
    );
  }
}
