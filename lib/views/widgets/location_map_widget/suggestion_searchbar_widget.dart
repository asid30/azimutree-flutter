import 'package:azimutree/views/widgets/location_map_widget/suggestion_body_widget.dart';
import 'package:azimutree/views/widgets/location_map_widget/suggestion_header_widget.dart';
import 'package:flutter/material.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';

class SuggestionSearchbarWidget extends StatefulWidget {
  const SuggestionSearchbarWidget({super.key});

  @override
  State<SuggestionSearchbarWidget> createState() =>
      _SuggestionSearchbarWidgetState();
}

class _SuggestionSearchbarWidgetState extends State<SuggestionSearchbarWidget> {
  late final VoidCallback _searchingListener;

  @override
  void initState() {
    super.initState();
    _searchingListener = () {
      if (!mounted) return;
      setState(() {});
    };
    isSearchingNotifier.addListener(_searchingListener);
  }

  @override
  void dispose() {
    isSearchingNotifier.removeListener(_searchingListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: userInputSearchBarNotifier,
      builder: (context, userInputSearchBar, child) {
        if (userInputSearchBar.isEmpty) {
          return const SizedBox();
        }
        final filteredSearch =
            resultSearchLocationNotifier.value
                .where(
                  (place) => place['name']!.toLowerCase().contains(
                    userInputSearchBar.toLowerCase(),
                  ),
                )
                .toList();

        return Container(
          color: Colors.white,
          width: double.infinity,
          height: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SuggestionHeaderWidget(query: userInputSearchBar),
              SuggestionBodyWidget(
                isSearching: isSearchingNotifier.value,
                results: filteredSearch,
              ),
              const SizedBox(height: 150),
            ],
          ),
        );
      },
    );
  }
}
