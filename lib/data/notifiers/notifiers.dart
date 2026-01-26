import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:azimutree/data/models/tree_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/cluster_model.dart';

/// Application-wide ValueNotifiers
///
/// This file exposes a collection of `ValueNotifier` objects used across
/// the UI to share small pieces of mutable state without a heavier
/// state-management solution. Each notifier is documented below with a
/// concise description of its intent.

/// Controls whether the app shows the light theme.
///
/// `true` -> light mode, `false` -> dark mode. Widgets listen to this
/// to adapt colors and theme-aware UI.
ValueNotifier<bool> isLightModeNotifier = ValueNotifier(true);

/// Currently-selected top-level page route/key ("home").
ValueNotifier<String> selectedPageNotifier = ValueNotifier("home");

/// Index of the selected item inside the menu bottom sheet.
ValueNotifier<int> selectedMenuBottomSheetNotifier = ValueNotifier(0);

/// Current raw text from the search input field (bottom sheet).
ValueNotifier<String> userInputSearchBarNotifier = ValueNotifier("");

/// Results from a location search. Each entry is a map with location data.
ValueNotifier<List<Map<String, dynamic>>> resultSearchLocationNotifier =
    ValueNotifier([]);

/// `true` while a location search is in progress (used to show loading UI).
ValueNotifier<bool> isSearchingNotifier = ValueNotifier(false);

/// The currently-selected geographic location (latitude/longitude).
ValueNotifier<Position?> selectedLocationNotifier = ValueNotifier(null);

/// Selected cluster identifier from a dropdown (nullable).
ValueNotifier<String?> selectedDropdownClusterNotifier = ValueNotifier(null);

/// Latest user location (live). Used for centering the map and other UI.
ValueNotifier<Position?> userLocationNotifier = ValueNotifier(null);

/// When `true`, the map camera will continuously follow the user's
/// live location. Typically toggled by a "follow" button.
ValueNotifier<bool> isFollowingUserLocationNotifier = ValueNotifier(false);

/// Increment this value to request the map camera reset its bearing to north.
///
/// UI code increments the integer to signal a one-shot command to map
/// listeners (they observe changes and perform the reset when detected).
ValueNotifier<int> northResetRequestNotifier = ValueNotifier(0);

/// `true` while the search input in the bottom sheet has focus.
ValueNotifier<bool> isSearchFieldFocusedNotifier = ValueNotifier(false);

/// The currently-selected `TreeModel` (set when a tree marker is tapped).
ValueNotifier<TreeModel?> selectedTreeNotifier = ValueNotifier(null);

/// The currently-selected `PlotModel` (set when a plot marker is tapped).
ValueNotifier<PlotModel?> selectedPlotNotifier = ValueNotifier(null);

/// When `true`, the next update to `selectedLocationNotifier` will preserve
/// the current map zoom level instead of resetting to a default zoom. Used
/// to avoid overriding the user's zoom when centering on a selected tree.
ValueNotifier<bool> preserveZoomOnNextCenterNotifier = ValueNotifier(false);

/// `true` if the active `selectedLocationNotifier` value originated from a
/// search result. The map can use this to display a distinct "search"
/// marker only for search-originated selections.
ValueNotifier<bool> selectedLocationFromSearchNotifier = ValueNotifier(false);

/// When `true`, short-tap activation of markers is enabled. Toggle to
/// temporarily disable marker activation (useful to avoid accidental
/// selections while panning the map).
ValueNotifier<bool> isMarkerActivationEnabledNotifier = ValueNotifier(true);

/// Controls the visibility of the on-map legend (top-left).
ValueNotifier<bool> isMapLegendVisibleNotifier = ValueNotifier(true);

/// Screen offset (logical pixels) where the user tapped a selected marker.
/// UI uses this value to position floating marker info close to the tap.
ValueNotifier<Offset?> selectedMarkerScreenOffsetNotifier = ValueNotifier(null);

// When a tree is selected, these hold resolved plot/cluster models to avoid
// performing database lookups inside UI widgets.
ValueNotifier<PlotModel?> selectedTreePlotNotifier = ValueNotifier(null);
ValueNotifier<ClusterModel?> selectedTreeClusterNotifier = ValueNotifier(null);
ValueNotifier<ClusterModel?> selectedPlotClusterNotifier = ValueNotifier(null);

/// When a generated centroid marker is selected, this holds the resolved
/// `ClusterModel` so the UI can present cluster info similarly to a plot
/// selection. Use `null` to clear the selection.
ValueNotifier<ClusterModel?> selectedCentroidNotifier = ValueNotifier(null);

/// Toggle that enables/disables the simple inspection workflow (drawer toggle).
ValueNotifier<bool> isInspectionWorkflowEnabledNotifier = ValueNotifier(false);

/// A set of tree IDs that the user has marked as inspected/completed.
ValueNotifier<Set<int>> inspectedTreeIdsNotifier = ValueNotifier({});

/// When `true`, selecting a marker (tree/plot) will show the floating
/// marker information card.
ValueNotifier<bool> isMarkerInfoOnSelectNotifier = ValueNotifier(true);

/// Controls visibility of the line connecting a tree marker to its plot center.
ValueNotifier<bool> isTreeToPlotLineVisibleNotifier = ValueNotifier(true);

/// Controls visibility of connecting lines between different plots.
ValueNotifier<bool> isPlotToPlotLineVisibleNotifier = ValueNotifier(true);

/// Increment to request the bottomsheet to minimize. Observers treat this
/// as a one-shot signal when the integer value changes.
ValueNotifier<int> bottomsheetMinimizeRequestNotifier = ValueNotifier(0);
