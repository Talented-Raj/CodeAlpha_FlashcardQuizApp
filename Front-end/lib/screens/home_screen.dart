import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/flashcard_model.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategoryFilter = 'All';

  String _getCategoryEmoji(String category) {
    switch (category.trim().toLowerCase()) {
      case 'programming':
        return '💻';
      case 'mathematics':
        return '📐';
      case 'science':
        return '🧪';
      case 'history':
        return '📜';
      case 'english':
        return '📝';
      default:
        return '🎓';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final flashcardProvider = Provider.of<FlashcardProvider>(context);
    
    // Width checks for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Flashcard Quiz App',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search Flashcards',
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: flashcardProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => flashcardProvider.loadData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Daily Study Goal Counter
                    _buildDailyGoalProgress(context, flashcardProvider),
                    const SizedBox(height: 24),

                    // Categories section
                    _buildCategoriesSection(context, flashcardProvider, isWide),
                    const SizedBox(height: 24),

                    // Sort controls panel & Filter
                    _buildSortingAndFilteringPanel(context, flashcardProvider),
                    const SizedBox(height: 16),

                    // Flashcard List / Recent List
                    _buildFlashcardsList(context, flashcardProvider),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add-edit-card'),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Flashcard', style: TextStyle(color: Colors.white)),
        backgroundColor: theme.colorScheme.primary,
        elevation: 4,
      ),
    );
  }

  Widget _buildDailyGoalProgress(BuildContext context, FlashcardProvider provider) {
    final theme = Theme.of(context);
    final count = provider.studiedTodayCount;
    const dailyGoal = 20;
    final progress = (count / dailyGoal).clamp(0.0, 1.0);

    return CustomCard(
      backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
      borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAILY STUDY PROGRESS',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    count >= dailyGoal
                        ? 'Daily Goal Met! Keep it up!'
                        : 'Study $count of $dailyGoal cards today',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Icon(
                count >= dailyGoal ? Icons.emoji_events : Icons.local_fire_department,
                color: count >= dailyGoal ? Colors.amber : Colors.orange,
                size: 32,
              ).animate(target: count >= dailyGoal ? 1 : 0).shake(),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% Completed',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '$count / $dailyGoal studied',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildCategoriesSection(BuildContext context, FlashcardProvider provider, bool isWide) {
    final theme = Theme.of(context);
    final categories = provider.categories;

    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Decks',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final cards = provider.flashcards.where((c) => c.category == category).toList();
              final emoji = _getCategoryEmoji(category);

              return Container(
                width: 170,
                margin: const EdgeInsets.only(right: 12),
                child: CustomCard(
                  onTap: () {
                    Navigator.pushNamed(context, '/study', arguments: category);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${cards.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushNamed(context, '/study', arguments: category);
                              },
                              child: const Text('Start', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fade(delay: 150.ms, duration: 400.ms);
  }

  Widget _buildSortingAndFilteringPanel(BuildContext context, FlashcardProvider provider) {
    final theme = Theme.of(context);
    final categories = ['All', ...provider.categories];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'All Flashcards',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            PopupMenuButton<String>(
              icon: Row(
                children: [
                  const Icon(Icons.sort, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    provider.currentSortMode == 'date'
                        ? 'Newest'
                        : provider.currentSortMode == 'category'
                            ? 'Category'
                            : 'Alphabetical',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              tooltip: 'Sort Options',
              onSelected: (mode) {
                provider.setSortMode(mode);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'date',
                  child: Text('Sort by Date Added'),
                ),
                const PopupMenuItem(
                  value: 'category',
                  child: Text('Sort by Category'),
                ),
                const PopupMenuItem(
                  value: 'alphabetical',
                  child: Text('Sort Alphabetically'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Horizontal category filters
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _selectedCategoryFilter == cat;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      _selectedCategoryFilter = cat;
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFlashcardsList(BuildContext context, FlashcardProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Filter by category selection
    final allCards = provider.flashcards;
    final displayCards = _selectedCategoryFilter == 'All'
        ? allCards
        : allCards.where((c) => c.category == _selectedCategoryFilter).toList();

    if (displayCards.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayCards.length,
      itemBuilder: (context, index) {
        final card = displayCards[index];
        final emoji = _getCategoryEmoji(card.category);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: CustomCard(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/add-edit-card',
                arguments: card,
              );
            },
            child: Row(
              children: [
                // Category icon bubble
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Question / Answer preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.question,
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              card.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            card.difficulty,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: card.difficulty.toLowerCase() == 'hard'
                                  ? AppColors.error
                                  : card.difficulty.toLowerCase() == 'medium'
                                      ? AppColors.warning
                                      : AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Actions: Star and Delete
                IconButton(
                  icon: Icon(
                    card.favorite ? Icons.star : Icons.star_border,
                    color: card.favorite ? Colors.amber : null,
                  ),
                  onPressed: () => provider.toggleFavorite(card),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () {
                    CustomDialog.showConfirmation(
                      context: context,
                      title: 'Delete Card',
                      message: 'Are you sure you want to delete this flashcard?',
                      confirmLabel: 'Delete',
                      isDestructive: true,
                    ).then((confirmed) {
                      if (confirmed == true && card.id != null) {
                        provider.deleteFlashcard(card.id!);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ).animate().fade(delay: (index * 50).ms, duration: 300.ms);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.style_outlined,
                size: 64,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Flashcards Found',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategoryFilter == 'All'
                  ? 'Get started by creating your very first flashcard!'
                  : 'No flashcards exist in category "${_selectedCategoryFilter}".',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            if (_selectedCategoryFilter != 'All')
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCategoryFilter = 'All';
                  });
                },
                child: const Text('View All Categories'),
              ),
          ],
        ),
      ),
    ).animate().fade(duration: 400.ms);
  }
}
