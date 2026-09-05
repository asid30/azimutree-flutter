import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:azimutree/services/azimuth_latlong_service.dart';
import 'package:flutter_test/flutter_test.dart';

TitikIkatModel validTitikIkat({double? latitude, double? longitude}) {
  return TitikIkatModel(
    idCluster: 1,
    nama: 'Patok Utama',
    latitude: latitude,
    longitude: longitude,
    keterangan: 'Dekat gerbang',
    urlFoto: 'https://example.com/patok.jpg',
  );
}

void main() {
  test('valid Titik Ikat converts to and from map', () {
    final model = validTitikIkat(latitude: -5.4, longitude: 105.2);
    model.validate();

    final restored = TitikIkatModel.fromMap(model.toMap());
    expect(restored.nama, 'Patok Utama');
    expect(restored.latitude, -5.4);
    expect(restored.keterangan, 'Dekat gerbang');
    expect(restored.urlFoto, 'https://example.com/patok.jpg');
  });

  test('coordinates are valid without obsolete direction attributes', () {
    final model = TitikIkatModel(
      idCluster: 1,
      nama: 'Titik Ikat CL1',
      latitude: -5.4,
      longitude: 105.2,
    );

    expect(model.validate, returnsNormally);
  });

  test('latitude and longitude must be provided together', () {
    expect(
      () => validTitikIkat(latitude: -5.4).validate(),
      throwsArgumentError,
    );
  });

  test('coordinates calculate forward azimuth from Titik Ikat to Plot 1', () {
    final result = AzimuthLatLongService.toAzimuthDistance(
      centerLatDeg: -5.401,
      centerLonDeg: 105.2,
      targetLatDeg: -5.4,
      targetLonDeg: 105.2,
    );

    expect(result.azimuthDeg, closeTo(0, 0.001));
    expect(result.distanceM, greaterThan(0));
  });

  test('generated coordinate preserves its source azimuth and distance', () {
    final coordinate = AzimuthLatLongService.fromAzimuthDistance(
      centerLatDeg: -5.4,
      centerLonDeg: 105.2,
      azimuthDeg: 237.5,
      distanceM: 14.8,
    );
    final restored = AzimuthLatLongService.toAzimuthDistance(
      centerLatDeg: -5.4,
      centerLonDeg: 105.2,
      targetLatDeg: coordinate.latitude,
      targetLonDeg: coordinate.longitude,
    );

    expect(restored.azimuthDeg, closeTo(237.5, 0.001));
    expect(restored.distanceM, closeTo(14.8, 0.001));
  });
}
