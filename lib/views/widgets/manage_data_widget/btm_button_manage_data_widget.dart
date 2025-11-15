import 'package:flutter/material.dart';

class BtmButtonManageDataWidget extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Size minSize;
  final Size maxSize;

  const BtmButtonManageDataWidget({
    super.key,
    required this.label,
    this.icon,
    this.minSize = const Size(150, 75),
    this.maxSize = const Size(200, 125),
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Color.fromARGB(255, 85, 146, 98),
        minimumSize: minSize,
        maximumSize: maxSize,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 30),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
