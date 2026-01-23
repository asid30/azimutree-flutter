import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:azimutree/services/debug_mode_service.dart';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // Ensure preference is loaded (main() already calls init, but keep this safe).
    DebugModeService.instance.init();
  }

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
        appBar: const AppbarWidget(title: "Pengaturan"),
        drawer: const SidebarWidget(),
        body: Stack(
          children: [
            //* Background App
            BackgroundAppWidget(
              lightBackgroundImage: "assets/images/light-bg-notitle.png",
              darkBackgroundImage: "assets/images/dark-bg-notitle.png",
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
                    Card(
                      color: Color.fromARGB(240, 180, 216, 187),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: isLightModeNotifier,
                        builder: (context, isLightMode, _) {
                          return SwitchListTile(
                            title: const Text('Tema'),
                            activeTrackColor: Color(0xFF1F4226),
                            subtitle: Text(
                              isLightMode ? 'Tema Terang' : 'Tema Gelap',
                            ),
                            value: isLightMode,
                            onChanged: (value) {
                              isLightModeNotifier.value = value;
                            },
                          );
                        },
                      ),
                    ),

                    Card(
                      color: Color.fromARGB(240, 180, 216, 187),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: DebugModeService.instance.enabled,
                        builder: (context, enabled, _) {
                          return SwitchListTile(
                            title: const Text('Mode Debug'),
                            activeTrackColor: Color(0xFF1F4226),
                            subtitle: const Text(
                              'Tampilkan fitur debug (generate/hapus data) di Kelola Data',
                            ),
                            value: enabled,
                            onChanged: (value) async {
                              await DebugModeService.instance.setEnabled(value);
                            },
                          );
                        },
                      ),
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
