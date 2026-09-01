import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:azimutree/data/notifiers/survey_navigation_notifier.dart';
import 'package:azimutree/services/survey_session_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('survey session survives a new storage instance', () async {
    final notifier = SurveyNavigationNotifier();
    addTearDown(notifier.dispose);
    final cluster = ClusterModel(id: 10, kodeCluster: 'CLS-10');
    final anchor = TitikIkatModel(
      id: 20,
      idCluster: 10,
      nama: 'Titik Ikat CLS-10',
      latitude: -5,
      longitude: 105,
    );
    final plot1 = PlotModel(
      id: 30,
      idCluster: 10,
      kodePlot: 1,
      latitude: -5.001,
      longitude: 105,
    );
    notifier.selectSurvey(
      cluster: cluster,
      anchorPoint: anchor,
      plot1: plot1,
      targetAzimuth: 180,
      targetDistanceM: 50,
    );
    notifier.start();
    notifier.confirmAnchorPoint();
    notifier.confirmPlot1();

    await SurveySessionStorage().save(notifier.value);
    final restored = await SurveySessionStorage().load();

    expect(restored?.clusterId, 10);
    expect(restored?.currentPlotId, 30);
    expect(restored?.targetPlotId, 30);
    expect(restored?.currentReference, SurveyReferenceType.plot);
    expect(restored?.currentTarget, SurveyTargetType.none);
    expect(restored?.hasStarted, isTrue);
    expect(restored?.targetAzimuth, 180);
    expect(restored?.targetDistanceM, 50);
  });

  test('clearing storage removes the active session', () async {
    SharedPreferences.setMockInitialValues({'survey_session_cluster_id': 10});
    final storage = SurveySessionStorage();
    await storage.clear();
    expect(await storage.load(), isNull);
  });
}
