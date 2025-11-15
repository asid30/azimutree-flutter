import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

ValueNotifier<bool> isLightModeNotifier = ValueNotifier(true);
ValueNotifier<String> selectedPageNotifier = ValueNotifier("home");
ValueNotifier<int> selectedMenuBottomSheetNotifier = ValueNotifier(0);
ValueNotifier<String> userInputSearchBarNotifier = ValueNotifier("");
ValueNotifier<List<Map<String, dynamic>>> resultSearchLocationNotifier =
    ValueNotifier([]);
ValueNotifier<bool> isSearchingNotifier = ValueNotifier(false);
ValueNotifier<Position?> selectedLocationNotifier = ValueNotifier(null);
ValueNotifier<String?> selectedDropdownClusterNotifier = ValueNotifier(null);
