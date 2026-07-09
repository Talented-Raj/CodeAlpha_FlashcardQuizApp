import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/flashcard_model.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/custom_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _recentSearches = [];
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initPrefs();
    
    // Clear any leftover search query on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FlashcardProvider>(context, listen: false).setSearchQuery('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentSearches = _prefs?.getStringList('recent_searches') ?? [];
    });
  }

  Future<void> _addSearchToHistory(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    List<String> newList = List.from(_recentSearches);
    newList.removeWhere((item) => item.toLowerCase() == trimmed.toLowerCase());
    newList.insert(0, trimmed);

    if (newList.length > 10) {
      newList = newList.sublist(0, 10);
    }

    setState(() {
      _recentSearches = newList;
    });
    await _prefs?.setStringList('recent_searches', newList);
  }

  Future<void> _clearSearchHistory() async {
    setState(() {
      _recentSearches = [];
    });
    await _prefs?.remove('recent_searches');
  }

  Future<void> _removeHistoryItem(String item) async {
    List<String> newList = List.from(_recentSearches);
    newList.remove(item);
    setState(() {
      _recentSearches = newList;
    });
    await _prefs?.setStringList('recent_searches', newList);
  }

  void _triggerSearch(String query) {
    _searchController.text = query;
    Provider.of<FlashcardProvider>(context, listen: false).setSearchQuery(query);
    _addSearchToHistory(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final flashcardProvider = Provider.of<FlashcardProvider>(context);

    final displayList = flashcardProvider.flashcards;
    final hasQuery = flashcardProvider.searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search question, answer, category...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        flashcardProvider.setSearchQuery('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkSurface : AppColors.lightBorder.withOpacity(0.5),
            ),
            onChanged: (val) {
              flashcardProvider.setSearchQuery(val);
            },
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                _addSearchToHistory(val);
              }
            },
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hasQuery) ...[
                _buildSearchHistory(theme),
                const SizedBox(height: 24),
                _buildSearchSuggestions(theme, flashcardProvider),
              ] else ...[
                // Search Results list
                Expanded(
                  child: displayList.isEmpty
                      ? _buildNoResultsView(theme, isDark, flashcardProvider.searchQuery)
                      : ListView.builder(
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final card = displayList[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: CustomCard(
                                onTap: () {
                                  _addSearchToHistory(flashcardProvider.searchQuery);
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
                                            card.question,
                                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            card.answer,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
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
                                    IconButton(
                                      icon: Icon(
                                        card.favorite ? Icons.star : Icons.star_border,
                                        color: card.favorite ? Colors.amber : null,
                                      ),
                                      tooltip: card.favorite ? 'Remove from favorites' : 'Add to favorites',
                                      onPressed: () => flashcardProvider.toggleFavorite(card),
                                    ),
                                  ],
                                ),
                              ),
                            )
                                .animate()
                                .fade(delay: (index * 40).ms, duration: 300.ms)
                                .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
                          },
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHistory(ThemeData theme) {
    if (_recentSearches.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Searches',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: _clearSearchHistory,
              child: const Text('Clear All', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recentSearches.map((item) {
            return InputChip(
              label: Text(item),
              onPressed: () => _triggerSearch(item),
              onDeleted: () => _removeHistoryItem(item),
            );
          }).toList(),
        ),
      ],
    ).animate().fade(duration: 300.ms);
  }

  Widget _buildSearchSuggestions(ThemeData theme, FlashcardProvider provider) {
    final categories = provider.categories;
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search by Category Decks',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: categories.map((cat) {
            return ActionChip(
              avatar: const Icon(Icons.folder_open, size: 16),
              label: Text(cat),
              onPressed: () => _triggerSearch(cat),
            );
          }).toList(),
        ),
      ],
    ).animate().fade(delay: 100.ms, duration: 300.ms);
  }

  Widget _buildNoResultsView(ThemeData theme, bool isDark, String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No Results Found',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'No flashcards matched your query: "$query".\nTry checking the spelling or use simpler keywords.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms);
  }
}
