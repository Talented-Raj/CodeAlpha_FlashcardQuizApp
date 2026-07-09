import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';

class LiveQuizPlayScreen extends StatefulWidget {
  const LiveQuizPlayScreen({Key? key}) : super(key: key);

  @override
  State<LiveQuizPlayScreen> createState() => _LiveQuizPlayScreenState();
}

class _LiveQuizPlayScreenState extends State<LiveQuizPlayScreen> {
  int _lastQuestionIndex = -1;
  String? _selectedOption;
  bool _answered = false;
  bool? _isCorrect;
  bool _revealAnswer = false;

  void _resetForNextQuestion(int index) {
    _lastQuestionIndex = index;
    _selectedOption = null;
    _answered = false;
    _isCorrect = null;
    _revealAnswer = false;
  }

  Future<void> _handleOptionSelected(String option) async {
    if (_revealAnswer) return;

    setState(() {
      _selectedOption = option;
      _answered = true;
    });

    final provider = Provider.of<FlashcardProvider>(context, listen: false);
    try {
      await provider.submitLiveAnswer(option);
      final currentQuestion = provider.quizState?['currentQuestion'];
      final correctAnswer = currentQuestion?['correctAnswer'] as String?;
      setState(() {
        _isCorrect = correctAnswer == option;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit answer: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleNextQuestion() async {
    final provider = Provider.of<FlashcardProvider>(context, listen: false);
    try {
      await provider.nextLiveQuestion();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to advance: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleEndQuiz() async {
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
              const Text('Quiz Syncing...', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    // Final standings screen when quiz has ended
    if (state['status'] == 'ended' || state['status'] == 'idle') {
      final students = state['students'] as List? ?? [];
      final sortedStudents = List.from(students);
      sortedStudents.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz Finished!'),
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
                  CustomCard(
                    backgroundColor: AppColors.primary.withOpacity(0.08),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
                        const SizedBox(height: 16),
                        Text(
                          '🏆 Live Quiz Finished! 🏆',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Here are the final standings of all participants.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Final Standings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sortedStudents.length,
                          itemBuilder: (context, index) {
                            final student = sortedStudents[index];
                            final nickname = student['nickname'] as String? ?? '';
                            final score = student['score'] as int? ?? 0;
                            final isMe = nickname == provider.studentNickname;

                            return ListTile(
                              leading: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              title: Text(
                                nickname + (isMe ? ' (You)' : ''),
                                style: TextStyle(
                                  fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                                  color: isMe ? AppColors.primary : null,
                                ),
                              ),
                              trailing: Text('$score pts', style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  CustomButton(
                    text: isHost ? 'End Session & Exit' : 'Exit to Home',
                    onPressed: () async {
                      await provider.endLiveQuiz();
                      if (mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    backgroundColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final currentIndex = state['currentQuestionIndex'] as int? ?? 0;
    if (currentIndex != _lastQuestionIndex) {
      _resetForNextQuestion(currentIndex);
    }

    final totalQuestions = state['totalQuestions'] as int? ?? 0;
    final timeLeft = state['timeLeft'] as int? ?? 0;
    final students = state['students'] as List? ?? [];
    final currentQuestion = state['currentQuestion'];
    
    // Auto-reveal if timer hits zero
    if (timeLeft == 0 && !_revealAnswer && state['status'] == 'active') {
      _revealAnswer = true;
    }

    // Rank students by score
    final sortedStudents = List.from(students);
    sortedStudents.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${currentIndex + 1} of $totalQuestions'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Exit Quiz'),
                  content: Text(isHost ? 'Do you want to end the quiz for all students?' : 'Do you want to leave this quiz?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleEndQuiz();
                      },
                      child: const Text('Exit', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timer and Stats
                Row(
                  children: [
                    Expanded(
                      child: CustomCard(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.timer_outlined, color: timeLeft < 5 ? AppColors.error : AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              timeLeft > 0 ? '$timeLeft seconds left' : 'Time Up!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: timeLeft < 5 ? AppColors.error : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomCard(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_alt_outlined, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Answered: ${state['answersSubmittedCount']} / ${students.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (currentQuestion == null)
                  const CustomCard(
                    padding: EdgeInsets.all(40),
                    child: Center(child: Text('Waiting for question details...')),
                  )
                else ...[
                  // Question Box
                  CustomCard(
                    backgroundColor: theme.cardColor,
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${currentQuestion['category']} • ${currentQuestion['difficulty']}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentQuestion['question'] as String? ?? '',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (isHost) ...[
                    // HOST VIEW: Dashboard
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Host Control Panel', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 16),
                          if (!_revealAnswer) ...[
                            CustomButton(
                              text: 'Reveal Correct Answer Now',
                              onPressed: () {
                                setState(() {
                                  _revealAnswer = true;
                                });
                              },
                              backgroundColor: AppColors.warning,
                            ),
                          ] else ...[
                            Text(
                              'Correct Answer: ${currentQuestion['correctAnswer']}',
                              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            CustomButton(
                              text: currentIndex + 1 < totalQuestions ? 'Next Question' : 'View Final Leaderboard & End',
                              onPressed: _handleNextQuestion,
                              backgroundColor: AppColors.success,
                            ),
                          ],
                          const SizedBox(height: 12),
                          CustomButton(
                            text: 'End Quiz Session (Force Finish)',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('End Quiz Session'),
                                  content: const Text('Are you sure you want to end the quiz now? Students will see the final leaderboard immediately.'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _handleEndQuiz();
                                      },
                                      child: const Text('End Quiz', style: TextStyle(color: AppColors.error)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            backgroundColor: Colors.transparent,
                            textColor: AppColors.error,
                            isPrimary: false,
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // STUDENT VIEW: Choices
                    if (!_revealAnswer) ...[
                      // Choices grid
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: (currentQuestion['options'] as List? ?? []).length,
                        itemBuilder: (context, index) {
                          final option = currentQuestion['options'][index] as String;
                          final isSelected = _selectedOption == option;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: _revealAnswer ? null : () => _handleOptionSelected(option),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : theme.dividerColor,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  color: isSelected ? AppColors.primary.withOpacity(0.05) : theme.cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.primary : null,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (_answered)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Text(
                              'Answer submitted. You can change your choice until time runs out.',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            ),
                          ),
                        ),
                    ] else ...[
                      // Display Answer Result
                      CustomCard(
                        backgroundColor: _isCorrect == true
                            ? AppColors.success.withOpacity(0.1)
                            : (_selectedOption == null
                                ? theme.disabledColor.withOpacity(0.1)
                                : AppColors.error.withOpacity(0.1)),
                        child: Column(
                          children: [
                            Icon(
                              _isCorrect == true
                                  ? Icons.check_circle_outline
                                  : (_selectedOption == null
                                      ? Icons.timer_off_outlined
                                      : Icons.cancel_outlined),
                              color: _isCorrect == true
                                  ? AppColors.success
                                  : (_selectedOption == null
                                      ? theme.disabledColor
                                      : AppColors.error),
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isCorrect == true
                                  ? 'Correct Answer!'
                                  : (_selectedOption == null
                                      ? 'Time ran out!'
                                      : 'Wrong Answer!'),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _isCorrect == true
                                    ? AppColors.success
                                    : (_selectedOption == null
                                        ? theme.disabledColor
                                        : AppColors.error),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Correct Answer: ${currentQuestion['correctAnswer']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (_selectedOption != null && _isCorrect == false) ...[
                              const SizedBox(height: 4),
                              Text('Your Answer: $_selectedOption', style: TextStyle(color: theme.hintColor)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 24),

                  // Leaderboard section
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Leaderboard', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: sortedStudents.length,
                          itemBuilder: (context, index) {
                            final student = sortedStudents[index];
                            final nickname = student['nickname'] as String? ?? '';
                            final score = student['score'] as int? ?? 0;
                            final isCorrect = student['answeredCorrectly'] as bool? ?? false;
                            
                            final isMe = nickname == provider.studentNickname;

                            return ListTile(
                              leading: Text('#${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              title: Text(
                                nickname + (isMe ? ' (You)' : ''),
                                style: TextStyle(
                                  fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                                  color: isMe ? AppColors.primary : null,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_revealAnswer) ...[
                                    Icon(
                                      isCorrect ? Icons.check_circle : Icons.cancel,
                                      color: isCorrect ? AppColors.success : AppColors.error,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text('$score pts', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
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
