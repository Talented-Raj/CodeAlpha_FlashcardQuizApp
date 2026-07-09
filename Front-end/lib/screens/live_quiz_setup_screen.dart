import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../providers/flashcard_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_card.dart';
import '../utils/app_router.dart';

class LiveQuizSetupScreen extends StatefulWidget {
  const LiveQuizSetupScreen({Key? key}) : super(key: key);

  @override
  State<LiveQuizSetupScreen> createState() => _LiveQuizSetupScreenState();
}

class _LiveQuizSetupScreenState extends State<LiveQuizSetupScreen> {
  final _serverUrlController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _timeLimitController = TextEditingController(text: '30');

  String _selectedCategory = 'All Decks';
  bool _isHosting = true; // true = Host, false = Join
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<FlashcardProvider>(context, listen: false);
    _serverUrlController.text = provider.serverUrl;
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _nicknameController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final provider = Provider.of<FlashcardProvider>(context, listen: false);
    final serverUrl = _serverUrlController.text.trim();

    if (serverUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Server URL is required')),
      );
      return;
    }

    provider.updateServerUrl(serverUrl);

    setState(() {
      _loading = true;
    });

    try {
      if (_isHosting) {
        final seconds = int.tryParse(_timeLimitController.text) ?? 30;
        await provider.hostQuiz(_selectedCategory, seconds);
        if (mounted) {
          Navigator.of(context).pushNamed(AppRouter.liveQuizLobby);
        }
      } else {
        final nickname = _nicknameController.text.trim();
        if (nickname.isEmpty) {
          throw Exception('Nickname is required to join');
        }
        await provider.joinQuiz(nickname);
        if (mounted) {
          Navigator.of(context).pushNamed(AppRouter.liveQuizLobby);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<FlashcardProvider>(context);

    // Make sure we have Category list
    final categoryList = ['All Decks', ...provider.categories];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Multiplayer Quiz'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mode Switch Toggle
                CustomCard(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Host Quiz (Admin)',
                          onPressed: () => setState(() => _isHosting = true),
                          isPrimary: _isHosting,
                          backgroundColor: _isHosting ? AppColors.primary : Colors.transparent,
                          textColor: _isHosting ? Colors.white : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                      Expanded(
                        child: CustomButton(
                          text: 'Join Quiz (Student)',
                          onPressed: () => setState(() => _isHosting = false),
                          isPrimary: !_isHosting,
                          backgroundColor: !_isHosting ? AppColors.primary : Colors.transparent,
                          textColor: !_isHosting ? Colors.white : theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Form Config Card
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _isHosting ? 'Host Configuration' : 'Student Join Form',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),

                      // Server Address Input
                      const Text(
                        'Server Connection URL',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _serverUrlController,
                        decoration: InputDecoration(
                          hintText: 'e.g., http://localhost:5000',
                          prefixIcon: const Icon(Icons.dns_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_isHosting) ...[
                        // Host fields
                        const Text(
                          'Category / Study Deck',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          borderRadius: BorderRadius.circular(12),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.style_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: categoryList.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategory = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Timer Limit per Question (seconds)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _timeLimitController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'e.g., 30',
                            prefixIcon: const Icon(Icons.timer_outlined),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ] else ...[
                        // Student fields
                        const Text(
                          'Student Nickname',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nicknameController,
                          maxLength: 15,
                          decoration: InputDecoration(
                            hintText: 'Enter your name to play...',
                            prefixIcon: const Icon(Icons.face_outlined),
                            counterText: '',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 30),

                      // Submit button
                      _loading
                          ? const Center(child: CircularProgressIndicator())
                          : CustomButton(
                              text: _isHosting ? 'Host Quiz Lobby' : 'Join Quiz Lobby',
                              onPressed: _handleSubmit,
                              backgroundColor: _isHosting ? AppColors.success : AppColors.primary,
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
