import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class TestOcrGoogleMlKitPage extends StatefulWidget {
  const TestOcrGoogleMlKitPage({super.key});

  @override
  State<TestOcrGoogleMlKitPage> createState() => _TestOcrGoogleMlKitPageState();
}

class _TestOcrGoogleMlKitPageState extends State<TestOcrGoogleMlKitPage> {
  String extractedText = "Memproses...";
  List<TextElement> textElements = [];
  String imagePath = '';

  @override
  void initState() {
    super.initState();
    _processImageFromAsset();
  }

  Future<void> _processImageFromAsset() async {
    final ByteData imageData = await rootBundle.load(
      'assets/images/sample.png',
    );
    final Directory tempDir = await getTemporaryDirectory();
    final String tempPath = join(tempDir.path, 'sample.jpg');

    File imageFile = await File(
      tempPath,
    ).writeAsBytes(imageData.buffer.asUint8List());

    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final recognizedText = await textRecognizer.processImage(inputImage);
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
      imagePath = imageFile.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (imagePath.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return FutureBuilder<Size>(
      future: _getImageSize(File(imagePath)),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final originalSize = snapshot.data!;
        final screenWidth = MediaQuery.of(context).size.width;
        final scale = screenWidth / originalSize.width;
        final displayHeight = originalSize.height * scale;

        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                width: screenWidth,
                height: displayHeight,
                child: Stack(
                  children: [
                    Image.file(
                      File(imagePath),
                      width: screenWidth,
                      fit: BoxFit.fitWidth,
                    ),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: TextBoundingBoxPainter(textElements, scale),
                      ),
                    ),
                  ],
                ),
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
            ],
          ),
        );
      },
    );
  }

  Future<Size> _getImageSize(File imageFile) async {
    final decodedImage = await decodeImageFromList(imageFile.readAsBytesSync());
    return Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
  }
}

class TextBoundingBoxPainter extends CustomPainter {
  final List<TextElement> elements;
  final double scale;

  TextBoundingBoxPainter(this.elements, this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.greenAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    for (final element in elements) {
      final rect = element.boundingBox;
      final scaledRect = Rect.fromLTRB(
        rect.left * scale,
        rect.top * scale,
        rect.right * scale,
        rect.bottom * scale,
      );
      canvas.drawRect(scaledRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
