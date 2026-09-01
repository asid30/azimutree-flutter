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
    this.currentReference = SurveyReferenceType.none,
    this.currentTarget = SurveyTargetType.none,
    this.targetAzimuth,
    this.targetDistanceM,
    this.hasStarted = false,
  });

  final ClusterModel? cluster;
  final TitikIkatModel? anchorPoint;
  final PlotModel? targetPlot;
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
    value = value.copyWith(
      currentReference: SurveyReferenceType.plot,
      currentTarget: SurveyTargetType.none,
    );
  }

  void reset() => value = const SurveyNavigationState();
}
