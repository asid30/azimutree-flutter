import 'package:flutter/material.dart';

/// Header row used to group location-search suggestions.
class SuggestionHeaderWidget extends StatelessWidget {
  final String query;
  const SuggestionHeaderWidget({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          title: const Text(
            "Hasil Pencarian:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("\"$query\""),
        ),
        const Divider(),
      ],
    );
  }
}
