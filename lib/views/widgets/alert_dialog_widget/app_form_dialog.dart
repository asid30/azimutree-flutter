import 'package:flutter/material.dart';

/// Shared shell for modal forms that need custom interactive content.
///
/// Feature widgets provide only their fields and actions; dialog structure and
/// future global styling remain centralized in the alert widget directory.
class AppFormDialog extends StatelessWidget {
  const AppFormDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.backgroundColor,
    this.insetPadding,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final Color? backgroundColor;
  final EdgeInsets? insetPadding;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: backgroundColor,
      insetPadding: insetPadding,
      title: title,
      content: content,
      actions: actions,
    );
  }
}
