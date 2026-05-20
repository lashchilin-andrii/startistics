import 'package:flutter/material.dart';
import 'package:startistics/model/metric.dart';
import 'package:startistics/model/taunt.dart';
import 'package:startistics/model/unit.dart';
import '../model/user.dart';
import '../model/user_metric.dart';
import '../repository/user.dart';
import '../repository/taunt.dart';
import '../repository/metric.dart';
import '../repository/unit.dart';

enum ViewState { loading, success, error }

class ProfileViewModel extends ChangeNotifier {
  // Чистые списки объектов из "БД" (JSON-файлов)
  UserModel? _profile;
  List<UserModel> _standards = [];
  List<TauntModel> _taunts = [];
  List<MetricModel> _metrics = [];
  List<UnitModel> _units = [];

  // КЭШ: Хранит всех пользователей из файла, чтобы не стереть их при обновлении текущего
  List<UserModel> _allUsersCache = [];

  // Результат вычислений для UI
  Map<String, double> _userTauntsPercentage = {};

  ViewState _state = ViewState.loading;
  String _errorMessage = '';

  // MVVM Геттеры
  bool get hasData => _profile != null;
  String get formattedUserName => _profile?.userName.toUpperCase() ?? '';
  ViewState get state => _state;
  String get errorMessage => _errorMessage;

  Map<String, double> get userTauntsPercentage => _userTauntsPercentage;
  List<TauntModel> get taunts => _taunts;

  /// Загрузка данных из репозиториев (вызывается один раз при старте экрана)
  Future<void> loadAndProcessMetrics() async {
    try {
      _state = ViewState.loading;
      notifyListeners();

      // Загружаем всё параллельно без блокировок
      final results = await Future.wait([
        UserRepository().readAllUsers(),
        UserRepository().readAllUsers(sectionName: "usersStandarts"),
        TauntRepository().readAllTaunts(),
        MetricRepository().readAllMetrics(),
        UnitRepository().readAllUnits(),
      ]);

      // Сохраняем исходный сырой список всех юзеров в кэш
      _allUsersCache = List<UserModel>.from(results[0]);

      _profile = _allUsersCache.firstOrNull;
      _standards = List<UserModel>.from(results[1]);
      _taunts = List<TauntModel>.from(results[2]);
      _metrics = List<MetricModel>.from(results[3]);
      _units = List<UnitModel>.from(results[4]);

      // Рассчитываем проценты на основе загруженных списков
      _recalculateMetrics();

      _state = ViewState.success;
    } catch (e) {
      _errorMessage = e.toString();
      _state = ViewState.error;
    } finally {
      notifyListeners();
    }
  }

  /// НОВЫЙ МЕТОД: Сохраняет изменения профиля из оперативки на постоянный диск телефона
  Future<void> saveProfile() async {
    if (_profile == null) return;

    // 1. Ищем текущего пользователя в закэшированном списке
    final index = _allUsersCache.indexWhere((u) => u.userId == _profile!.userId);
    
    if (index != -1) {
      // Обновляем данные пользователя в кэше списков
      _allUsersCache[index] = _profile!;
    } else {
      _allUsersCache.add(_profile!);
    }

    // 2. Вызываем метод репозитория для полной перезаписи секции "users"
    await UserRepository().saveUsers(_allUsersCache);
  }

  /// Возвращает отфильтрованный список метрик для конкретного таунта
  List<Map<String, dynamic>> getMetricsForTaunt(String tauntId) {
    if (_profile == null) return [];

    final List<Map<String, dynamic>> filteredMetrics = [];

    for (var uMetric in _profile!.userMetrics) {
      final metricDef = _metrics.firstWhere(
        (m) => m.metricId == uMetric.metricId,
        orElse: () => MetricModel(
          metricId: '',
          metricName: uMetric.metricId,
          unitId: '',
          lowerIsBetter: false,
          tauntIds: [],
        ),
      );

      if (metricDef.tauntIds.contains(tauntId)) {
        final unitDef = _units.firstWhere(
          (u) => u.unitId == metricDef.unitId,
          orElse: () => UnitModel(unitId: '', unitName: ''),
        );

        filteredMetrics.add({
          'metricId': uMetric.metricId,
          'metricName': metricDef.metricName,
          'unitName': unitDef.unitName,
          'value': uMetric.value,
        });
      }
    }

    return filteredMetrics;
  }

  /// Изменение значения пользователем
  void updateMetricValue(String metricId, double newValue) {
    if (_profile == null) return;

    final index = _profile!.userMetrics.indexWhere(
      (m) => m.metricId == metricId,
    );

    if (index != -1) {
      _profile!.userMetrics[index] = UserMetricModel(
        metricId: metricId,
        value: newValue,
      );

      _recalculateMetrics();
      notifyListeners();
    }
  }

  /// Математика пересчета процентов
  void _recalculateMetrics() {
    if (_profile == null || _standards.isEmpty) return;

    final eliteUser = _standards.first;

    final Map<String, List<double>> userScoresAccumulator = {
      for (var taunt in _taunts) taunt.tauntId: [],
    };

    for (var uMetric in _profile!.userMetrics) {
      final metricId = uMetric.metricId;

      final eliteMetric = eliteUser.userMetrics.firstWhere(
        (m) => m.metricId == metricId,
        orElse: () => UserMetricModel(metricId: '', value: 0),
      );

      final metricDef = _metrics.firstWhere(
        (m) => m.metricId == metricId,
        orElse: () => MetricModel(
          metricId: '',
          metricName: '',
          unitId: '',
          lowerIsBetter: false,
          tauntIds: [],
        ),
      );

      final double uValue = uMetric.value;
      final double eValue = eliteMetric.value;

      if (eValue > 0 && uValue > 0 && metricDef.metricId.isNotEmpty) {
        final double userProgress = metricDef.lowerIsBetter
            ? (eValue / uValue) * 100
            : (uValue / eValue) * 100;

        for (String tauntId in metricDef.tauntIds) {
          if (userScoresAccumulator.containsKey(tauntId)) {
            userScoresAccumulator[tauntId]!.add(userProgress);
          }
        }
      }
    }

    _userTauntsPercentage = {};
    for (var taunt in _taunts) {
      final scores = userScoresAccumulator[taunt.tauntId] ?? [];
      _userTauntsPercentage[taunt.tauntId] = scores.isNotEmpty
          ? double.parse(
              (scores.reduce((a, b) => a + b) / scores.length).toStringAsFixed(1),
            )
          : 0.0;
    }
  }
}