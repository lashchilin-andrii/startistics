import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class JsonAssetDataSource {
  const JsonAssetDataSource();

  // Имя файла, в котором мы будем хранить "БД" на телефоне пользователя
  static const String _dbFileName = 'db.json';

  /// Получает путь к файлу базы данных в локальных документах устройства
  Future<File> _getLocalFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_dbFileName');
  }

  /// Вспомогательный метод: загружает всю структуру JSON (из документов или из assets)
  Future<Map<String, dynamic>> _getFullDatabase() async {
    final localFile = await _getLocalFile();

    // 1. Если пользователь уже что-то сохранял, читаем файл с диска устройства
    if (await localFile.exists()) {
      final String contents = await localFile.readAsString();
      return jsonDecode(contents) as Map<String, dynamic>;
    }

    // 2. Если запускаем первый раз и локального файла нет, берем дефолтный из assets
    final String assetsContent = await rootBundle.loadString(
      'asset/db.json',
    );
    final Map<String, dynamic> db =
        jsonDecode(assetsContent) as Map<String, dynamic>;

    // Сразу кэшируем его на диск устройства для последующих модификаций
    await localFile.writeAsString(jsonEncode(db));
    return db;
  }

  /// Чтение конкретной секции (например, "users", "metrics")
  Future<List<dynamic>> getSection(String sectionName) async {
    final db = await _getFullDatabase();
    return db[sectionName] as List<dynamic>? ?? [];
  }

  /// НОВЫЙ МЕТОД: Перезаписывает конкретную секцию и сохраняет весь JSON на диск
  Future<void> saveSection(
    String sectionName,
    List<Map<String, dynamic>> newSectionData,
  ) async {
    // 1. Получаем текущую полную базу данных
    final db = await _getFullDatabase();

    // 2. Обновляем в ней только ту секцию, которую редактировал пользователь
    db[sectionName] = newSectionData;

    // 3. Записываем обновленный глобальный JSON обратно на постоянный диск телефона
    final localFile = await _getLocalFile();
    await localFile.writeAsString(jsonEncode(db));
  }
}
