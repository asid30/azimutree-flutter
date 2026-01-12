import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
      },
      child: Scaffold(
        appBar: const AppbarWidget(title: "Tentang Aplikasi"),
        drawer: const SidebarWidget(),
        body: Stack(
          children: [
            //* Background App
            BackgroundAppWidget(
              lightBackgroundImage: "assets/images/light-bg-plain.png",
              darkBackgroundImage: "assets/images/dark-bg-plain.png",
            ),
            //* Content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        BackButton(
                          onPressed: () {
                            Navigator.popAndPushNamed(context, "home");
                          },
                        ),
                        const Text("Kembali", style: TextStyle(fontSize: 18)),
                      ],
                    ),
                    //? TODO: Add about app content
                    Text(
                      'Tentang Aplikasi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
