import 'package:azimutree/data/models/cluster_model.dart';
import 'package:azimutree/data/models/plot_model.dart';
import 'package:azimutree/data/models/titik_ikat_model.dart';
import 'package:flutter/foundation.dart';

enum SurveyReferenceType { none, anchorPoint, plot }

enum SurveyTargetType { none, anchorPoint, plot }

@immutable
class SurveyNavigationState {
  const SurveyNavigationState({
    this.cluster,
    this.anchorPoint,
    this.targetPlot,
    this.currentPlot,
    this.currentReference = SurveyReferenceType.none,
    this.currentTarget = SurveyTargetType.none,
    this.targetAzimuth,
    this.targetDistanceM,
    this.hasStarted = false,
  });

  final ClusterModel? cluster;
  final TitikIkatModel? anchorPoint;
  final PlotModel? targetPlot;
  final PlotModel? currentPlot;
  final SurveyReferenceType currentReference;
  final SurveyTargetType currentTarget;
  final double? targetAzimuth;
  final double? targetDistanceM;
  final bool hasStarted;

  SurveyNavigationState copyWith({
    SurveyReferenceType? currentReference,
    SurveyTargetType? currentTarget,
    bool? hasStarted,
  }) => SurveyNavigationState(
    cluster: cluster,
    anchorPoint: anchorPoint,
    targetPlot: targetPlot,
    currentPlot: currentPlot,
    currentReference: currentReference ?? this.currentReference,
    currentTarget: currentTarget ?? this.currentTarget,
    targetAzimuth: targetAzimuth,
    targetDistanceM: targetDistanceM,
    hasStarted: hasStarted ?? this.hasStarted,
  );
}

class SurveyNavigationNotifier extends ValueNotifier<SurveyNavigationState> {
  SurveyNavigationNotifier() : super(const SurveyNavigationState());

  void selectSurvey({
    required ClusterModel cluster,
    required TitikIkatModel? anchorPoint,
    required PlotModel? plot1,
    double? targetAzimuth,
    double? targetDistanceM,
  }) {
    value = SurveyNavigationState(
      cluster: cluster,
      anchorPoint: anchorPoint,
      targetPlot: plot1,
      currentTarget:
          anchorPoint == null
              ? SurveyTargetType.none
              : SurveyTargetType.anchorPoint,
      targetAzimuth: targetAzimuth,
      targetDistanceM: targetDistanceM,
    );
  }

  void start() => value = value.copyWith(hasStarted: true);

  void confirmAnchorPoint() {
    if (value.anchorPoint == null || value.targetPlot == null) return;
    value = value.copyWith(
      currentReference: SurveyReferenceType.anchorPoint,
      currentTarget: SurveyTargetType.plot,
      hasStarted: true,
    );
  }

  void confirmPlot1() {
    if (value.currentReference != SurveyReferenceType.anchorPoint) return;
    value = SurveyNavigationState(
      cluster: value.cluster,
      anchorPoint: value.anchorPoint,
      targetPlot: value.targetPlot,
      currentPlot: value.targetPlot,
      currentReference: SurveyReferenceType.plot,
      currentTarget: SurveyTargetType.none,
      targetAzimuth: value.targetAzimuth,
      targetDistanceM: value.targetDistanceM,
      hasStarted: true,
    );
  }

  void selectPlotTarget({
    required PlotModel plot,
    required double azimuth,
    required double distanceM,
  }) {
    if (value.currentPlot?.kodePlot != 1) return;
    value = SurveyNavigationState(
      cluster: value.cluster,
      anchorPoint: value.anchorPoint,
      targetPlot: plot,
      currentPlot: value.currentPlot,
      currentReference: SurveyReferenceType.plot,
      currentTarget: SurveyTargetType.plot,
      targetAzimuth: azimuth,
      targetDistanceM: distanceM,
      hasStarted: true,
    );
  }

  void confirmTargetPlot() {
    if (value.currentReference != SurveyReferenceType.plot ||
        value.currentTarget != SurveyTargetType.plot ||
        value.targetPlot == null) {
      return;
    }
    value = SurveyNavigationState(
      cluster: value.cluster,
      anchorPoint: value.anchorPoint,
      targetPlot: value.targetPlot,
      currentPlot: value.targetPlot,
      currentReference: SurveyReferenceType.plot,
      currentTarget: SurveyTargetType.none,
      targetAzimuth: value.targetAzimuth,
      targetDistanceM: value.targetDistanceM,
      hasStarted: true,
    );
  }

  void cancelNavigation() {
    if (value.currentTarget != SurveyTargetType.plot) return;
    final fallbackTarget = value.currentPlot ?? value.targetPlot;
    value = SurveyNavigationState(
      cluster: value.cluster,
      anchorPoint: value.anchorPoint,
      targetPlot: fallbackTarget,
      currentPlot: value.currentPlot,
      currentReference: value.currentReference,
      currentTarget: SurveyTargetType.none,
      hasStarted: true,
    );
  }

  void resumePlot1Navigation({
    required double azimuth,
    required double distanceM,
  }) {
    if (value.currentReference != SurveyReferenceType.anchorPoint ||
        value.targetPlot?.kodePlot != 1) {
      return;
    }
    value = SurveyNavigationState(
      cluster: value.cluster,
      anchorPoint: value.anchorPoint,
      targetPlot: value.targetPlot,
      currentReference: SurveyReferenceType.anchorPoint,
      currentTarget: SurveyTargetType.plot,
      targetAzimuth: azimuth,
      targetDistanceM: distanceM,
      hasStarted: true,
    );
  }

  void restore({
    required ClusterModel cluster,
    required TitikIkatModel anchorPoint,
    required PlotModel targetPlot,
    required PlotModel? currentPlot,
    required SurveyReferenceType currentReference,
    required SurveyTargetType currentTarget,
    required double? targetAzimuth,
    required double? targetDistanceM,
    required bool hasStarted,
  }) {
    value = SurveyNavigationState(
      cluster: cluster,
      anchorPoint: anchorPoint,
      targetPlot: targetPlot,
      currentPlot: currentPlot,
      currentReference: currentReference,
      currentTarget: currentTarget,
      targetAzimuth: targetAzimuth,
      targetDistanceM: targetDistanceM,
      hasStarted: hasStarted,
    );
  }

  void reset() => value = const SurveyNavigationState();
}
