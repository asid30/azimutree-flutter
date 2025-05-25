import 'dart:io';
import 'package:azimutree/data/notifiers.dart';
import 'package:azimutree/views/widgets/appbar_widget.dart';
import 'package:azimutree/views/widgets/sidebar_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TestOcrGoogleMlKitPage extends StatefulWidget {
  const TestOcrGoogleMlKitPage({super.key});

  @override
  State<TestOcrGoogleMlKitPage> createState() => _TestOcrGoogleMlKitPageState();
}

class _TestOcrGoogleMlKitPageState extends State<TestOcrGoogleMlKitPage> {
  File? _image;
  String extractedText = "Memproses...";
  List<TextElement> textElements = [];
  String imagePath = '';
  Size imageSize = Size.zero;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      await _processImageFromAsset(pickedFile);
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _cameraImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      await _processImageFromAsset(pickedFile);
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _processImageFromAsset(XFile imageData) async {
    final inputImage = InputImage.fromFilePath(imageData.path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final recognizedText = await textRecognizer.processImage(inputImage);
    final file = File(imageData.path);
    final decodedImage = await decodeImageFromList(file.readAsBytesSync());
    await textRecognizer.close();

    List<TextElement> elements = [];
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        elements.addAll(line.elements);
      }
    }

    setState(() {
      extractedText = recognizedText.text;
      textElements = elements;
      imagePath = imageData.path;
      imageSize = Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppbarWidget(title: "Test OCR Google ML Kit"),
      drawer: SidebarWidget(),
      body: Stack(
        children: [
          //* Background App
          ValueListenableBuilder(
            valueListenable: isLightModeNotifier,
            builder: (context, isLightMode, child) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 800),
                transitionBuilder: (Widget child, Animation<double> animation) {
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
                          File(imagePath),
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
                    : Container(
                      color: Colors.white,
                      height: 200,
                      alignment: Alignment.center,
                      child: const Text(
                        "Belum ada gambar dipilih",
                        style: TextStyle(color: Colors.black),
                      ),
                    ),

                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _pickImage();
                        });
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
                      onPressed: () {
                        setState(() {
                          _cameraImage();
                        });
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
                const SizedBox(height: 20),
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
