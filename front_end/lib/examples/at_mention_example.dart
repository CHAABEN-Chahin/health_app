import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/text_styles.dart';
import '../models/user.dart';
import '../widgets/common/at_mention_text_field.dart';

/// Example screen demonstrating the @ mention text field functionality
/// This can be used for testing and as a reference implementation
class AtMentionExample extends StatefulWidget {
  const AtMentionExample({Key? key}) : super(key: key);

  @override
  State<AtMentionExample> createState() => _AtMentionExampleState();
}

class _AtMentionExampleState extends State<AtMentionExample> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _mentionedUsers = [];
  final List<String> _messages = [];

  final List<User> _exampleUsers = [
    User(
      id: '1',
      username: 'john_doe',
      email: 'john@example.com',
      fullName: 'John Doe',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
    User(
      id: '2',
      username: 'jane_smith',
      email: 'jane@example.com',
      fullName: 'Jane Smith',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    setState(() {
      _messages.add(_controller.text);
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryDark,
        title: const Text('@ Mention Example'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.secondaryDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Type @ to mention users',
              style: AppTextStyles.bodyMedium,
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryDark,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _messages[index],
                    style: AppTextStyles.bodyMedium,
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryDark,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: AtMentionTextField(
                      controller: _controller,
                      hintText: 'Type @ to mention...',
                      availableUsers: _exampleUsers,
                      onSubmitted: (_) => _sendMessage(),
                      onUserMentioned: (user) {
                        debugPrint('Mentioned: @${user.username}');
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
