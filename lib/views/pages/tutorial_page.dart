import 'package:azimutree/data/notifiers.dart';
import 'package:azimutree/views/widgets/appbar_widget.dart';
import 'package:azimutree/views/widgets/sidebar_widget.dart';
import 'package:flutter/material.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppbarWidget(title: "Panduan Aplikasi"),
      drawer: SidebarWidget(),
      body: Stack(
        children: [
          //* Background App
          ValueListenableBuilder(
            valueListenable: isLightModeNotifier,
            builder: (context, isLightMode, child) {
              return Image(
                image: AssetImage(
                  isLightMode
                      ? "assets/images/light-bg-notitle.png"
                      : "assets/images/dark-bg-notitle.png",
                ),
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
              );
            },
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Tutorial Page"),
                BackButton(
                  onPressed: () {
                    Navigator.popAndPushNamed(context, "home");
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
