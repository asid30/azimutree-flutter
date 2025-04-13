import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class TestOcrGoogleVisionApiPage extends StatefulWidget {
  const TestOcrGoogleVisionApiPage({super.key});

  @override
  State<TestOcrGoogleVisionApiPage> createState() =>
      _TestOcrGoogleVisionApiPageState();
}

class _TestOcrGoogleVisionApiPageState
    extends State<TestOcrGoogleVisionApiPage> {
  String extractedText = "Memproses...";
  File? imageFile;
  List<Rect> boundingBoxes = [];
  Size? originalImageSize;

  @override
  void initState() {
    super.initState();
    _processImageFromAsset();
  }

  Future<void> _processImageFromAsset() async {
    try {
      final ByteData imageData = await rootBundle.load(
        'assets/images/sample.png',
      );
      final Directory tempDir = await getTemporaryDirectory();
      final String tempPath = join(tempDir.path, 'sample.png');

      imageFile = await File(
        tempPath,
      ).writeAsBytes(imageData.buffer.asUint8List());

      // Decode size asli gambar
      final decodedImage = await decodeImageFromList(
        imageFile!.readAsBytesSync(),
      );
      final Size imageSize = Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      );

      final result = await recognizeTextWithGoogleVision(imageFile!);

      setState(() {
        extractedText = result['text'];
        boundingBoxes = result['boxes'];
        originalImageSize = imageSize;
      });
    } catch (e) {
      setState(() {
        extractedText = "Terjadi kesalahan: $e";
      });
    }
  }

  Future<Map<String, dynamic>> recognizeTextWithGoogleVision(
    File imageFile,
  ) async {
    const String apiKey =
        'AIzaSyCjuokYxx6LJCB07Xr1knS2w_743PAU3C8'; // Ganti dengan API Key kamu

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final url = 'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';

    final body = jsonEncode({
      "requests": [
        {
          "image": {"content": base64Image},
          "features": [
            {"type": "TEXT_DETECTION"},
          ],
        },
      ],
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final fullText =
          data['responses'][0]['fullTextAnnotation']?['text'] ??
          'Tidak ada teks terdeteksi.';
      final List<dynamic> blocks =
          data['responses'][0]['fullTextAnnotation']?['pages']?[0]['blocks'] ??
          [];

      final boxes = <Rect>[];

      for (var block in blocks) {
        for (var paragraph in block['paragraphs']) {
          for (var word in paragraph['words']) {
            final vertices = word['boundingBox']['vertices'];
            final left = vertices[0]['x']?.toDouble() ?? 0.0;
            final top = vertices[0]['y']?.toDouble() ?? 0.0;
            final right = vertices[2]['x']?.toDouble() ?? 0.0;
            final bottom = vertices[2]['y']?.toDouble() ?? 0.0;
            boxes.add(Rect.fromLTRB(left, top, right, bottom));
          }
        }
      }

      return {"text": fullText, "boxes": boxes};
    } else {
      throw Exception('Gagal mengenali teks: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return imageFile == null || originalImageSize == null
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(
          builder: (context, constraints) {
            final renderWidth = constraints.maxWidth;
            final scale = renderWidth / originalImageSize!.width;

            final scaledBoxes =
                boundingBoxes
                    .map(
                      (box) => Rect.fromLTRB(
                        box.left * scale,
                        box.top * scale,
                        box.right * scale,
                        box.bottom * scale,
                      ),
                    )
                    .toList();

            return Column(
              children: [
                Stack(
                  children: [
                    Image.file(imageFile!, width: renderWidth),
                    Positioned.fill(
                      child: CustomPaint(
                        painter: BoundingBoxPainter(scaledBoxes),
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
              ],
            );
          },
        );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<Rect> boxes;

  BoundingBoxPainter(this.boxes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.red
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;

    for (final box in boxes) {
      canvas.drawRect(box, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
