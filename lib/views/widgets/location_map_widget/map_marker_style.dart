import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

const int kClusterColor = 0xFF2E7D32;
const int kClusterStrokeColor = 0xFF1B5E20;
const double kClusterRadius = 11.0;
const double kClusterStrokeWidth = 1.5;
const double kClusterOpacity = 0.85;

const int kPlotColor = 0xFF1565C0;
const int kPlotStrokeColor = 0xFF0D47A1;
const double kPlotRadius = 9.0;
const double kPlotStrokeWidth = 1.2;
const double kPlotOpacity = 0.9;
const int kPlotSelectedStrokeColor = 0xFFFFFFFF;
const double kPlotSelectedStrokeWidth = 1.6;

const int kPlotAreaColor = 0xFF81D4FA;
const int kPlotAreaOutlineColor = 0xFF4FC3F7;
const double kPlotAreaOpacity = 0.18;
const double kPlotAreaMarginMeters = 5.0;
const double kEmptyPlotAreaRadiusMeters = 10.0;
const int kPlotAreaSegments = 64;

const int kTreeColor = 0xFFF57C00;
const int kTreeStrokeColor = 0xFFE65100;
const int kTreeSelectedStrokeColor = 0xFFFFFFFF;
const double kTreeRadius = 6.0;
const double kTreeSelectedStrokeWidth = 1.6;
const double kTreeStrokeWidth = 1.0;
const double kTreeOpacity = 0.95;
const double kTreeIconSize = 0.92;
const double kTreeSelectedIconSize = 1.08;
const int kTreeInspectedColor = 0xFF8BC34A;

const int kConnectionColor = 0xFFB71C1C;
const double kConnectionRadius = 2.0;
const int kConnectionSegments = 120;
const int kPlotConnectionColor = 0xFF81D4FA;
const int kCentroidColor = 0xFF6A1B9A;
const int kTitikIkatColor = 0xFFE53935;
const double kTitikIkatIconSize = 0.88;

class TreeMarkerIconFactory {
  TreeMarkerIconFactory._();

  static final Map<String, Uint8List> _cache = {};

  static Future<Uint8List> create(
    int colorValue, {
    bool selected = false,
  }) async {
    final cacheKey = '$colorValue-$selected';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final outline =
        Paint()
          ..color = selected ? Colors.white : const Color(0xFF3E2723)
          ..style = PaintingStyle.stroke
          ..strokeWidth = selected ? 4 : 2
          ..strokeJoin = StrokeJoin.round;
    final canopy =
        Paint()
          ..color = Color(colorValue)
          ..style = PaintingStyle.fill;
    final trunk =
        Paint()
          ..color = const Color(0xFF5D4037)
          ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 27, 8, 18),
        const Radius.circular(2),
      ),
      outline,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(22, 28, 4, 17),
        const Radius.circular(1.5),
      ),
      trunk,
    );
    final tiers = <Path>[
      Path()
        ..moveTo(24, 17)
        ..lineTo(6, 40)
        ..lineTo(42, 40)
        ..close(),
      Path()
        ..moveTo(24, 9)
        ..lineTo(10, 30)
        ..lineTo(38, 30)
        ..close(),
      Path()
        ..moveTo(24, 2)
        ..lineTo(14, 21)
        ..lineTo(34, 21)
        ..close(),
    ];
    for (final tier in tiers) {
      canvas.drawPath(tier, canopy);
      canvas.drawPath(tier, outline);
    }

    final image = await recorder.endRecording().toImage(48, 48);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) throw StateError('Gagal membuat ikon pohon');
    final result = bytes.buffer.asUint8List();
    _cache[cacheKey] = result;
    return result;
  }
}

class TitikIkatMarkerIconFactory {
  TitikIkatMarkerIconFactory._();

  static final Map<bool, Uint8List> _cache = {};

  static Future<Uint8List> create({bool selected = false}) async {
    final cached = _cache[selected];
    if (cached != null) return cached;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final fill =
        Paint()
          ..color = const Color(kTitikIkatColor)
          ..style = PaintingStyle.fill;
    final outline =
        Paint()
          ..color = selected ? Colors.white : Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
    final pin =
        Path()
          ..moveTo(24, 46)
          ..cubicTo(20, 38, 9, 27, 9, 17)
          ..cubicTo(9, 8, 15.7, 2, 24, 2)
          ..cubicTo(32.3, 2, 39, 8, 39, 17)
          ..cubicTo(39, 27, 28, 38, 24, 46)
          ..close();
    canvas.drawPath(pin, fill);
    canvas.drawPath(pin, outline);
    canvas.drawCircle(
      const Offset(24, 17),
      6,
      Paint()..color = selected ? Colors.white : Colors.black,
    );
    canvas.drawCircle(
      const Offset(24, 17),
      3,
      Paint()..color = const Color(kTitikIkatColor),
    );

    final image = await recorder.endRecording().toImage(48, 48);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) throw StateError('Gagal membuat ikon Titik Ikat');
    final result = bytes.buffer.asUint8List();
    _cache[selected] = result;
    return result;
  }
}
