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
  late TextEditingController _frontController;
  late TextEditingController _backController;
  
  // Category autocomplete sync controller
  TextEditingController? _categoryController;
  String _categoryValue = '';

  int _box = 1;
  bool _isFavorite = false;

  bool get _isEditing => widget.card != null;

  @override
  void initState() {
    super.initState();
    _frontController = TextEditingController(text: widget.card?.front ?? '');
    _backController = TextEditingController(text: widget.card?.back ?? '');
    _categoryValue = widget.card?.category ?? '';
    _box = widget.card?.box ?? 1;
    _isFavorite = widget.card?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    super.dispose();
  }

  void _saveCard() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<FlashcardProvider>(context, listen: false);

      final frontText = _frontController.text.trim();
      final backText = _backController.text.trim();
      
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
          front: frontText,
          back: backText,
          category: categoryText,
          box: _box,
          isFavorite: _isFavorite,
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
          frontText,
          backText,
          categoryText,
          box: _box,
          isFavorite: _isFavorite,
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
            icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
            color: _isFavorite ? Colors.amber : null,
            onPressed: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
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
                // Front Input
                TextFormField(
                  controller: _frontController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Front Side (Question/Term)',
                    hintText: 'e.g. What is polymorphism?',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter front side text' : null,
                ),
                const SizedBox(height: 16),

                // Back Input
                TextFormField(
                  controller: _backController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Back Side (Answer/Definition)',
                    hintText: 'e.g. The ability of an object to take on many forms...',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Please enter back side text' : null,
                ),
                const SizedBox(height: 16),

                // Category Autocomplete
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _categoryValue),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
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
                        hintText: 'e.g. Computer Science, Spanish',
                        suffixIcon: const Icon(Icons.arrow_drop_down),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter or select a deck category' : null,
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Difficulty Rating Label
                Text(
                  'Leitner Box level (Difficulty / Spacing offset)',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cards in higher boxes are scheduled for review less frequently.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Material 3 Segmented Button
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment<int>(value: 1, label: Text('Box 1'), tooltip: 'New / Hardest (1 day offset)'),
                    ButtonSegment<int>(value: 2, label: Text('2')),
                    ButtonSegment<int>(value: 3, label: Text('3')),
                    ButtonSegment<int>(value: 4, label: Text('4')),
                    ButtonSegment<int>(value: 5, label: Text('Box 5'), tooltip: 'Mastered / Easiest (30 days offset)'),
                  ],
                  selected: {_box},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      _box = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 40),

                // Bottom Action buttons
                CustomButton(
                  text: _isEditing ? 'Save Changes' : 'Create Flashcard',
                  icon: Icons.check,
                  onPressed: _saveCard,
                ),
                
                if (_isEditing) ...[
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Delete Card',
                    isPrimary: false,
                    textColor: AppColors.error,
                    icon: Icons.delete_outline,
                    onPressed: _deleteCard,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
