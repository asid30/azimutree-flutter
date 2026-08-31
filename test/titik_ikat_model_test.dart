import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:azimutree/services/azimuth_latlong_service.dart';
import 'package:flutter_test/flutter_test.dart';

TitikIkatModel validTitikIkat({
  double azimut = 73,
  double jarak = 41.2,
  double? latitude,
  double? longitude,
}) {
  return TitikIkatModel(
    idCluster: 1,
    nama: 'Patok Utama',
    latitude: latitude,
    longitude: longitude,
    azimutKePlot1: azimut,
    jarakKePlot1M: jarak,
  );
}

void main() {
  test('valid Titik Ikat converts to and from map', () {
    final model = validTitikIkat(latitude: -5.4, longitude: 105.2);
    model.validate();

    final restored = TitikIkatModel.fromMap(model.toMap());
    expect(restored.nama, 'Patok Utama');
    expect(restored.azimutKePlot1, 73);
    expect(restored.jarakKePlot1M, 41.2);
    expect(restored.latitude, -5.4);
  });

  test('azimuth must be in the range 0 to less than 360', () {
    expect(() => validTitikIkat(azimut: -1).validate(), throwsArgumentError);
    expect(() => validTitikIkat(azimut: 360).validate(), throwsArgumentError);
  });

  test('zero distance is valid but negative distance is rejected', () {
    expect(() => validTitikIkat(jarak: 0).validate(), returnsNormally);
    expect(() => validTitikIkat(jarak: -1).validate(), throwsArgumentError);
    expect(
      () => validTitikIkat(jarak: double.nan).validate(),
      throwsArgumentError,
    );
  });

  test('azimuth and distance may be empty for initial coordinates', () {
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
}
