import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:flutter/material.dart';

class BackgroundAppWidget extends StatelessWidget {
  final String lightBackgroundImage;
  final String darkBackgroundImage;
  final int animatedSwitchDuration;

  const BackgroundAppWidget({
    super.key,
    this.lightBackgroundImage = "assets/images/light-bg-notitle.png",
    this.darkBackgroundImage = "assets/images/dark-bg-notitle.png",
    this.animatedSwitchDuration = 800,
  });

  @override
  Widget build(BuildContext context) {
    // Animated background image based on light/dark mode
    // Uses ValueListenableBuilder to listen to changes in the isLightModeNotifier
    // and update the background image accordingly
    return ValueListenableBuilder(
      valueListenable: isLightModeNotifier,
      builder: (context, isLightMode, child) {
        return AnimatedSwitcher(
          duration: Duration(milliseconds: animatedSwitchDuration),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Image(
            key: ValueKey<bool>(isLightMode),
            image: AssetImage(
              // Use the appropriate background image based on the light/dark mode
              isLightMode ? lightBackgroundImage : darkBackgroundImage,
            ),
            fit: BoxFit.cover, // Cover the entire screen
            height: double.infinity, // Ensure the image covers the full height
            width: double.infinity, // Ensure the image covers the full width
          ),
        );
      },
    );
  }
}
