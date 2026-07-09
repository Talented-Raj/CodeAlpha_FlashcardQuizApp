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

  @override
  void initState() {
    super.initState();
    _loadActivityData();
  }

  Future<void> _loadActivityData() async {
    final provider = Provider.of<FlashcardProvider>(context, listen: false);

    // Fetch raw study logs from DB
    final rawLogs7 = await provider.getStudyLogsForPastDays(7);
    final last7Days = _getLastDates(7);

    final Map<String, int> weeklyMap = {for (var date in last7Days) date: 0};

    // Overlay logs
    for (var log in rawLogs7) {
      final date = log['date'] as String;
      if (weeklyMap.containsKey(date)) {
        weeklyMap[date] = log['cards_count'] as int;
      }
    }

    if (mounted) {
      setState(() {
        _weeklyData = weeklyMap;
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
        case 1: return 'M';
        case 2: return 'T';
        case 3: return 'W';
        case 4: return 'T';
        case 5: return 'F';
        case 6: return 'S';
        case 7: return 'S';
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
        title: const Text('Statistics'),
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
                      // Study Progress Goal
                      _buildStudyProgressCard(theme, provider),
                      const SizedBox(height: 24),

                      // Summary Counters Grid
                      _buildSummaryGrid(theme, provider),
                      const SizedBox(height: 24),

                      // Weekly Activity Bar Chart
                      _buildWeeklyBarChart(theme, isDark),
                      const SizedBox(height: 24),

                      // Category Distribution List (showing M3 animated progress bars)
                      _buildCategoryDistributionList(theme, provider),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStudyProgressCard(ThemeData theme, FlashcardProvider provider) {
    final studied = provider.studiedTodayCount;
    const dailyGoal = 20;
    final progress = (studied / dailyGoal).clamp(0.0, 1.0);

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Study Progress Today',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                '$studied / $dailyGoal cards',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            studied >= dailyGoal
                ? 'Congratulations! You met your daily study goal today! 🎉'
                : 'Study ${dailyGoal - studied} more cards to hit today\'s goal.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          // Animated M3 Progress Bar
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progress),
            duration: 800.ms,
            curve: Curves.easeOutCubic,
            builder: (context, val, child) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: val,
                      minHeight: 12,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${(val * 100).toStringAsFixed(0)}% complete',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms);
  }

  Widget _buildSummaryGrid(ThemeData theme, FlashcardProvider provider) {
    final total = provider.totalCount;
    final starred = provider.favoriteCount;
    final categoriesCount = provider.categories.length;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.1,
      children: [
        _buildStatTile(
          theme,
          title: 'Total Cards',
          value: '$total',
          icon: Icons.style,
          color: Colors.blue,
        ),
        _buildStatTile(
          theme,
          title: 'Starred',
          value: '$starred',
          icon: Icons.star,
          color: Colors.amber,
        ),
        _buildStatTile(
          theme,
          title: 'Decks',
          value: '$categoriesCount',
          icon: Icons.folder,
          color: Colors.purple,
        ),
      ],
    ).animate().fade(delay: 150.ms, duration: 400.ms);
  }

  Widget _buildStatTile(ThemeData theme, {required String title, required String value, required IconData icon, required Color color}) {
    return CustomCard(
      padding: const EdgeInsets.all(12),
      backgroundColor: color.withOpacity(0.08),
      borderSide: BorderSide(color: color.withOpacity(0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(ThemeData theme, bool isDark) {
    final maxVal = _weeklyData.values.isEmpty
        ? 10.0
        : _weeklyData.values.reduce((curr, next) => curr > next ? curr : next).toDouble();
    final double yLimit = maxVal < 5 ? 5.0 : maxVal + 2;

    final barGroups = <BarChartGroupData>[];
    int index = 0;
    
    _weeklyData.forEach((dateStr, count) {
      final label = _getWeekdayLabel(dateStr);
      barGroups.add(
        BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: theme.colorScheme.primary,
              width: 14,
              borderRadius: BorderRadius.circular(4),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: yLimit,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
      index++;
    });

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Review Activity',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: _weeklyData.isEmpty
                ? const Center(child: Text('No study logs available'))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: yLimit,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final idx = value.toInt();
                              if (idx >= 0 && idx < _weeklyData.keys.length) {
                                final dateStr = _weeklyData.keys.elementAt(idx);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    _getWeekdayLabel(dateStr),
                                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: barGroups,
                    ),
                  ),
          ),
        ],
      ),
    ).animate().fade(delay: 250.ms, duration: 400.ms);
  }

  Widget _buildCategoryDistributionList(ThemeData theme, FlashcardProvider provider) {
    final categories = provider.categories;
    final total = provider.totalCount;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deck Distributions',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (categories.isEmpty)
            const Text('No categories active')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final count = provider.flashcards.where((c) => c.category == category).length;
                final double ratio = total > 0 ? (count / total) : 0.0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$count cards (${(ratio * 100).toStringAsFixed(0)}%)',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Animated linear progress bar for the deck ratio
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: ratio),
                        duration: 800.ms,
                        curve: Curves.easeOutCubic,
                        builder: (context, val, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: val,
                              minHeight: 6,
                              backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryGradient[index % AppColors.primaryGradient.length],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    ).animate().fade(delay: 300.ms, duration: 400.ms);
  }
}
