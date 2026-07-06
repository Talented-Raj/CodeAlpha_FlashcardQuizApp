import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../providers/auth_provider.dart';
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
              'Your privacy is important to us. Memora stores all your flashcards, scores, and activity history directly on your local device using SQLite and SharedPreferences. No personal data is collected, uploaded, or shared with third parties.\n\n'
              'Local Storage Permissions:\n'
              'Memora utilizes internal database storage and does not require active internet connections or network permissions to function.\n\n'
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

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLarge)),
          title: const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const SingleChildScrollView(
            child: Text(
              'Welcome to Memora. By using this application, you agree to these terms:\n\n'
              '1. Personal Use:\n'
              'Memora is built as a learning and spaced-repetition tool for personal study portfolios.\n\n'
              '2. Data Loss Disclaimer:\n'
              'All study records are saved locally. Clearing app cache, resetting data, or uninstalling Memora will permanently erase your flashcards and study logs. We do not provide cloud recoveries.\n\n'
              '3. Modification of Services:\n'
              'Features are subject to changes in future updates.',
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

  void _showRateAppDialog(BuildContext context) {
    int rating = 5;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLarge)),
              title: const Text('Rate Memora', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('How would you rate your learning experience with Memora?'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      return IconButton(
                        icon: Icon(
                          starIndex <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        tooltip: 'Rate $starIndex stars',
                        onPressed: () {
                          setState(() {
                            rating = starIndex;
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Thank you for rating us $rating stars!'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLarge)),
          title: const Text('Send Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Tell us how we can improve...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thank you! Your feedback has been simulated.'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Send'),
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
      message: 'Are you sure you want to reset the database? This action will permanently erase all flashcards and logs. This cannot be undone.',
      confirmLabel: 'Reset',
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed == true) {
        provider.resetDatabase().then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All local tables and study logs cleared.'),
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
    final authProvider = Provider.of<AuthProvider>(context);
    final flashcardProvider = Provider.of<FlashcardProvider>(context);

    final username = authProvider.user?.name ?? 'Student';

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
                  const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    radius: 28,
                    child: Icon(Icons.style, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Clean Leitner Flashcards study application built in Flutter.',
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

            // Profile Section
            Text(
              'Profile',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Card(
              margin: const EdgeInsets.only(top: 8, bottom: 20),
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Username'),
                subtitle: Text(username),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () {
                  CustomDialog.showInputDialog(
                    context: context,
                    title: 'Update Username',
                    hintText: 'Enter username',
                    initialValue: username,
                  ).then((name) {
                    if (name != null && name.trim().isNotEmpty) {
                      authProvider.completeOnboarding(
                        name: name.trim(),
                        email: authProvider.user?.email ?? '',
                        currency: authProvider.user?.currency ?? '\$',
                        monthlyBudget: authProvider.user?.monthlyBudget ?? 1000.0,
                      );
                    }
                  });
                },
              ),
            ),

            // Appearance Section
            Text(
              'Appearance',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Card(
              margin: const EdgeInsets.only(top: 8, bottom: 20),
              child: SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Mode'),
                value: themeProvider.isDarkMode,
                onChanged: (_) {
                  themeProvider.toggleTheme();
                },
              ),
            ),

            // Storage Section
            Text(
              'Data Management',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Card(
              margin: const EdgeInsets.only(top: 8, bottom: 20),
              child: ListTile(
                leading: const Icon(Icons.delete_forever_outlined, color: AppColors.error),
                title: const Text('Reset Database', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                subtitle: const Text('Wipes all flashcards and study logs'),
                onTap: () => _resetDatabase(context, flashcardProvider),
              ),
            ),

            // Feedback & Actions
            Text(
              'Feedback & Support',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Card(
              margin: const EdgeInsets.only(top: 8, bottom: 20),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.star_rate_outlined),
                    title: const Text('Rate App'),
                    onTap: () => _showRateAppDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.feedback_outlined),
                    title: const Text('Submit Feedback'),
                    onTap: () => _showFeedbackDialog(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.code_outlined),
                    title: const Text('GitHub Repository'),
                    subtitle: const Text('Open source placeholder link'),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('GitHub link: https://github.com/placeholder/memora'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Legals & Information
            Text(
              'Legal & Info',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Card(
              margin: const EdgeInsets.only(top: 8, bottom: 24),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy Policy'),
                    onTap: () => _showPrivacyPolicy(context),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Terms of Service'),
                    onTap: () => _showTermsOfService(context),
                  ),
                ],
              ),
            ),

            // Footer Version Info
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  children: [
                    Text(
                      'Memora Flashcards',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Version 1.0.0',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
