//* tutorial page
import 'package:azimutree/views/widgets/appbar_widget.dart';
import 'package:azimutree/views/widgets/background_app_widget.dart';
import 'package:azimutree/views/widgets/sidebar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lorem/flutter_lorem.dart';

class TutorialPage extends StatelessWidget {
  const TutorialPage({super.key});

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
        appBar: const AppbarWidget(title: "Panduan Aplikasi"),
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
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang di Aplikasi Azimutree!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Panduan ini akan membantu Anda memahami cara menggunakan aplikasi Azimutree untuk mengelola data klaster, plot, dan pohon.',
                      style: TextStyle(fontSize: 16),
                    ),
                    Divider(height: 30, thickness: 1),
                    Text(
                      lorem(paragraphs: 3, words: 750),
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.justify,
                    ),
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
