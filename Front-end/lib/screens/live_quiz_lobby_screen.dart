import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../utils/app_router.dart';

class LiveQuizLobbyScreen extends StatefulWidget {
  const LiveQuizLobbyScreen({Key? key}) : super(key: key);

  @override
  State<LiveQuizLobbyScreen> createState() => _LiveQuizLobbyScreenState();
}

class _LiveQuizLobbyScreenState extends State<LiveQuizLobbyScreen> {
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if quiz has started, and auto-navigate to Play screen
    final provider = Provider.of<FlashcardProvider>(context);
    final state = provider.quizState;
    if (state != null && state['status'] == 'active' && !_navigated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRouter.liveQuizPlay);
      });
    }
  }

  Future<void> _handleStart() async {
    final provider = Provider.of<FlashcardProvider>(context, listen: false);
    try {
      await provider.startLiveQuiz();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleExit() async {
    final provider = Provider.of<FlashcardProvider>(context, listen: false);
    await provider.endLiveQuiz();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<FlashcardProvider>(context);
    final state = provider.quizState;
    final isHost = provider.isQuizHost;

    if (state == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Connecting to quiz server...', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Cancel',
                onPressed: () => Navigator.of(context).pop(),
                backgroundColor: AppColors.error,
              )
            ],
          ),
        ),
      );
    }

    final students = state['students'] as List? ?? [];
    final category = state['category'] as String? ?? 'All Decks';
    final totalQuestions = state['totalQuestions'] as int? ?? 0;
    
    // Calculate Join URL
    String joinUrl = provider.serverUrl;
    if (provider.hostIp.isNotEmpty && joinUrl.contains('localhost')) {
      joinUrl = joinUrl.replaceAll('localhost', provider.hostIp);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isHost ? 'Quiz Organizer Lobby' : 'Quiz Waiting Room'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Header
                CustomCard(
                  backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  child: Column(
                    children: [
                      const Icon(Icons.group_outlined, size: 48, color: AppColors.primary),
                      const SizedBox(height: 12),
                      Text(
                        isHost ? 'Share this Address to Join' : 'Waiting for Host to Start...',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        joinUrl,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Divider(color: theme.dividerColor),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHeaderStat('Deck', category, theme),
                          _buildHeaderStat('Questions', '$totalQuestions cards', theme),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Connected Students list
                Text(
                  'Connected Participants (${students.length})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                students.isEmpty
                    ? CustomCard(
                        padding: const EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            isHost ? 'Waiting for students to connect...' : 'You are the first to join!',
                            style: TextStyle(color: theme.hintColor),
                          ),
                        ),
                      )
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: 60,
                        ),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final nickname = student['nickname'] as String? ?? 'Student';
                          final isMe = nickname == provider.studentNickname;

                          return CustomCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            backgroundColor: isMe ? AppColors.primary.withOpacity(0.1) : null,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isMe ? AppColors.primary : theme.disabledColor,
                                  child: Text(
                                    nickname.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    nickname + (isMe ? ' (You)' : ''),
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                                      color: isMe ? AppColors.primary : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 30),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: isHost ? 'Cancel Session' : 'Leave Quiz',
                        onPressed: _handleExit,
                        backgroundColor: isHost ? theme.disabledColor : AppColors.error,
                      ),
                    ),
                    if (isHost) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: CustomButton(
                          text: 'Start Quiz',
                          onPressed: students.isEmpty ? null : _handleStart,
                          backgroundColor: AppColors.success,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat(String title, String value, ThemeData theme) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: theme.hintColor, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}
