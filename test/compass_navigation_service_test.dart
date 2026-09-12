import 'package:azimutree/services/compass_navigation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeAngle', () {
    test('normalizes values into 0 to 360 range', () {
      expect(normalizeAngle(-10), 350);
      expect(normalizeAngle(0), 0);
      expect(normalizeAngle(360), 0);
      expect(normalizeAngle(370), 10);
      expect(normalizeAngle(720), 0);
    });
  });

  group('signedAngleDifference', () {
    test('returns the shortest signed rotation', () {
      expect(signedAngleDifference(75, 40), 35);
      expect(signedAngleDifference(75, 100), -25);
      expect(signedAngleDifference(5, 355), 10);
      expect(signedAngleDifference(355, 5), -10);
    });
  });

  test('alignment works across north', () {
    expect(isDirectionAligned(1, 359, tolerance: 5), isTrue);
  });

  test('back azimuth wraps around', () {
    expect(calculateBackAzimuth(200), 20);
  });

  test('circular smoothing handles north boundary', () {
    final smoother = CircularHeadingSmoother(windowSize: 2);
    smoother.add(359);
    final result = smoother.add(1);

    expect(signedAngleDifference(0, result).abs(), lessThan(0.001));
  });

  test('cardinal direction uses Indonesian abbreviations', () {
    expect(cardinalDirection(0), 'U');
    expect(cardinalDirection(90), 'T');
    expect(cardinalDirection(180), 'S');
    expect(cardinalDirection(270), 'B');
  });
}
