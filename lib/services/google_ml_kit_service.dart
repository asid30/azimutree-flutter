// OCR feature removed. This file intentionally left minimal to avoid
// references to the removed `google_mlkit_text_recognition` package.

class OcrResult {
  final String text;
  OcrResult({required this.text});
}

class OcrServiceGoogleMLKit {
  Future<OcrResult> processImage(dynamic _) async {
    return OcrResult(text: 'OCR feature removed');
  }

  void dispose() {}
}
