//* Scan label pages
import 'dart:io';
import 'package:azimutree/views/widgets/alert_dialog_widget/alert_error_widget.dart';
import 'package:azimutree/views/widgets/core_widget/appbar_widget.dart';
import 'package:azimutree/views/widgets/core_widget/background_app_widget.dart';
import 'package:azimutree/views/widgets/core_widget/sidebar_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:azimutree/data/global_variables/global_camera.dart';
import 'package:azimutree/services/google_ml_kit_service.dart';
import 'package:image_picker/image_picker.dart';

class ScanLabelPage extends StatefulWidget {
  const ScanLabelPage({super.key});

  @override
  State<ScanLabelPage> createState() => _ScanLabelPageState();
}

class _ScanLabelPageState extends State<ScanLabelPage> {
  late final OcrServiceGoogleMLKit _ocrServiceGoogleMLKit;
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  XFile? _image;
  String extractedText = "Memproses...";
  List<TextElement> textElements = [];
  String imagePath = '';
  Size imageSize = Size.zero;

  Future<void> _processImage(XFile imageData) async {
    final file = File(imageData.path);
    final result = await _ocrServiceGoogleMLKit.processImage(file);

    setState(() {
      _image = imageData;
      extractedText = result.text;
      textElements = result.elements;
      imageSize = result.imageSize;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await _processImage(pickedFile);
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      globalCameras.first, // atau pilih kamera belakang
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
    _ocrServiceGoogleMLKit = OcrServiceGoogleMLKit();
  }

  @override
  void dispose() {
    _ocrServiceGoogleMLKit.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) {
                return;
              }
              Navigator.pushNamedAndRemoveUntil(
                context,
                'home',
                (route) => false,
              );
            },
            child: Scaffold(
              appBar: AppbarWidget(title: "Home"),
              drawer: SidebarWidget(),
              body: Stack(
                children: [
                  //* Background App
                  BackgroundAppWidget(),
                  //* Main Content
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            BackButton(
                              onPressed: () {
                                Navigator.popAndPushNamed(context, "home");
                              },
                            ),
                            const Text(
                              "Kembali",
                              style: TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                        if (_image != null)
                          Stack(
                            children: [
                              Image.file(
                                File(_image!.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final displayedWidth = constraints.maxWidth;
                                  final aspectRatio =
                                      imageSize.width != 0
                                          ? imageSize.height / imageSize.width
                                          : 1;
                                  final displayedHeight =
                                      displayedWidth * aspectRatio;

                                  return SizedBox(
                                    width: displayedWidth,
                                    height: displayedHeight,
                                    child: CustomPaint(
                                      painter: TextBoundingBoxPainter(
                                        elements: textElements,
                                        originalImageSize: imageSize,
                                        displayedImageSize: Size(
                                          displayedWidth,
                                          displayedHeight,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        else
                          Stack(children: [CameraPreview(_controller)]),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  _pickImage();
                                } catch (e) {
                                  if (kDebugMode) {
                                    debugPrint("Error Message: $e");
                                  }
                                  if (context.mounted) {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) =>
                                              AlertErrorWidget(errorMessage: e),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1F4226),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.upload, color: Colors.white),
                                  Text(
                                    " Upload",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                try {
                                  await _initializeControllerFuture;
                                  final image = await _controller.takePicture();
                                  await _processImage(image);
                                  setState(() {
                                    _image = image;
                                  });
                                  // Lakukan sesuatu dengan gambar yang diambil
                                } catch (e) {
                                  if (kDebugMode) {
                                    debugPrint("Error Message: $e");
                                  }
                                  if (context.mounted) {
                                    showDialog(
                                      context: context,
                                      builder:
                                          (context) =>
                                              AlertErrorWidget(errorMessage: e),
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1F4226),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.camera_alt, color: Colors.white),
                                  Text(
                                    " Camera",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        const Text(
                          "Hasil OCR:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.all(16.0),
                          child: Text(extractedText),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class TextBoundingBoxPainter extends CustomPainter {
  final List<TextElement> elements;
  final Size originalImageSize;
  final Size displayedImageSize;

  TextBoundingBoxPainter({
    required this.elements,
    required this.originalImageSize,
    required this.displayedImageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.redAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    double scaleX = displayedImageSize.width / originalImageSize.width;
    double scaleY = displayedImageSize.height / originalImageSize.height;

    for (final element in elements) {
      final rect = element.boundingBox;
      final scaledRect = Rect.fromLTRB(
        rect.left * scaleX,
        rect.top * scaleY,
        rect.right * scaleX,
        rect.bottom * scaleY,
      );
      canvas.drawRect(scaledRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
