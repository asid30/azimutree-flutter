import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:azimutree/data/models/tree_model.dart';

ValueNotifier<bool> isLightModeNotifier = ValueNotifier(true);
ValueNotifier<String> selectedPageNotifier = ValueNotifier("home");
ValueNotifier<int> selectedMenuBottomSheetNotifier = ValueNotifier(0);
ValueNotifier<String> userInputSearchBarNotifier = ValueNotifier("");
ValueNotifier<List<Map<String, dynamic>>> resultSearchLocationNotifier =
    ValueNotifier([]);
ValueNotifier<bool> isSearchingNotifier = ValueNotifier(false);
ValueNotifier<Position?> selectedLocationNotifier = ValueNotifier(null);
ValueNotifier<String?> selectedDropdownClusterNotifier = ValueNotifier(null);

/// Latest user location (live). Used for centering and optional UI.
ValueNotifier<Position?> userLocationNotifier = ValueNotifier(null);

/// True when the map should keep following the user's live location.
ValueNotifier<bool> isFollowingUserLocationNotifier = ValueNotifier(false);

/// Increment this value to request the map camera to reset bearing to north.
ValueNotifier<int> northResetRequestNotifier = ValueNotifier(0);

/// True when the search input inside the bottom sheet has focus.
ValueNotifier<bool> isSearchFieldFocusedNotifier = ValueNotifier(false);

/// Holds the currently-selected tree (when a marker is tapped on the map).
ValueNotifier<TreeModel?> selectedTreeNotifier = ValueNotifier(null);

/// When true, the next `selectedLocationNotifier` update will preserve the
/// current map zoom instead of forcing a fixed zoom level. This is used when
/// centering on a tree so the user's zoom choice isn't overridden.
ValueNotifier<bool> preserveZoomOnNextCenterNotifier = ValueNotifier(false);
