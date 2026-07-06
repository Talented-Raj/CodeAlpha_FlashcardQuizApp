import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/flashcard_model.dart';
import '../providers/flashcard_provider.dart';
import '../services/storage_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';

class StudyScreen extends StatefulWidget {
  final String category;

  const StudyScreen({Key? key, required this.category}) : super(key: key);

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  late PageController _pageController;
  List<FlashcardModel> _sessionCards = [];
  int _currentIndex = 0;
  bool _isShuffled = false;
  late List<GlobalKey<FlipCardState>> _cardKeys;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadSessionCards();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadSessionCards() async {
    final provider = Provider.of<FlashcardProvider>(context, listen: false);
    
    // Fetch target cards
    List<FlashcardModel> cards = [];
    if (widget.category == 'All Decks') {
      cards = List.from(provider.flashcards);
    } else {
      cards = provider.flashcards.where((c) => c.category == widget.category).toList();
    }

    if (cards.isEmpty) {
      if (mounted) {
        setState(() {
          _sessionCards = [];
          _cardKeys = [];
          _isLoading = false;
        });
      }
      return;
    }

    // Retrieve storage indices
    final prefs = await provider.loadData().then((_) => SharedPreferences.getInstance());
    final storage = StorageService(prefs);
    final savedIndex = storage.getLastStudiedIndex(widget.category);
    
    setState(() {
      _sessionCards = cards;
      _cardKeys = List.generate(cards.length, (_) => GlobalKey<FlipCardState>());
      _currentIndex = (savedIndex >= 0 && savedIndex < cards.length) ? savedIndex : 0;
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients && _currentIndex > 0) {
        _pageController.jumpToPage(_currentIndex);
      }
    });
  }

  void _saveCurrentPosition(int index) async {
    final provider = Provider.of<FlashcardProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final storage = StorageService(prefs);
    await storage.setLastStudiedIndex(widget.category, index);
  }

  void _handlePageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
    _saveCurrentPosition(index);
  }

  void _prevPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentIndex < _sessionCards.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _flipCurrentCard() {
    if (_sessionCards.isNotEmpty) {
      _cardKeys[_currentIndex].currentState?.toggleCard();
    }
  }

  void _toggleShuffle() {
    setState(() {
      _isShuffled = !_isShuffled;
      if (_isShuffled) {
        _sessionCards.shuffle();
      } else {
        _loadSessionCards();
        return;
      }
      // Reset keys for shuffled list
      _cardKeys = List.generate(_sessionCards.length, (_) => GlobalKey<FlipCardState>());
      _currentIndex = 0;
    });
    
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    _saveCurrentPosition(0);
  }

  void _toggleFavorite(FlashcardModel card) {
    Provider.of<FlashcardProvider>(context, listen: false).toggleFavorite(card);
  }

  void _submitReview(FlashcardModel card, bool correct) {
    final provider = Provider.of<FlashcardProvider>(context, listen: false);
    provider.reviewFlashcard(card, correct);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(correct ? 'Moved to Box ${card.box < 5 ? card.box + 1 : 5}' : 'Moved back to Box 1'),
        duration: const Duration(milliseconds: 600),
        behavior: SnackBarBehavior.floating,
        backgroundColor: correct ? AppColors.success : AppColors.error,
      ),
    );

    // Auto-advance if not at the end
    if (_currentIndex < _sessionCards.length - 1) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) _nextPage();
      });
    } else {
      // Completed last card
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLarge)),
              title: const Text('Deck Complete!', style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text('You have completed reviewing all the cards in this session. Great job!'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Exit study screen
                  },
                  child: const Text('Go Home'),
                ),
              ],
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_sessionCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.category)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.style_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No Cards Available',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'There are no flashcards in "${widget.category}" to review. Try creating some first!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Go Back',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentCard = _sessionCards[_currentIndex];
    final progress = _sessionCards.isEmpty ? 0.0 : (_currentIndex + 1) / _sessionCards.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        actions: [
          IconButton(
            icon: Icon(currentCard.isFavorite ? Icons.star : Icons.star_border),
            color: currentCard.isFavorite ? Colors.amber : null,
            onPressed: () => _toggleFavorite(currentCard),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            children: [
              // Progress Bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_currentIndex + 1}/${_sessionCards.length}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // PageView study area
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _sessionCards.length,
                  onPageChanged: _handlePageChanged,
                  itemBuilder: (context, index) {
                    final card = _sessionCards[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FlipCard(
                        key: _cardKeys[index],
                        direction: FlipDirection.HORIZONTAL,
                        speed: 300,
                        front: _buildCardFace(
                          context: context,
                          title: 'QUESTION',
                          content: card.front,
                          cardColor: theme.cardColor,
                        ),
                        back: _buildCardFace(
                          context: context,
                          title: 'ANSWER',
                          content: card.back,
                          cardColor: theme.colorScheme.primary.withOpacity(0.05),
                          borderSide: BorderSide(
                            color: theme.colorScheme.primary.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Spaced Repetition Session Rating Bar
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Forgot',
                      isPrimary: false,
                      textColor: AppColors.error,
                      onPressed: () => _submitReview(currentCard, false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      text: 'Know',
                      backgroundColor: AppColors.success,
                      onPressed: () => _submitReview(currentCard, true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tool Controls Bottom Bar: Prev, Flip, Next, Shuffle
              CustomCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      tooltip: 'Previous Card',
                      onPressed: _currentIndex > 0 ? _prevPage : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.flip),
                      tooltip: 'Flip Card',
                      onPressed: _flipCurrentCard,
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      tooltip: 'Next Card',
                      onPressed: _currentIndex < _sessionCards.length - 1 ? _nextPage : null,
                    ),
                    IconButton(
                      icon: Icon(_isShuffled ? Icons.shuffle_on_outlined : Icons.shuffle),
                      tooltip: 'Shuffle Deck',
                      color: _isShuffled ? theme.colorScheme.primary : null,
                      onPressed: _toggleShuffle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardFace({
    required BuildContext context,
    required String title,
    required String content,
    required Color cardColor,
    BorderSide? borderSide,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
        border: borderSide ??
            Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1.5,
            ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.slate.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SingleChildScrollView(
                child: Text(
                  content,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Tap card to flip',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
