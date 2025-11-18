import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/user.dart';
import '../../widgets/common/at_mention_text_field.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late List<User> _availableUsers;

  @override
  void initState() {
    super.initState();
    // Initialize mock users for mention feature
    _availableUsers = _getMockUsers();
    
    // Add welcome message
    _messages.add(ChatMessage(
      text: "Hello! I'm your health assistant. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }
  
  List<User> _getMockUsers() {
    return [
      User(
        id: 'user_1',
        username: 'dr_smith',
        email: 'smith@health.com',
        fullName: 'Dr. Sarah Smith',
        createdAt: DateTime.now(),
      ),
      User(
        id: 'user_2',
        username: 'coach_mike',
        email: 'mike@health.com',
        fullName: 'Coach Mike Johnson',
        createdAt: DateTime.now(),
      ),
      User(
        id: 'user_3',
        username: 'nutritionist_emma',
        email: 'emma@health.com',
        fullName: 'Nutritionist Emma Wilson',
        createdAt: DateTime.now(),
      ),
      User(
        id: 'user_4',
        username: 'trainer_alex',
        email: 'alex@health.com',
        fullName: 'Trainer Alex Rodriguez',
        createdAt: DateTime.now(),
      ),
      User(
        id: 'user_5',
        username: 'physio_lisa',
        email: 'lisa@health.com',
        fullName: 'Physiotherapist Lisa Chen',
        createdAt: DateTime.now(),
      ),
    ];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _messageController.clear();
      _isTyping = true;
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });

    // Simulate bot response (will be replaced with API call)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: "I understand you said: \"$text\". API integration coming soon!",
            isUser: false,
            timestamp: DateTime.now(),
          ));
          _isTyping = false;
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Health Assistant', style: AppTextStyles.header3.copyWith(fontSize: 16)),
                Text(
                  'AI-Powered Chat',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.successGreen,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              _showOptionsMenu();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),
          
          // Typing indicator
          if (_isTyping) _buildTypingIndicator(),
          
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Start a Conversation',
            style: AppTextStyles.header3,
          ),
          const SizedBox(height: 12),
          Text(
            'Ask me anything about your health,\nfitness, or nutrition!',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.mediumGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: message.isUser
                        ? AppColors.primaryGradient
                        : null,
                    color: message.isUser ? null : AppColors.secondaryDark,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 16),
                    ),
                    border: message.isUser
                        ? null
                        : Border.all(
                            color: AppColors.purplePrimary.withOpacity(0.3),
                          ),
                  ),
                  child: _buildMessageText(message.text),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.mediumGray,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.pinkPrimary.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.pinkPrimary),
              ),
              child: const Icon(Icons.person, color: AppColors.pinkPrimary, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondaryDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        final delay = index * 0.2;
        final animValue = ((value - delay) * 2).clamp(0.0, 1.0);
        final opacity = (animValue < 0.5)
            ? animValue * 2
            : 2 - (animValue * 2);
        
        return Opacity(
          opacity: opacity.clamp(0.3, 1.0),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.pinkPrimary,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        if (mounted && _isTyping) {
          setState(() {}); // Trigger rebuild to restart animation
        }
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondaryDark,
        border: Border(
          top: BorderSide(
            color: AppColors.mediumGray.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.purplePrimary),
              onPressed: () {
                _showAttachmentOptions();
              },
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.mediumGray.withOpacity(0.3),
                  ),
                ),
                child: AtMentionTextField(
                  controller: _messageController,
                  hintText: 'Type a message... (use @ to mention)',
                  availableUsers: _availableUsers,
                  maxLines: null,
                  onSubmitted: (_) => _sendMessage(),
                  onUserMentioned: (user) {
                    debugPrint('Mentioned user: @${user.username}');
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share', style: AppTextStyles.header3),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: AppColors.purplePrimary,
                  onTap: () => Navigator.pop(context),
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: AppColors.pinkPrimary,
                  onTap: () => Navigator.pop(context),
                ),
                _buildAttachmentOption(
                  icon: Icons.description,
                  label: 'Document',
                  color: AppColors.infoBlue,
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.mediumGray),
          ),
        ],
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.emergencyRed),
              title: Text('Clear Chat', style: AppTextStyles.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                _clearChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: AppColors.infoBlue),
              title: Text('About Assistant', style: AppTextStyles.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _messages.add(ChatMessage(
        text: "Chat cleared. How can I help you?",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryDark,
        title: Text('About Health Assistant', style: AppTextStyles.header3),
        content: Text(
          'Your AI-powered health companion. Get personalized advice on fitness, nutrition, and wellness.\n\nAPI integration coming soon!',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.pinkPrimary)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildMessageText(String text) {
    final List<TextSpan> spans = [];
    final mentionRegex = RegExp(r'@(\w+)');
    int lastMatchEnd = 0;

    for (final match in mentionRegex.allMatches(text)) {
      // Add text before mention
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
          ),
        ));
      }

      // Add mention with special styling
      spans.add(TextSpan(
        text: match.group(0),
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.pinkPrimary,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
      ));

      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans.isEmpty 
        ? [TextSpan(
            text: text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white,
            ),
          )]
        : spans),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
