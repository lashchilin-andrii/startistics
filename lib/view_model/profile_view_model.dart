import 'package:flutter/material.dart';
import '../service/json_asset_data_source.dart';
import '../repository/user.dart';
import '../repository/taunt.dart';
import '../repository/metric.dart';
import '../model/user.dart';

enum ViewState { loading, success, error }

class ProfileViewModel extends ChangeNotifier {
  static final _dataSource = JsonAssetDataSource();
  final UserRepository _userRepository = UserRepository(_dataSource);
  final TauntRepository _tauntRepository = TauntRepository(_dataSource);
  final MetricRepository _metricRepository = MetricRepository(_dataSource);

  UserModel? _profile;
  Map<String, double> _userTauntsPercentage = {};
  Map<String, String> _tauntIdToNameMap = {};
  ViewState _state = ViewState.loading;
  String _errorMessage = '';

  // MVVM Геттеры: Отдаем во View исключительно очищенные примитивы
  bool get hasData => _profile != null;
  String get formattedUserName => _profile?.userName.toUpperCase() ?? '';
  
  Map<String, double> get userTauntsPercentage => _userTauntsPercentage;
  Map<String, String> get tauntNames => _tauntIdToNameMap;
  ViewState get state => _state;
  String get errorMessage => _errorMessage;

  /// Загрузка и процессинг метрик через слой репозиториев
  Future<void> loadAndProcessMetrics() async {
    try {
      _state = ViewState.loading;
      notifyListeners();

      final results = await Future.wait([
        _userRepository.getUsers(),
        _userRepository.getUsersStandards(),
        _tauntRepository.getTaunts(),
        _metricRepository.getMetricDefinitions(),
      ]);

      final List<UserModel> users = results[0] as List<UserModel>;
      final List<UserModel> standards = results[1] as List<UserModel>;
      final tauntsList = results[2] as List;
      final globalMetrics = results[3] as List;

      if (users.isEmpty || standards.isEmpty) {
        throw Exception("Пользователи или нормативы не найдены в репозиториях");
      }

      final user = users.first;
      final eliteUser = standards.first;
      _profile = user;

      _tauntIdToNameMap = {for (var t in tauntsList) t.tauntId: t.tauntName};

      Map<String, List<String>> metricToTauntsMap = {};
      Map<String, bool> metricToLowerIsBetterMap = {};

      for (var m in globalMetrics) {
        metricToLowerIsBetterMap[m.metricId] = m.lowerIsBetter;
        metricToTauntsMap[m.metricId] = m.tauntIds;
      }

      Map<String, double> eliteMetricsMap = {
        for (var m in eliteUser.userMetrics) m.metricId: (m.value as num).toDouble(),
      };

      Map<String, List<double>> userScoresAccumulator = {};
      final List<String> standardTaunts = [
        "taunt_strength",
        "taunt_speed",
        "taunt_agility",
        "taunt_flexibility",
        "taunt_endurance",
      ];

      for (var tauntId in standardTaunts) {
        userScoresAccumulator[tauntId] = [];
      }

      for (var uMetric in user.userMetrics) {
        String metricId = uMetric.metricId;
        final uValue = (uMetric.value as num).toDouble();

        if (eliteMetricsMap.containsKey(metricId) &&
            metricToTauntsMap.containsKey(metricId)) {
          final eValue = eliteMetricsMap[metricId]!;

          if (eValue > 0 && uValue > 0) {
            bool lowerIsBetter = metricToLowerIsBetterMap[metricId] ?? false;
            double userProgress = lowerIsBetter
                ? (eValue / uValue) * 100
                : (uValue / eValue) * 100;

            for (String tauntId in metricToTauntsMap[metricId]!) {
              if (userScoresAccumulator.containsKey(tauntId)) {
                userScoresAccumulator[tauntId]!.add(userProgress);
              }
            }
          }
        }
      }

      _userTauntsPercentage = {};
      for (var tauntId in standardTaunts) {
        final scores = userScoresAccumulator[tauntId]!;
        _userTauntsPercentage[tauntId] = scores.isNotEmpty
            ? double.parse(
                (scores.reduce((a, b) => a + b) / scores.length).toStringAsFixed(1),
              )
            : 0.0;
      }

      _state = ViewState.success;
    } catch (e) {
      _errorMessage = e.toString();
      _state = ViewState.error;
    } finally {
      notifyListeners();
    }
  }
}