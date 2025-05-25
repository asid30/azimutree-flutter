import 'package:azimutree/data/notifiers.dart';
import 'package:flutter/material.dart';

class AppbarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const AppbarWidget({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: FittedBox(fit: BoxFit.scaleDown, child: Text(title)),
      actions: [
        Text(isLightModeNotifier.value ? "Light Theme" : "Dark Theme"),
        ValueListenableBuilder(
          valueListenable: isLightModeNotifier,
          builder: (context, isLightMode, child) {
            return IconButton(
              onPressed: () {
                isLightModeNotifier.value = !isLightMode;
              },
              icon: Icon(isLightMode ? Icons.light_mode : Icons.dark_mode),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
