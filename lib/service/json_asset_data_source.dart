import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class JsonAssetDataSource {
  const JsonAssetDataSource();

  // Имя файла, в котором мы будем хранить "БД" на телефоне пользователя
  static const String _dbFileName = 'db.json';

  /// Получает путь к файлу базы данных в локальной директории приложения
  /// Без path_provider используем внутреннее изолированное пространство приложения.
  Future<File> _getLocalFile() async {
    // В Android/Linux это безопасная папка самого приложения, куда есть доступ на запись.
    // Чтобы гарантировать правильный путь в зависимости от платформы, 
    // Flutter хранит пути к кэшу прямо в системных переменных среды.
    final String baseDir = Platform.isAndroid 
        ? '/data/data/com.example.startistics/files' // Стандартный путь для Android (замени com.example.startistics на свой applicationId, если менял его)
        : Directory.current.path;

    // Альтернативный и полностью кроссплатформенный вариант без путей — 
    // использовать подкапотный каталог приложения:
    final directory = Directory(baseDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    
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
    try {
      await localFile.writeAsString(jsonEncode(db));
    } catch (e) {
      // Лог на случай, если папка на какой-то кастомной прошивке защищена
      print("Ошибка первичного кэширования БД: $e");
    }
    return db;
  }

  /// Чтение конкретной секции (например, "users", "metrics")
  Future<List<dynamic>> getSection(String sectionName) async {
    final db = await _getFullDatabase();
    return db[sectionName] as List<dynamic>? ?? [];
  }

  /// Перезаписывает конкретную секцию и сохраняет весь JSON на диск
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