import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../models/flashcard_model.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_dialog.dart';

class AddEditCardScreen extends StatefulWidget {
  final FlashcardModel? card;

  const AddEditCardScreen({Key? key, this.card}) : super(key: key);

  @override
  State<AddEditCardScreen> createState() => _AddEditCardScreenState();
}

class _AddEditCardScreenState extends State<AddEditCardScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionController;
  late TextEditingController _answerController;
  
  // Category autocomplete synced controller
  TextEditingController? _categoryController;
  String _categoryValue = '';

  String _difficulty = 'Medium'; // "Easy", "Medium", "Hard"
  bool _favorite = false;

  bool get _isEditing => widget.card != null;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.card?.question ?? '');
    _answerController = TextEditingController(text: widget.card?.answer ?? '');
    _categoryValue = widget.card?.category ?? '';
    _difficulty = widget.card?.difficulty ?? 'Medium';
    _favorite = widget.card?.favorite ?? false;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _saveCard() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FlashcardProvider>(context, listen: false);

      final questionText = _questionController.text.trim();
      final answerText = _answerController.text.trim();
      
      // Extract category from autocomplete controller or fallback
      final categoryText = (_categoryController != null && _categoryController!.text.trim().isNotEmpty)
          ? _categoryController!.text.trim()
          : _categoryValue.trim();

      if (categoryText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select or write a category!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      if (_isEditing) {
        final updatedCard = widget.card!.copyWith(
          question: questionText,
          answer: answerText,
          category: categoryText,
          difficulty: _difficulty,
          favorite: _favorite,
          updatedAt: DateTime.now(),
        );
        provider.updateFlashcard(updatedCard).then((_) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Flashcard updated successfully!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
        });
      } else {
        provider.addFlashcard(
          questionText,
          answerText,
          categoryText,
          _difficulty,
          favorite: _favorite,
        ).then((_) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New Flashcard created!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
        });
      }
    }
  }

  void _deleteCard() {
    if (!_isEditing) return;

    CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Flashcard',
      message: 'Are you sure you want to permanently delete this card? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed == true && widget.card!.id != null) {
        Provider.of<FlashcardProvider>(context, listen: false)
            .deleteFlashcard(widget.card!.id!)
            .then((_) {
          Navigator.pop(context); // Close edit screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Flashcard deleted successfully.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final provider = Provider.of<FlashcardProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Flashcard' : 'Add Flashcard'),
        actions: [
          IconButton(
            icon: Icon(_favorite ? Icons.star : Icons.star_border),
            color: _favorite ? Colors.amber : null,
            tooltip: _favorite ? 'Starred' : 'Star Flashcard',
            onPressed: () {
              setState(() {
                _favorite = !_favorite;
              });
            },
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              tooltip: 'Delete Card',
              onPressed: _deleteCard,
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Question Input
                TextFormField(
                  controller: _questionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Question text',
                    hintText: 'e.g. What is polymorphism?',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Question cannot be empty' : null,
                ),
                const SizedBox(height: 16),

                // Answer Input
                TextFormField(
                  controller: _answerController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Answer text',
                    hintText: 'e.g. The ability of an object to take on many forms...',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Answer cannot be empty' : null,
                ),
                const SizedBox(height: 16),

                // Category Autocomplete
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _categoryValue),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return provider.categories;
                    }
                    return provider.categories.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    _categoryValue = selection;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    _categoryController = controller;
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Deck / Category',
                        hintText: 'e.g. Programming, Mathematics, Science',
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter or select a deck category' : null,
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Difficulty Rating Label
                Text(
                  'Card Difficulty',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // Material 3 Segmented Button
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(value: 'Easy', label: Text('Easy')),
                    ButtonSegment<String>(value: 'Medium', label: Text('Medium')),
                    ButtonSegment<String>(value: 'Hard', label: Text('Hard')),
                  ],
                  selected: {_difficulty},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _difficulty = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Favorite Toggle
                SwitchListTile(
                  title: const Text('Mark as Favorite', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Starred cards appear in the Favorites section'),
                  value: _favorite,
                  onChanged: (bool value) {
                    setState(() {
                      _favorite = value;
                    });
                  },
                  secondary: Icon(
                    _favorite ? Icons.star : Icons.star_border,
                    color: _favorite ? Colors.amber : null,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save Action Button
                CustomButton(
                  text: _isEditing ? 'Update Flashcard' : 'Save Flashcard',
                  icon: Icons.check,
                  onPressed: _saveCard,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
