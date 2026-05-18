import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'stats_chart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startistics',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 0, 149, 255),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<Map<String, dynamic>> _userDataFuture;

  @override
  void initState() {
    super.initState();
    _userDataFuture = _loadAndProcessMetrics();
  }

  Future<Map<String, dynamic>> _loadAndProcessMetrics() async {
    final String dbJsonString = await rootBundle.loadString('asset/db.json');
    final Map<String, dynamic> dbData = jsonDecode(dbJsonString);

    final List<dynamic> globalMetrics = dbData["metrics"] ?? [];
    final List<dynamic> userMetrics = dbData["users"][0]["userMetrics"] ?? [];
    final List<dynamic> userEliteMetrics = dbData["usersStandarts"][0]["userMetrics"] ?? [];

    Map<String, List<String>> metricToTauntsMap = {};
    Map<String, bool> metricToLowerIsBetterMap = {};

    for (var m in globalMetrics) {
      String mId = m["metricId"];
      metricToLowerIsBetterMap[mId] = m["lowerIsBetter"] ?? false;
      if (m["tauntIds"] != null) {
        metricToTauntsMap[mId] = List<String>.from(m["tauntIds"]);
      }
    }

    Map<String, double> eliteMetricsMap = {};
    for (var m in userEliteMetrics) {
      eliteMetricsMap[m["metricId"]] = (m["value"] ?? 0.0).toDouble();
    }

    Map<String, List<double>> userScoresAccumulator = {};

    final List<String> standardTaunts = [
      "taunt_strength",
      "taunt_speed",
      "taunt_agility",
      "taunt_flexibility",
      "taunt_endurance"
    ];

    for (var tauntId in standardTaunts) {
      userScoresAccumulator[tauntId] = [];
    }

    for (var uMetric in userMetrics) {
      String metricId = uMetric["metricId"];
      double uValue = (uMetric["value"] ?? 0.0).toDouble();

      if (eliteMetricsMap.containsKey(metricId) && metricToTauntsMap.containsKey(metricId)) {
        double eValue = eliteMetricsMap[metricId]!;

        if (eValue > 0 && uValue > 0) {
          bool lowerIsBetter = metricToLowerIsBetterMap[metricId] ?? false;

          double userProgress = lowerIsBetter
              ? (eValue / uValue) * 100
              : (uValue / eValue) * 100;

          for (String tauntId in metricToTauntsMap[metricId]!) {
            userScoresAccumulator[tauntId]!.add(userProgress);
          }
        }
      }
    }

    Map<String, double> userTauntsPercentage = {};

    for (var tauntId in standardTaunts) {
      final scores = userScoresAccumulator[tauntId]!;
      userTauntsPercentage[tauntId] = scores.isNotEmpty
          ? double.parse(
              (scores.reduce((a, b) => a + b) / scores.length).toStringAsFixed(1))
          : 0.0;
    }

    return {
      "userName": dbData["users"][0]["userName"],
      "userTauntsPercentage": userTauntsPercentage,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _userDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text("Loading Profile..."), centerTitle: true),
            body: const Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text("Error"), centerTitle: true),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text("No Data"), centerTitle: true),
            body: const Center(child: Text('No analytical profiles found.')),
          );
        }

        final String userName = snapshot.data!["userName"];
        final Map<String, double> userTauntsPercentage =
            snapshot.data!["userTauntsPercentage"];

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            title: Text(userName.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: SizedBox(
                    width: 340,
                    height: 340,
                    child: PolygonalStatsChart(
                      stats: userTauntsPercentage,
                    ),
                  ),
                ),
                const Divider(),
                ...userTauntsPercentage.entries.map((entry) {
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    child: ListTile(
                      minTileHeight: 55,
                      leading: CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Text(entry.key.split('_').last[0].toUpperCase()),
                      ),
                      title: Text(
                        entry.key.split('_').last.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: Text(
                        "${entry.value}%",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
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

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}