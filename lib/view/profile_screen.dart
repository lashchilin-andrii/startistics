import 'package:flutter/material.dart';
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
    final double chartSize = (screenWidth * 0.85).clamp(280.0, 400.0);

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

        // MVVM Оптимизация: Проверяем флаг наличия данных во ViewModel
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
              // Читаем подготовленную строку напрямую из ViewModel (View не форматирует данные)
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
                  child: SizedBox(
                    width: chartSize,
                    height: chartSize,
                    child: PolygonalStatsChart(
                      stats: _viewModel.userTauntsPercentage,
                    ),
                  ),
                ),
                const Divider(),
                ..._viewModel.userTauntsPercentage.entries.map((entry) {
                  final String displayName = _viewModel.tauntNames[entry.key] ?? "";

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 10,
                    ),
                    child: ListTile(
                      minTileHeight: 55,
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
                      trailing: Text(
                        "${entry.value}%",
                        style: Theme.of(context).textTheme.bodyMedium,
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