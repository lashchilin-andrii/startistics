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
  // Список метрик, который мы считаем ОДИН раз при открытии экрана
  List<Map<String, dynamic>> _metricsToEdit = [];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Получаем снапшот данных один раз. Экран больше не будет перестраиваться от notifyListeners
    _metricsToEdit = widget.viewModel.getMetricsForTaunt(widget.tauntId);

    // Сразу инициализируем все контроллеры сохраненными значениями
    for (var metric in _metricsToEdit) {
      final metricId = metric['metricId'] as String;
      final currentValue = metric['value'] as double;
      
      // Красиво убираем ".0", если число целое (например, 100 вместо 100.0)
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

  // Метод сохранения, который вызывается по нажатию на галочку
  void _saveAllChanges() {
    for (var metric in _metricsToEdit) {
      final metricId = metric['metricId'] as String;
      final text = _controllers[metricId]?.text ?? '';
      
      final newValue = double.tryParse(text) ?? 0.0;
      widget.viewModel.updateMetricValue(metricId, newValue);
    }
    
    // Возвращаемся на ProfileScreen, который сам обновится благодаря ListenableBuilder внутри него
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Больше никакого ListenableBuilder вокруг Scaffold!
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
                            // Параметр onChanged больше НЕ дергает ViewModel, фокус не пропадет!
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