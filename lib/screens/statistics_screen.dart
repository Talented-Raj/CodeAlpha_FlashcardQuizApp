import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/custom_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({Key? key}) : super(key: key);

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoadingLogs = true;
  Map<String, int> _weeklyData = {};
  Map<String, int> _monthlyData = {};

  @override
  void initState() {
    super.initState();
    _loadActivityData();
  }

  Future<void> _loadActivityData() async {
    final provider = Provider.of<FlashcardProvider>(context, listen: false);

    // Fetch raw study logs from DB
    final rawLogs7 = await provider.getStudyLogsForPastDays(7);
    final rawLogs30 = await provider.getStudyLogsForPastDays(30);

    // Pre-fill lists of dates for past 7 days and 30 days
    final last7Days = _getLastDates(7);
    final last30Days = _getLastDates(30);

    final Map<String, int> weeklyMap = {for (var date in last7Days) date: 0};
    final Map<String, int> monthlyMap = {for (var date in last30Days) date: 0};

    // Overlay logs
    for (var log in rawLogs7) {
      final date = log['date'] as String;
      if (weeklyMap.containsKey(date)) {
        weeklyMap[date] = log['cards_count'] as int;
      }
    }

    for (var log in rawLogs30) {
      final date = log['date'] as String;
      if (monthlyMap.containsKey(date)) {
        monthlyMap[date] = log['cards_count'] as int;
      }
    }

    if (mounted) {
      setState(() {
        _weeklyData = weeklyMap;
        _monthlyData = monthlyMap;
        _isLoadingLogs = false;
      });
    }
  }

  List<String> _getLastDates(int daysCount) {
    final List<String> dates = [];
    for (int i = daysCount - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      dates.add(date.toString().substring(0, 10));
    }
    return dates;
  }

  String _getWeekdayLabel(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      switch (date.weekday) {
        case 1: return 'Mon';
        case 2: return 'Tue';
        case 3: return 'Wed';
        case 4: return 'Thu';
        case 5: return 'Fri';
        case 6: return 'Sat';
        case 7: return 'Sun';
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<FlashcardProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics Dashboard'),
      ),
      body: SafeArea(
        child: provider.isLoading || _isLoadingLogs
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () async {
                  await provider.loadData();
                  await _loadActivityData();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Summary Counters Grid
                      _buildSummaryGrid(theme, isDark, provider),
                      const SizedBox(height: 24),

                      // Section 2: Leitner Box Distribution (Pie Chart)
                      _buildLeitnerPieChart(theme, isDark, provider),
                      const SizedBox(height: 24),

                      // Section 3: Weekly Activity (Bar Chart)
                      _buildWeeklyBarChart(theme, isDark),
                      const SizedBox(height: 24),

                      // Section 4: Monthly Activity (Line Chart)
                      _buildMonthlyLineChart(theme, isDark),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryGrid(ThemeData theme, bool isDark, FlashcardProvider provider) {
    final studiedToday = provider.studiedTodayCount;
    final total = provider.totalCount;
    final starred = provider.favoriteCount;
    final decksCount = provider.categories.length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          theme,
          title: 'STUDIED TODAY',
          value: '$studiedToday',
          icon: Icons.check_circle_outline,
          color: theme.colorScheme.primary,
        ),
        _buildStatCard(
          theme,
          title: 'TOTAL CARDS',
          value: '$total',
          icon: Icons.style_outlined,
          color: Colors.blue,
        ),
        _buildStatCard(
          theme,
          title: 'STARRED',
          value: '$starred',
          icon: Icons.star_outline,
          color: Colors.amber,
        ),
        _buildStatCard(
          theme,
          title: 'DECKS',
          value: '$decksCount',
          icon: Icons.folder_outlined,
          color: Colors.purple,
        ),
      ],
    ).animate().fade(duration: 350.ms);
  }

  Widget _buildStatCard(ThemeData theme, {required String title, required String value, required IconData icon, required Color color}) {
    final isDark = theme.brightness == Brightness.dark;
    return CustomCard(
      backgroundColor: color.withOpacity(0.08),
      borderSide: BorderSide(color: color.withOpacity(0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeitnerPieChart(ThemeData theme, bool isDark, FlashcardProvider provider) {
    final dist = provider.boxDistribution;
    final total = provider.totalCount;

    if (total == 0) {
      return CustomCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            children: [
              Text('Leitner Box Distribution', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('No cards available to map distribution.', textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final sections = dist.entries.map((entry) {
      final boxNum = entry.key;
      final count = entry.value;
      final percentage = total > 0 ? (count / total * 100).toStringAsFixed(0) : '0';

      Color color;
      switch (boxNum) {
        case 1: color = Colors.redAccent; break;
        case 2: color = Colors.orangeAccent; break;
        case 3: color = Colors.yellowAccent; break;
        case 4: color = Colors.lightGreenAccent; break;
        case 5: color = Colors.green; break;
        default: color = Colors.grey;
      }

      return PieChartSectionData(
        value: count.toDouble(),
        title: '$percentage%',
        radius: 40,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
        color: color,
      );
    }).toList();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Leitner Box Distribution',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Boxes 1-5 progress distribution overview.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: PieChart(
                    PieChartData(
                      sections: sections,
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: dist.entries.map((entry) {
                      final boxNum = entry.key;
                      final count = entry.value;
                      
                      Color color;
                      switch (boxNum) {
                        case 1: color = Colors.redAccent; break;
                        case 2: color = Colors.orangeAccent; break;
                        case 3: color = Colors.yellowAccent; break;
                        case 4: color = Colors.lightGreenAccent; break;
                        case 5: color = Colors.green; break;
                        default: color = Colors.grey;
                      }

                      return Row(
                        children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text('Box $boxNum: $count cards', style: const TextStyle(fontSize: 12)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 100.ms, duration: 400.ms);
  }

  Widget _buildWeeklyBarChart(ThemeData theme, bool isDark) {
    final entries = _weeklyData.entries.toList();

    final barGroups = List.generate(entries.length, (index) {
      final value = entries[index].value.toDouble();
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            gradient: const LinearGradient(
              colors: [Colors.purple, Colors.deepPurpleAccent],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: 16,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: 10,
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
            ),
          ),
        ],
      );
    });

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Activity',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Cards studied over the past 7 days.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _getMaxY(_weeklyData.values),
                barGroups: barGroups,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < entries.length) {
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              _getWeekdayLabel(entries[idx].key),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildMonthlyLineChart(ThemeData theme, bool isDark) {
    final entries = _monthlyData.entries.toList();

    final spots = List.generate(entries.length, (index) {
      return FlSpot(index.toDouble(), entries[index].value.toDouble());
    });

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Activity Log',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Cards studied over the past 30 days.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                maxY: _getMaxY(_monthlyData.values),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final idx = value.toInt();
                        // Only show label for start, middle and end to avoid crowding
                        if (idx == 0 || idx == 14 || idx == 29) {
                          final dateStr = entries[idx].key;
                          final formattedStr = dateStr.substring(8); // Just show Day number YYYY-MM-[DD]
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              formattedStr,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Colors.blue, Colors.cyan],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [Colors.blue.withOpacity(0.2), Colors.cyan.withOpacity(0.01)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 300.ms, duration: 400.ms);
  }

  double _getMaxY(Iterable<int> values) {
    if (values.isEmpty) return 10.0;
    final maxVal = values.reduce((curr, next) => curr > next ? curr : next).toDouble();
    return maxVal < 5 ? 5.0 : maxVal + 2; // ensure there's padding and minimum height
  }
}
