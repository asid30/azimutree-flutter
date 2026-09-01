import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:azimutree/data/notifiers/survey_navigation_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final cluster = ClusterModel(id: 1, kodeCluster: 'A');
  final anchor = TitikIkatModel(
    id: 1,
    idCluster: 1,
    nama: 'Titik Ikat A',
    latitude: -5,
    longitude: 105,
  );
  final plot1 = PlotModel(
    id: 1,
    idCluster: 1,
    kodePlot: 1,
    latitude: -5.001,
    longitude: 105.001,
  );

  test(
    'survey confirmation moves reference from none to anchor then Plot 1',
    () {
      final notifier = SurveyNavigationNotifier();
      addTearDown(notifier.dispose);

      notifier.selectSurvey(
        cluster: cluster,
        anchorPoint: anchor,
        plot1: plot1,
        targetAzimuth: 73,
        targetDistanceM: 41.2,
      );
      expect(notifier.value.currentReference, SurveyReferenceType.none);
      expect(notifier.value.currentTarget, SurveyTargetType.anchorPoint);

      notifier.start();
      notifier.confirmAnchorPoint();
      expect(notifier.value.currentReference, SurveyReferenceType.anchorPoint);
      expect(notifier.value.currentTarget, SurveyTargetType.plot);

      notifier.confirmPlot1();
      expect(notifier.value.currentReference, SurveyReferenceType.plot);
      expect(notifier.value.currentTarget, SurveyTargetType.none);
      expect(notifier.value.currentPlot?.kodePlot, 1);
    },
  );

  test('Plot 1 cannot be confirmed before Titik Ikat', () {
    final notifier = SurveyNavigationNotifier();
    addTearDown(notifier.dispose);
    notifier.selectSurvey(
      cluster: cluster,
      anchorPoint: anchor,
      plot1: plot1,
      targetAzimuth: 73,
      targetDistanceM: 41.2,
    );

    notifier.confirmPlot1();
    expect(notifier.value.currentReference, SurveyReferenceType.none);
  });

  test('P1 can select and confirm a P2 navigation target', () {
    final notifier = SurveyNavigationNotifier();
    addTearDown(notifier.dispose);
    final plot2 = PlotModel(
      id: 2,
      idCluster: 1,
      kodePlot: 2,
      latitude: -4.999,
      longitude: 105,
    );
    notifier.selectSurvey(
      cluster: cluster,
      anchorPoint: anchor,
      plot1: plot1,
      targetAzimuth: 73,
      targetDistanceM: 41.2,
    );
    notifier.start();
    notifier.confirmAnchorPoint();
    notifier.confirmPlot1();

    notifier.selectPlotTarget(plot: plot2, azimuth: 30, distanceM: 39.4);
    expect(notifier.value.currentPlot?.kodePlot, 1);
    expect(notifier.value.targetPlot?.kodePlot, 2);
    expect(notifier.value.targetAzimuth, 30);
    expect(notifier.value.targetDistanceM, 39.4);

    notifier.confirmTargetPlot();
    expect(notifier.value.currentPlot?.kodePlot, 2);
    expect(notifier.value.currentTarget, SurveyTargetType.none);
  });

  test('active plot navigation can return to the confirmed Plot 1', () {
    final notifier = SurveyNavigationNotifier();
    addTearDown(notifier.dispose);
    final plot2 = PlotModel(
      id: 2,
      idCluster: 1,
      kodePlot: 2,
      latitude: -4.999,
      longitude: 105,
    );
    notifier.restore(
      cluster: cluster,
      anchorPoint: anchor,
      targetPlot: plot2,
      currentPlot: plot1,
      currentReference: SurveyReferenceType.plot,
      currentTarget: SurveyTargetType.plot,
      targetAzimuth: 30,
      targetDistanceM: 39.4,
      hasStarted: true,
    );

    notifier.cancelNavigation();
    expect(notifier.value.currentPlot?.kodePlot, 1);
    expect(notifier.value.targetPlot?.kodePlot, 1);
    expect(notifier.value.currentTarget, SurveyTargetType.none);
    expect(notifier.value.targetAzimuth, isNull);
  });
}
