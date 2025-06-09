import 'dart:convert';
import 'dart:io';
import 'package:azimutree/data/notifiers/notifiers.dart';
import 'package:azimutree/views/widgets/appbar_widget.dart';
import 'package:azimutree/views/widgets/sidebar_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:azimutree/data/global_variables/api_key.dart';

class TestOcrGoogleVisionApiPage extends StatefulWidget {
  const TestOcrGoogleVisionApiPage({super.key});

  @override
  State<TestOcrGoogleVisionApiPage> createState() =>
      _TestOcrGoogleVisionApiPageState();
}

class _TestOcrGoogleVisionApiPageState
    extends State<TestOcrGoogleVisionApiPage> {
  File? _image;
  String extractedText = 'Memproses...';
  List<Map<String, dynamic>> boundingBoxes = [];
  Size imageSize = Size.zero;

  final String apiKey = mySecretApiKey;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final decodedImage = await decodeImageFromList(file.readAsBytesSync());
      setState(() {
        _image = file;
        imageSize = Size(
          decodedImage.width.toDouble(),
          decodedImage.height.toDouble(),
        );
      });

      await _processImageWithGoogleVision(file);
    }
  }

  Future<void> _processImageWithGoogleVision(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final url = Uri.parse(
      'https://vision.googleapis.com/v1/images:annotate?key=$apiKey',
    );

    final requestPayload = {
      'requests': [
        {
          'image': {'content': base64Image},
          'features': [
            {'type': 'TEXT_DETECTION'},
          ],
        },
      ],
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestPayload),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      final annotations = result['responses'][0]['textAnnotations'];

      if (annotations != null && annotations.isNotEmpty) {
        final text = annotations[0]['description'];
        final boxes =
            annotations.sublist(1).map<Map<String, dynamic>>((annotation) {
              final vertices = annotation['boundingPoly']['vertices'];
              return {'text': annotation['description'], 'vertices': vertices};
            }).toList();

        setState(() {
          extractedText = text;
          boundingBoxes = boxes;
        });
      } else {
        setState(() {
          extractedText = 'Tidak ada teks terdeteksi.';
          boundingBoxes = [];
        });
      }
    } else {
      setState(() {
        extractedText = 'Gagal mengambil hasil dari Google Vision API.';
      });
    }
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
        appBar: AppbarWidget(title: "Test OCR Google Vision API"),
        drawer: SidebarWidget(),
        body: Stack(
          children: [
            //* Background App
            ValueListenableBuilder(
              valueListenable: isLightModeNotifier,
              builder: (context, isLightMode, child) {
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 800),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Image(
                    key: ValueKey<bool>(isLightMode),
                    image: AssetImage(
                      isLightMode
                          ? "assets/images/light-bg-notitle.png"
                          : "assets/images/dark-bg-notitle.png",
                    ),
                    fit: BoxFit.cover,
                    height: double.infinity,
                    width: double.infinity,
                  ),
                );
              },
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  (_image != null)
                      ? Stack(
                        children: [
                          Image.file(
                            _image!,
                            width: MediaQuery.of(context).size.width,
                            fit: BoxFit.fitWidth,
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
                                  painter: VisionBoundingBoxPainter(
                                    boundingBoxes: boundingBoxes,
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
                      : Container(
                        color: Colors.white,
                        height: 200,
                        alignment: Alignment.center,
                        child: const Text(
                          "Belum ada gambar dipilih",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.upload, color: Colors.white),
                        label: const Text(
                          "Upload",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F4226),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        label: const Text(
                          "Camera",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1F4226),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Hasil OCR (Google Vision):",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16.0),
                    child: Text(extractedText),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VisionBoundingBoxPainter extends CustomPainter {
  final List<Map<String, dynamic>> boundingBoxes;
  final Size originalImageSize;
  final Size displayedImageSize;

  VisionBoundingBoxPainter({
    required this.boundingBoxes,
    required this.originalImageSize,
    required this.displayedImageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.blueAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    double scaleX = displayedImageSize.width / originalImageSize.width;
    double scaleY = displayedImageSize.height / originalImageSize.height;

    for (final box in boundingBoxes) {
      final vertices = box['vertices'] as List<dynamic>;
      if (vertices.length >= 4) {
        final p1 = Offset(
          (vertices[0]['x'] ?? 0) * scaleX,
          (vertices[0]['y'] ?? 0) * scaleY,
        );
        final p2 = Offset(
          (vertices[1]['x'] ?? 0) * scaleX,
          (vertices[1]['y'] ?? 0) * scaleY,
        );
        final p3 = Offset(
          (vertices[2]['x'] ?? 0) * scaleX,
          (vertices[2]['y'] ?? 0) * scaleY,
        );
        final p4 = Offset(
          (vertices[3]['x'] ?? 0) * scaleX,
          (vertices[3]['y'] ?? 0) * scaleY,
        );

        final path =
            Path()
              ..moveTo(p1.dx, p1.dy)
              ..lineTo(p2.dx, p2.dy)
              ..lineTo(p3.dx, p3.dy)
              ..lineTo(p4.dx, p4.dy)
              ..close();

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
