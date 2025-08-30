import 'package:flutter/material.dart';

ValueNotifier<bool> isLightModeNotifier = ValueNotifier(true);
ValueNotifier<String> selectedPageNotifier = ValueNotifier("home");
ValueNotifier<int> selectedMenuBottomSheetNotifier = ValueNotifier(0);
ValueNotifier<String> userInputSearchBarNotifier = ValueNotifier("");
