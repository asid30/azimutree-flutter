import 'package:flutter/material.dart';

class SmallMenuButtonWidget extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const SmallMenuButtonWidget({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Color(0xFF1F4226),
        minimumSize: Size(50, 50),
        maximumSize: Size(100, 100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: onPressed,
      child: Icon(icon),
    );
  }
}
