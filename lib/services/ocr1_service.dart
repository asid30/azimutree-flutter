import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/material.dart';

class OcrResult {
  final String text;
  final List<TextElement> elements;
  final Size imageSize;

  OcrResult({
    required this.text,
    required this.elements,
    required this.imageSize,
  });
}

class OcrServiceGoogleMLKit {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  Future<OcrResult> processImage(File file) async {
    final inputImage = InputImage.fromFile(file);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final decodedImage = await decodeImageFromList(file.readAsBytesSync());

    List<TextElement> elements = [];
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        elements.addAll(line.elements);
      }
    }

    return OcrResult(
      text: recognizedText.text,
      elements: elements,
      imageSize: Size(
        decodedImage.width.toDouble(),
        decodedImage.height.toDouble(),
      ),
    );
  }

  void dispose() {
    _textRecognizer.close();
  }
}
