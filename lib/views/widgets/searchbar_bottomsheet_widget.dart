import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:flutter/material.dart';

class SearchbarBottomsheetWidget extends StatefulWidget {
  const SearchbarBottomsheetWidget({super.key});

  @override
  State<SearchbarBottomsheetWidget> createState() =>
      _SearchbarBottomsheetWidgetState();
}

class _SearchbarBottomsheetWidgetState
    extends State<SearchbarBottomsheetWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: userInputSearchBarNotifier,
      builder: (context, userInputSearchBar, child) {
        return TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                _searchController.clear();
                FocusScope.of(context).unfocus();
                userInputSearchBarNotifier.value = "";
              },
            ),
            hintText: 'Cari lokasi...',
            contentPadding: const EdgeInsets.symmetric(
              vertical: 9,
              horizontal: 16,
            ),
          ),
          onChanged: (value) {
            userInputSearchBarNotifier.value = value;
          },
        );
      },
    );
  }
}
