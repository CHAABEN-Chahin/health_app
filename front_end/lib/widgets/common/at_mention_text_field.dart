import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';
import '../../models/user.dart';

/// A text field that supports @ mentions with autocomplete
class AtMentionTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onSubmitted;
  final int? maxLines;
  final List<User> availableUsers;
  final Function(User)? onUserMentioned;

  const AtMentionTextField({
    Key? key,
    required this.controller,
    this.hintText = 'Type a message...',
    this.onSubmitted,
    this.maxLines,
    this.availableUsers = const [],
    this.onUserMentioned,
  }) : super(key: key);

  @override
  State<AtMentionTextField> createState() => _AtMentionTextFieldState();
}

class _AtMentionTextFieldState extends State<AtMentionTextField> {
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<User> _filteredUsers = [];
  String _currentMentionQuery = '';
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final cursorPosition = widget.controller.selection.baseOffset;

    if (cursorPosition < 0) return;

    // Find if there's an @ before the cursor
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex != -1) {
      // Check if there's a space between @ and cursor
      final textAfterAt = textBeforeCursor.substring(lastAtIndex + 1);
      if (!textAfterAt.contains(' ') && !textAfterAt.contains('\n')) {
        // We're in a mention
        _currentMentionQuery = textAfterAt.toLowerCase();
        _filterUsers();
        if (_filteredUsers.isNotEmpty) {
          _showSuggestionOverlay();
        } else {
          _removeOverlay();
        }
        return;
      }
    }

    // Not in a mention, hide overlay
    _removeOverlay();
  }

  void _filterUsers() {
    if (_currentMentionQuery.isEmpty) {
      _filteredUsers = widget.availableUsers.take(5).toList();
    } else {
      _filteredUsers = widget.availableUsers
          .where((user) =>
              user.username.toLowerCase().contains(_currentMentionQuery) ||
              (user.fullName?.toLowerCase().contains(_currentMentionQuery) ??
                  false))
          .take(5)
          .toList();
    }
  }

  void _showSuggestionOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
      return;
    }

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _showSuggestions = false;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, -(_filteredUsers.length * 60.0) - 10),
          child: Material(
            elevation: 8,
            color: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppColors.secondaryDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.purplePrimary.withOpacity(0.3),
                ),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return _buildUserSuggestion(user);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSuggestion(User user) {
    return InkWell(
      onTap: () => _selectUser(user),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.mediumGray.withOpacity(0.1),
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: Center(
                child: Text(
                  user.username.substring(0, 1).toUpperCase(),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@${user.username}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.pinkPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (user.fullName != null)
                    Text(
                      user.fullName!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.mediumGray,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectUser(User user) {
    final text = widget.controller.text;
    final cursorPosition = widget.controller.selection.baseOffset;
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastAtIndex = textBeforeCursor.lastIndexOf('@');

    if (lastAtIndex != -1) {
      final textBeforeAt = text.substring(0, lastAtIndex);
      final textAfterCursor = text.substring(cursorPosition);
      final newText = '$textBeforeAt@${user.username} $textAfterCursor';

      widget.controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: lastAtIndex + user.username.length + 2,
        ),
      );

      widget.onUserMentioned?.call(user);
    }

    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.mediumGray,
          ),
          border: InputBorder.none,
        ),
        maxLines: widget.maxLines,
        textInputAction: TextInputAction.send,
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
