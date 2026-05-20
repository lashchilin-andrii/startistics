import 'package:flutter/material.dart';
import 'package:startistics/view_model/profile_view_model.dart';

class EditMetricsScreen extends StatefulWidget {
  final String tauntId;
  final String tauntName;
  final ProfileViewModel viewModel;

  const EditMetricsScreen({
    super.key,
    required this.tauntId,
    required this.tauntName,
    required this.viewModel,
  });

  @override
  State<EditMetricsScreen> createState() => _EditMetricsScreenState();
}

class _EditMetricsScreenState extends State<EditMetricsScreen> {
  List<Map<String, dynamic>> _metricsToEdit = [];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _metricsToEdit = widget.viewModel.getMetricsForTaunt(widget.tauntId);

    for (var metric in _metricsToEdit) {
      final metricId = metric['metricId'] as String;
      final currentValue = metric['value'] as double;
      
      final String formattedValue = currentValue % 1 == 0
          ? currentValue.toInt().toString()
          : currentValue.toString();

      _controllers[metricId] = TextEditingController(text: formattedValue);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Сделали метод асинхронным для безопасной записи на флешку девайса
  void _saveAllChanges() async {
    // 1. Сначала переносим обновленные данные из полей ввода в оперативку ViewModel
    for (var metric in _metricsToEdit) {
      final metricId = metric['metricId'] as String;
      final text = _controllers[metricId]?.text ?? '';

      final newValue = double.tryParse(text) ?? 0.0;
      widget.viewModel.updateMetricValue(metricId, newValue);
    }

    // 2. Показываем системный диалог с крутилкой, блокируя интерфейс на время записи
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // 3. Вызываем асинхронное сохранение полного JSON на телефон
      await widget.viewModel.saveProfile();
    } catch (e) {
      // Здесь при желании можно вывести SnackBar с ошибкой
    } finally {
      // 4. Закрываем крутилку и возвращаемся назад на профиль
      if (mounted) {
        Navigator.pop(context); // Убирает диалог загрузки
        Navigator.pop(context); // Закрывает EditMetricsScreen
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tauntName),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save',
            onPressed: _saveAllChanges,
          ),
        ],
      ),
      body: _metricsToEdit.isEmpty
          ? const Center(child: Text('No metrics.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _metricsToEdit.length,
              itemBuilder: (context, index) {
                final metric = _metricsToEdit[index];
                final metricId = metric['metricId'] as String;
                final name = metric['metricName'] as String;
                final unit = metric['unitName'] as String;
                final controller = _controllers[metricId];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: TextField(
                            controller: controller,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              suffixText: unit,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}