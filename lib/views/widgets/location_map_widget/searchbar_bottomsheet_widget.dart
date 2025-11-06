import 'package:azimutree/data/global_variables/logger_global.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/services/search_location_service.dart';
import 'package:azimutree/services/debouncer_service.dart';
import 'package:flutter/material.dart';

class SearchbarBottomsheetWidget extends StatefulWidget {
  const SearchbarBottomsheetWidget({super.key});

  @override
  State<SearchbarBottomsheetWidget> createState() =>
      _SearchbarBottomsheetWidgetState();
}

class _SearchbarBottomsheetWidgetState
    extends State<SearchbarBottomsheetWidget> {
  late final TextEditingController _searchController;
  late final DebouncerService _debouncer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _debouncer = DebouncerService(delay: Duration(seconds: 1));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    userInputSearchBarNotifier.value = value;
    if (value.trim().isEmpty) {
      resultSearchLocationNotifier.value = [];
      isSearchingNotifier.value = false;
      return;
    }
    isSearchingNotifier.value = true;
    _debouncer.run(() async {
      try {
        await _search(value);
      } finally {
        isSearchingNotifier.value = false;
      }
    });
  }

  Future<void> _search(String searchQuery) async {
    try {
      final places = await searchLocationService(searchQuery);
      resultSearchLocationNotifier.value = places;
    } catch (e) {
      logger.e("Error during search: $e");
      throw Exception("Error during search: $e");
    }
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
          onChanged: _onSearchChanged,
        );
      },
    );
  }
}
