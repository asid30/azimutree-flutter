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
    DebugModeService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pushNamedAndRemoveUntil(context, 'home', (route) => false);
      },
      child: Scaffold(
        appBar: const AppbarWidget(title: "Pengaturan"),
        drawer: const SidebarWidget(),
        body: Stack(
          children: [
            // Background
            BackgroundAppWidget(
              lightBackgroundImage: "assets/images/light-bg-notitle.png",
              darkBackgroundImage: "assets/images/dark-bg-notitle.png",
            ),
            // Content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                child: ValueListenableBuilder<bool>(
                  valueListenable: isLightModeNotifier,
                  builder: (context, isLight, child) {
                    final isDark = !isLight;
                    return DefaultTextStyle(
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ValueListenableBuilder<bool>(
                                valueListenable: isLightModeNotifier,
                                builder: (context, isLight, child) {
                                  return BackButton(
                                    color: isLight ? null : Colors.white,
                                    onPressed: () {
                                      Navigator.popAndPushNamed(
                                        context,
                                        "home",
                                      );
                                    },
                                  );
                                },
                              ),
                              ValueListenableBuilder<bool>(
                                valueListenable: isLightModeNotifier,
                                builder: (context, isLight, child) {
                                  return Text(
                                    "Kembali",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: isLight ? null : Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Theme switch
                          ValueListenableBuilder<bool>(
                            valueListenable: isLightModeNotifier,
                            builder: (context, isLightMode, _) {
                              final isDark = !isLightMode;
                              return Card(
                                color:
                                    isDark
                                        ? const Color.fromARGB(255, 36, 67, 42)
                                        : const Color.fromARGB(
                                          240,
                                          180,
                                          216,
                                          187,
                                        ),
                                child: SwitchListTile(
                                  title: Text(
                                    'Tema',
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  activeTrackColor:
                                      isDark
                                          ? const Color(0xFFC1FF72)
                                          : const Color(0xFF1F4226),
                                  activeThumbColor:
                                      isDark ? const Color(0xFF1F4226) : null,
                                  subtitle: Text(
                                    isLightMode ? 'Tema Terang' : 'Tema Gelap',
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  value: isLightMode,
                                  onChanged: (value) {
                                    isLightModeNotifier.value = value;
                                  },
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          // Debug mode switch
                          ValueListenableBuilder<bool>(
                            valueListenable: isLightModeNotifier,
                            builder: (context, isLightMode, _) {
                              final isDark = !isLightMode;
                              return Card(
                                color:
                                    isDark
                                        ? const Color.fromARGB(255, 36, 67, 42)
                                        : const Color.fromARGB(
                                          240,
                                          180,
                                          216,
                                          187,
                                        ),
                                child: ValueListenableBuilder<bool>(
                                  valueListenable:
                                      DebugModeService.instance.enabled,
                                  builder: (context, enabled, _) {
                                    return SwitchListTile(
                                      title: Text(
                                        'Mode Debug',
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                      ),
                                      activeTrackColor:
                                          isDark
                                              ? const Color(0xFFC1FF72)
                                              : const Color(0xFF1F4226),
                                      activeThumbColor:
                                          isDark
                                              ? const Color(0xFF1F4226)
                                              : null,
                                      subtitle: Text(
                                        'Tampilkan fitur debug (generate/hapus data) di Kelola Data',
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? Colors.white
                                                  : Colors.black,
                                        ),
                                      ),
                                      value: enabled,
                                      onChanged: (value) async {
                                        await DebugModeService.instance
                                            .setEnabled(value);
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
