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
  // Храним контроллеры, чтобы текст не сбрасывался при вводе
  final Map<String, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, child) {
        // Получаем отфильтрованные метрики для этого таунта из ViewModel
        final metricsToEdit = widget.viewModel.getMetricsForTaunt(
          widget.tauntId,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.tauntName),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: metricsToEdit.length,
            itemBuilder: (context, index) {
              final metric = metricsToEdit[index];
              final metricId = metric['metricId'] as String;
              final name = metric['metricName'] as String;
              final unit = metric['unitName'] as String;
              final currentValue = metric['value'] as double;

              // Инициализируем контроллер, если его еще нет
              final controller = _controllers.putIfAbsent(
                metricId,
                () => TextEditingController(text: currentValue.toString()),
              );

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
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
                          onChanged: (text) {
                            final newValue = double.tryParse(text) ?? 0.0;
                            // Передаем обновление во ViewModel
                            widget.viewModel.updateMetricValue(
                              metricId,
                              newValue,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
