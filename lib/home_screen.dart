import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String intensityValue = "Loading...";
  String intensityIndex = "Loading...";
  String message = "Loading...";
  List<FlSpot> graphData = [];

  @override
  void initState() {
    super.initState();
    fetchCarbonIntensity();
    fetchGraphData();
  }

  Future<void> fetchCarbonIntensity() async {
    const url = 'https://api.carbonintensity.org.uk/intensity';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final intensity = data['data'][0]['intensity'];

      setState(() {
        intensityValue = "${intensity['actual']} gCO₂/kWh";
        intensityIndex = intensity['index'].toUpperCase();
      });
    } else {
      setState(() {
        intensityValue = "Failed to load data (HTTP ${response.statusCode})";
        intensityIndex = "N/A";
        message = "Please try again later.";
      });
    }
  }

  Future<void> fetchGraphData() async {
    const url = 'https://api.carbonintensity.org.uk/intensity/date/2024-11-18';

    final response = await http.get(Uri.parse(url));
    log("API Response: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'];

      if (data == null || data.isEmpty) {
        setState(() {
          message = "No data available for the selected date.";
        });
        return;
      }

      List<FlSpot> tempData = [];
      for (int i = 0; i < data.length; i++) {
        double time = i.toDouble();
        double actual = data[i]['intensity']['actual']?.toDouble() ?? 0;

        tempData.add(FlSpot(time, actual));
      }

      setState(() {
        graphData = tempData;
      });
    } else {
      log("Failed to fetch data. Status Code: ${response.statusCode}");
      setState(() {
        message = "Failed to fetch data.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF7380FD),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const SafeArea(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Carbon Buddy ',
                    style: TextStyle(
                      color: Color(0xFF7380FD),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    Icons.emoji_emotions_outlined,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 10, top: 20, right: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Reload the data:",
                    style: TextStyle(color: Color(0xFF7380FD)),
                  ),
                  IconButton(
                      onPressed: () {
                        fetchCarbonIntensity();
                      },
                      icon: const Icon(
                        Icons.refresh,
                        color: Color(0xFF7380FD),
                      ))
                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: 30, bottom: 40),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF7380FD), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7380FD).withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'National Carbon Intensity',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      intensityValue,
                      style: const TextStyle(
                        color: Color(0xFF7380FD),
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Divider(
                      color: Colors.white,
                      thickness: 2,
                      height: 30,
                    ),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Carbon intensity is $intensityIndex! Maybe take a break and read a book instead 📚.',
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 20),
                          padding: const EdgeInsets.all(40),
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            intensityIndex,
                            style: const TextStyle(
                              color: Color(0xFF7380FD),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Text(
                "National half-hourly carbon intensity for the current day.",
                style: TextStyle(
                    color: Color(0xFF7380FD),
                    fontSize: 22,
                    fontWeight: FontWeight.w500),
              ),
              graphData.isEmpty
                  ? const CircularProgressIndicator()
                  : SizedBox(
                  height: 300,
                  child: LineChart(
                    LineChartData(
                      backgroundColor:
                      const Color(0xFF7380FD).withOpacity(0.2),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: 50,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.white.withOpacity(0.1),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.left,
                              );
                            },
                          ),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: const Border(
                          left: BorderSide(color: Colors.white, width: 1),
                          bottom: BorderSide(color: Colors.transparent),
                          right: BorderSide(color: Colors.transparent),
                          top: BorderSide(color: Colors.transparent),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: graphData,
                          isCurved: true,
                          color: const Color(0xFF7380FD),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          belowBarData: BarAreaData(
                            show: false,
                          ),
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                      minY: 0,
                      maxY: 300,
                    ),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
