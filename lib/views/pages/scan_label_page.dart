import 'dart:io';
import 'package:azimutree/data/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:azimutree/data/global_camera.dart';

class ScanLabelPage extends StatefulWidget {
  const ScanLabelPage({super.key});

  @override
  State<ScanLabelPage> createState() => _ScanLabelPageState();
}

class _ScanLabelPageState extends State<ScanLabelPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  File? _image;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      globalCameras.first, // atau pilih kamera belakang
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Column(
            children: [
              Stack(
                children: [
                  CameraPreview(_controller),
                  Positioned(
                    bottom: 30,
                    left: 250,
                    child: Row(
                      children: [
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: CircleBorder(),
                          ),
                          icon: Icon(Icons.camera, color: Colors.white),
                          onPressed: () async {
                            try {
                              await _initializeControllerFuture;
                              final _image = await _controller.takePicture();
                              // Lakukan sesuatu dengan gambar yang diambil
                            } catch (e) {
                              print(e);
                            }
                          },
                        ),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: const CircleBorder(),
                          ),
                          icon: const Icon(Icons.image, color: Colors.white),
                          onPressed: () async {
                            // Pilih gambar dari galeri
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ValueListenableBuilder(
                valueListenable: selectedPageNotifier,
                builder: (context, selectedPage, child) {
                  return ElevatedButton.icon(
                    onPressed: () {
                      selectedPageNotifier.value = "home";
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF1F4226),
                      minimumSize: const Size(50, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.skip_previous),
                    label: const Text("Back"),
                  );
                },
              ),
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
