import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../providers/flashcard_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLarge)),
          title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const SingleChildScrollView(
            child: Text(
              'Your privacy is important to us. Flashcard Quiz App stores all your flashcards, scores, and activity history directly on your local device using SQLite and SharedPreferences. No personal data is collected, uploaded, or shared with third parties.\n\n'
              'Local Storage Permissions:\n'
              'This application utilizes internal database storage and does not require active internet connections or network permissions to function.\n\n'
              'Changes to this Policy:\n'
              'We reserve the right to modify this policy at any time. Updates are effective immediately upon app installation updates.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLarge)),
          title: const Text('About Flashcard Quiz App', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const SingleChildScrollView(
            child: Text(
              'Flashcard Quiz App is a production-quality local spaced study companion. It allows students to manage dynamic study decks, customize cards with varying difficulties, search queries, star favorites, track daily progress logs, and test their knowledge with swipe gesture page cards.\n\n'
              'Developed using Clean Architecture principles, SOLID practices, and Google Material 3 Design.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _resetDatabase(BuildContext context, FlashcardProvider provider) {
    CustomDialog.showConfirmation(
      context: context,
      title: 'Reset Database',
      message: 'Are you sure you want to reset the database? This action will permanently erase all custom flashcards and reset default study decks. This cannot be undone.',
      confirmLabel: 'Reset',
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed == true) {
        provider.resetDatabase().then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Database reset successfully with default study decks!'),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final flashcardProvider = Provider.of<FlashcardProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          children: [
            // About App Header Card
            CustomCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primary,
                    radius: 28,
                    child: const Icon(Icons.style, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Flashcard Quiz App',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A professional study portfolio application built with Material 3.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Theme Settings
            Text(
              'Appearance',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Enable dark color theme palette'),
                    value: themeProvider.isDarkMode,
                    onChanged: (bool value) {
                      themeProvider.toggleTheme(value);
                    },
                    secondary: const Icon(Icons.dark_mode_outlined),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Database Actions
            Text(
              'Data Management',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.restore, color: AppColors.error),
                    title: const Text('Reset Database', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error)),
                    subtitle: const Text('Erase custom data and restore default category decks'),
                    onTap: () => _resetDatabase(context, flashcardProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App Information
            Text(
              'Information',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About App', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showAboutDialog(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showPrivacyPolicy(context),
                  ),
                  const Divider(height: 1, indent: 56),
                  const ListTile(
                    leading: Icon(Icons.label_outline),
                    title: Text('Version', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: Text('1.0.0', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
