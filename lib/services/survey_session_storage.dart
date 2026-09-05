import 'package:azimutree/data/notifiers/survey_navigation_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SurveySessionSnapshot {
  const SurveySessionSnapshot({
    required this.clusterId,
    required this.hasStarted,
    required this.currentReference,
    required this.currentTarget,
    this.currentPlotId,
    this.targetPlotId,
    this.targetAzimuth,
    this.targetDistanceM,
  });

  final int clusterId;
  final bool hasStarted;
  final SurveyReferenceType currentReference;
  final SurveyTargetType currentTarget;
  final int? currentPlotId;
  final int? targetPlotId;
  final double? targetAzimuth;
  final double? targetDistanceM;
}

class SurveySessionStorage {
  static const _prefix = 'survey_session_';
  static const _clusterIdKey = '${_prefix}cluster_id';
  static const _startedKey = '${_prefix}started';
  static const _referenceKey = '${_prefix}reference';
  static const _targetKey = '${_prefix}target';
  static const _currentPlotIdKey = '${_prefix}current_plot_id';
  static const _targetPlotIdKey = '${_prefix}target_plot_id';
  static const _azimuthKey = '${_prefix}azimuth';
  static const _distanceKey = '${_prefix}distance';

  Future<void> save(SurveyNavigationState state) async {
    final preferences = await SharedPreferences.getInstance();
    final clusterId = state.cluster?.id;
    if (clusterId == null) {
      await clear();
      return;
    }
    await preferences.setInt(_clusterIdKey, clusterId);
    await preferences.setBool(_startedKey, state.hasStarted);
    await preferences.setString(_referenceKey, state.currentReference.name);
    await preferences.setString(_targetKey, state.currentTarget.name);
    await _setNullableInt(
      preferences,
      _currentPlotIdKey,
      state.currentPlot?.id,
    );
    await _setNullableInt(preferences, _targetPlotIdKey, state.targetPlot?.id);
    await _setNullableDouble(preferences, _azimuthKey, state.targetAzimuth);
    await _setNullableDouble(preferences, _distanceKey, state.targetDistanceM);
  }

  Future<SurveySessionSnapshot?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final clusterId = preferences.getInt(_clusterIdKey);
    if (clusterId == null) return null;
    final reference = _enumByName(
      SurveyReferenceType.values,
      preferences.getString(_referenceKey),
    );
    final target = _enumByName(
      SurveyTargetType.values,
      preferences.getString(_targetKey),
    );
    if (reference == null || target == null) {
      await clear();
      return null;
    }
    return SurveySessionSnapshot(
      clusterId: clusterId,
      hasStarted: preferences.getBool(_startedKey) ?? false,
      currentReference: reference,
      currentTarget: target,
      currentPlotId: preferences.getInt(_currentPlotIdKey),
      targetPlotId: preferences.getInt(_targetPlotIdKey),
      targetAzimuth: preferences.getDouble(_azimuthKey),
      targetDistanceM: preferences.getDouble(_distanceKey),
    );
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    for (final key in <String>[
      _clusterIdKey,
      _startedKey,
      _referenceKey,
      _targetKey,
      _currentPlotIdKey,
      _targetPlotIdKey,
      _azimuthKey,
      _distanceKey,
    ]) {
      await preferences.remove(key);
    }
  }

  T? _enumByName<T extends Enum>(List<T> values, String? name) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }

  Future<void> _setNullableInt(
    SharedPreferences preferences,
    String key,
    int? value,
  ) => value == null ? preferences.remove(key) : preferences.setInt(key, value);

  Future<void> _setNullableDouble(
    SharedPreferences preferences,
    String key,
    double? value,
  ) =>
      value == null
          ? preferences.remove(key)
          : preferences.setDouble(key, value);
}
