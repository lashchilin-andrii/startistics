import 'package:flutter/material.dart';
import 'package:startistics/model/metric.dart';
import 'package:startistics/model/taunt.dart';
import 'package:startistics/model/unit.dart';
import 'package:startistics/repository/unit.dart';
import '../service/json_asset_data_source.dart';
import '../repository/user.dart';
import '../repository/taunt.dart';
import '../repository/metric.dart';
import '../model/user.dart';
import '../model/user_metric.dart';

enum ViewState { loading, success, error }

class ProfileViewModel extends ChangeNotifier {
  static final _dataSource = JsonAssetDataSource();
  final UserRepository _userRepository = UserRepository(_dataSource);
  final TauntRepository _tauntRepository = TauntRepository(_dataSource);
  final MetricRepository _metricRepository = MetricRepository(_dataSource);
  final UnitRepository _unitRepository = UnitRepository(_dataSource);

  UserModel? _profile;
  Map<String, double> _userTauntsPercentage = {};
  Map<String, String> _tauntIdToNameMap = {};
  ViewState _state = ViewState.loading;
  String _errorMessage = '';

  // Специфичные кэш-карты для связи сущностей без повторной загрузки данных
  Map<String, List<String>> _metricToTauntsMap = {};
  Map<String, bool> _metricToLowerIsBetterMap = {};
  Map<String, String> _metricIdToNameMap = {};
  Map<String, String> _metricIdToUnitMap = {};
  Map<String, double> _eliteMetricsMap = {};

  // MVVM Геттеры
  bool get hasData => _profile != null;
  String get formattedUserName => _profile?.userName.toUpperCase() ?? '';

  Map<String, double> get userTauntsPercentage => _userTauntsPercentage;
  Map<String, String> get tauntNames => _tauntIdToNameMap;
  ViewState get state => _state;
  String get errorMessage => _errorMessage;

  /// Загрузка данных из репозиториев (вызывается один раз при старте экрана)
  Future<void> loadAndProcessMetrics() async {
    try {
      _state = ViewState.loading;
      notifyListeners();

      final results = await Future.wait([
        _userRepository.getUsers("users"),
        _userRepository.getUsers("usersStandarts"),
        _tauntRepository.getTaunts(),
        _metricRepository.getMetricDefinitions(),
        _unitRepository.getUnits(),
      ]);

      final List<UserModel> users = results[0] as List<UserModel>;
      final List<UserModel> standards = results[1] as List<UserModel>;
      final List<TauntModel> tauntsList = results[2] as List<TauntModel>;
      final List<MetricModel> globalMetrics = results[3] as List<MetricModel>;
      final List<UnitModel> unitsList = results[4] as List<UnitModel>;

      if (users.isEmpty || standards.isEmpty) {
        throw Exception("Пользователи или нормативы не найдены в репозиториях");
      }

      final user = users.first;
      final eliteUser = standards.first;
      _profile = user;

      // Мапим ID таунтов на их имена
      _tauntIdToNameMap = {for (var t in tauntsList) t.tauntId: t.tauntName};

      // Мапим ID юнитов на их строковые имена (kg, seconds...)
      final Map<String, String> unitIdToNameMap = {
        for (var u in unitsList) u.unitId: u.unitName,
      };

      // Наполняем глобальные кэш-карты связей для быстрого O(1) доступа
      _metricToTauntsMap = {};
      _metricToLowerIsBetterMap = {};
      _metricIdToNameMap = {};
      _metricIdToUnitMap = {};

      for (var m in globalMetrics) {
        _metricToLowerIsBetterMap[m.metricId] = m.lowerIsBetter;
        _metricToTauntsMap[m.metricId] = m.tauntIds;
        _metricIdToNameMap[m.metricId] = m.metricName;
        _metricIdToUnitMap[m.metricId] = unitIdToNameMap[m.unitId] ?? '';
      }

      // Сохраняем нормативы элиты
      _eliteMetricsMap = {
        for (var m in eliteUser.userMetrics)
          m.metricId: (m.value as num).toDouble(),
      };

      // Рассчитываем проценты
      _recalculateMetrics();

      _state = ViewState.success;
    } catch (e) {
      _errorMessage = e.toString();
      _state = ViewState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Возвращает отфильтрованный список метрик, привязанных к конкретному tauntId
  List<Map<String, dynamic>> getMetricsForTaunt(String tauntId) {
    if (_profile == null) return [];

    final List<Map<String, dynamic>> filteredMetrics = [];

    for (var uMetric in _profile!.userMetrics) {
      final metricId = uMetric.metricId;
      final associatedTaunts = _metricToTauntsMap[metricId] ?? [];

      if (associatedTaunts.contains(tauntId)) {
        filteredMetrics.add({
          'metricId': metricId,
          'metricName': _metricIdToNameMap[metricId] ?? metricId,
          'unitName': _metricIdToUnitMap[metricId] ?? '',
          'value': (uMetric.value as num).toDouble(),
        });
      }
    }

    return filteredMetrics;
  }

  void updateMetricValue(String metricId, double newValue) {
    if (_profile == null) return;

    // Ищем индекс нужной метрики в списке пользователя
    final index = _profile!.userMetrics.indexWhere(
      (m) => m.metricId == metricId,
    );

    if (index != -1) {
      final currentMetric = _profile!.userMetrics[index];

      _profile!.userMetrics[index] = UserMetricModel(
        metricId: currentMetric.metricId,
        value: newValue,
      );

      _recalculateMetrics();
      notifyListeners();
    }
  }

  /// Изолированная математика пересчета процентов по категориям (Taunts)
  void _recalculateMetrics() {
    if (_profile == null) return;

    final Map<String, List<double>> userScoresAccumulator = {
      for (var tauntId in _tauntIdToNameMap.keys) tauntId: [],
    };

    for (var uMetric in _profile!.userMetrics) {
      final String metricId = uMetric.metricId;
      final double uValue = (uMetric.value as num).toDouble();

      if (_eliteMetricsMap.containsKey(metricId) &&
          _metricToTauntsMap.containsKey(metricId)) {
        final double eValue = _eliteMetricsMap[metricId]!;

        if (eValue > 0 && uValue > 0) {
          final bool lowerIsBetter =
              _metricToLowerIsBetterMap[metricId] ?? false;

          final double userProgress = lowerIsBetter
              ? (eValue / uValue) * 100
              : (uValue / eValue) * 100;

          for (String tauntId in _metricToTauntsMap[metricId]!) {
            if (userScoresAccumulator.containsKey(tauntId)) {
              userScoresAccumulator[tauntId]!.add(userProgress);
            }
          }
        }
      }
    }

    _userTauntsPercentage = {};
    for (var tauntId in _tauntIdToNameMap.keys) {
      final scores = userScoresAccumulator[tauntId]!;
      _userTauntsPercentage[tauntId] = scores.isNotEmpty
          ? double.parse(
              (scores.reduce((a, b) => a + b) / scores.length).toStringAsFixed(
                1,
              ),
            )
          : 0.0;
    }
  }
}
