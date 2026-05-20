import 'package:flutter/material.dart';
import 'package:startistics/view/edit_metrics_screen.dart';
import 'package:startistics/view/stats_chart.dart';
import 'package:startistics/view_model/profile_view_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileViewModel _viewModel = ProfileViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.loadAndProcessMetrics();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double chartSize = (screenWidth * 0.9).clamp(280.0, 400.0);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        if (_viewModel.state == ViewState.loading) {
          return Scaffold(
            appBar: AppBar(
              title: const Text("Loading Profile..."),
              centerTitle: true,
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (_viewModel.state == ViewState.error) {
          return Scaffold(
            appBar: AppBar(title: const Text("Error"), centerTitle: true),
            body: Center(child: Text('Error: ${_viewModel.errorMessage}')),
          );
        }

        if (!_viewModel.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text("No Data"), centerTitle: true),
            body: const Center(child: Text('No analytical profiles found.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            title: Text(
              _viewModel.formattedUserName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 30),
                    width: chartSize,
                    height: chartSize,
                    child: PolygonalStatsChart(
                      stats: _viewModel.userTauntsPercentage,
                    ),
                  ),
                ),

                const Divider(),

                // Итерируемся напрямую по списку моделей таунтов из ViewModel
                ..._viewModel.taunts.map((taunt) {
                  // Получаем процент для текущего таунта (дефолт 0.0, если данных нет)
                  final double percentage = _viewModel.userTauntsPercentage[taunt.tauntId] ?? 0.0;
                  final String displayName = taunt.tauntName;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 10,
                    ),
                    child: ListTile(
                      minTileHeight: 55,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditMetricsScreen(
                              tauntId: taunt.tauntId,
                              tauntName: displayName,
                              viewModel: _viewModel, // Передаем вьюмодель для реактивности
                            ),
                          ),
                        );
                      },
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : "?",
                        ),
                      ),
                      title: Text(
                        displayName,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${percentage.toStringAsFixed(1)}%",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: Theme.of(context).hintColor,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}