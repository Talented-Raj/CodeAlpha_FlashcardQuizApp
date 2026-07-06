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



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final flashcardProvider = Provider.of<FlashcardProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    
    final username = authProvider.user?.name.isNotEmpty == true 
        ? authProvider.user!.name 
        : 'Student';

    // Width checks for responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/statistics');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
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
                    // Dynamic Welcome Header
                    Text(
                      'Welcome back, $username',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ).animate().fade(duration: 400.ms).slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 16),

                    // Statistics Preview Section
                    _buildStatsGrid(context, flashcardProvider, isWide),
                    const SizedBox(height: 24),

                    // Categories Carousel
                    _buildCategoriesSection(context, flashcardProvider),
                    const SizedBox(height: 24),

                    // Favorites Preview Row
                    if (flashcardProvider.favoriteFlashcards.isNotEmpty) ...[
                      _buildFavoritesSection(context, flashcardProvider),
                      const SizedBox(height: 24),
                    ],

                    // Recent Cards / search Results
                    _buildRecentCardsSection(context, flashcardProvider),
                  ],
                ),
              ),
            ),
      floatingActionButton: Semantics(
        label: 'Create new flashcard',
        button: true,
        child: FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, '/add-edit-card'),
          backgroundColor: theme.colorScheme.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, FlashcardProvider provider, bool isWide) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final boxStats = provider.boxDistribution;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomCard(
                onTap: () => Navigator.pushNamed(context, '/statistics'),
                backgroundColor: theme.colorScheme.primary.withOpacity(0.08),
                borderSide: BorderSide(color: theme.colorScheme.primary.withOpacity(0.2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOTAL CARDS', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${provider.totalCount}', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomCard(
                onTap: () => Navigator.pushNamed(context, '/statistics'),
                backgroundColor: AppColors.warning.withOpacity(0.08),
                borderSide: const BorderSide(color: AppColors.warning),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DUE REVIEW', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, color: AppColors.warning)),
                    const SizedBox(height: 4),
                    Text('${provider.dueCount}', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.warning)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Leitner progress distribution line
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Leitner Box Distribution',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  final boxNum = index + 1;
                  final count = boxStats[boxNum] ?? 0;
                  return Column(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primaryGradient[0].withOpacity(0.1 + (index * 0.15)),
                        child: Text(
                          '$boxNum',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$count cards',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    ).animate().fade(delay: 100.ms, duration: 400.ms);
  }

  Widget _buildCategoriesSection(BuildContext context, FlashcardProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (provider.categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Study Decks',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final category = provider.categories[index];
              final cards = provider.flashcards.where((c) => c.category == category).toList();
              final due = cards.where((c) => provider.dueFlashcards.any((d) => d.id == c.id)).length;

              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                child: CustomCard(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/study',
                      arguments: category,
                    );
                  },
                  gradient: index % 2 == 0 ? AppColors.primaryGradient : null,
                  backgroundColor: index % 2 != 0 ? (isDark ? AppColors.darkSurface : Colors.white) : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: index % 2 == 0 ? Colors.white : (isDark ? Colors.white : Colors.black),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cards.length} cards',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: index % 2 == 0 ? Colors.white.withOpacity(0.8) : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ),
                          if (due > 0)
                            Text(
                              '$due due review',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: index % 2 == 0 ? Colors.amberAccent : AppColors.warning,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fade(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildFavoritesSection(BuildContext context, FlashcardProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Starred / Favorites',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: provider.favoriteFlashcards.length,
            itemBuilder: (context, index) {
              final card = provider.favoriteFlashcards[index];
              return Container(
                width: 220,
                margin: const EdgeInsets.only(right: 12),
                child: CustomCard(
                  backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              card.front,
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              card.category,
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.star, color: Colors.amber),
                        onPressed: () => provider.toggleFavorite(card),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fade(delay: 250.ms, duration: 400.ms);
  }

  Widget _buildRecentCardsSection(BuildContext context, FlashcardProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasSearchQuery = provider.searchQuery.isNotEmpty;
    final displayList = provider.flashcards;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasSearchQuery ? 'Search Results' : 'Recent Flashcards',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        if (displayList.isEmpty)
          CustomCard(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 56,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    hasSearchQuery ? 'No matching cards found' : 'No flashcards yet',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasSearchQuery
                        ? 'Try modifying your search text'
                        : 'Tap the Floating Action Button below to add cards to your study deck!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: hasSearchQuery ? displayList.length : (displayList.length > 5 ? 5 : displayList.length),
            itemBuilder: (context, index) {
              final card = displayList[index];
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.front,
                              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
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
                                  'Box ${card.box}',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          card.isFavorite ? Icons.star : Icons.star_border,
                          color: card.isFavorite ? Colors.amber : null,
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
              );
            },
          ),
      ],
    ).animate().fade(delay: 300.ms, duration: 400.ms);
  }
}
