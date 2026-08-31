import 'dart:math' as math;

const double compassAlignmentTolerance = 10.0;

double normalizeAngle(double angle) => ((angle % 360) + 360) % 360;

double signedAngleDifference(double target, double current) {
  return ((target - current + 540) % 360) - 180;
}

bool isDirectionAligned(
  double target,
  double current, {
  double tolerance = compassAlignmentTolerance,
}) {
  return signedAngleDifference(target, current).abs() <= tolerance;
}

double calculateBackAzimuth(double azimuth) => normalizeAngle(azimuth + 180);

double applyHeadingCorrection(double heading, {double correction = 0}) {
  return normalizeAngle(heading + correction);
}

String cardinalDirection(double heading) {
  const directions = ['U', 'TL', 'T', 'TG', 'S', 'BD', 'B', 'BL'];
  final index = ((normalizeAngle(heading) + 22.5) ~/ 45) % directions.length;
  return directions[index];
}

/// Moving circular average suitable for headings around the 0/360 boundary.
class CircularHeadingSmoother {
  CircularHeadingSmoother({this.windowSize = 8})
    : assert(windowSize > 0, 'windowSize must be greater than zero');

  final int windowSize;
  final List<double> _samples = [];

  double add(double heading) {
    _samples.add(normalizeAngle(heading));
    if (_samples.length > windowSize) {
      _samples.removeAt(0);
    }

    var sinSum = 0.0;
    var cosSum = 0.0;
    for (final sample in _samples) {
      final radians = sample * math.pi / 180;
      sinSum += math.sin(radians);
      cosSum += math.cos(radians);
    }

    final averageRadians = math.atan2(sinSum, cosSum);
    return normalizeAngle(averageRadians * 180 / math.pi);
  }

  void reset() => _samples.clear();
}
