# @ Mention Wrapper Feature

## Overview
This document describes the @ mention wrapper feature implemented for the HealthTrack Wearable app's chat interface.

## Implementation

### Files Added
- `lib/widgets/common/at_mention_text_field.dart` - The main @ mention text field widget

### Files Modified
- `lib/screens/chat/chat_screen.dart` - Updated to use the @ mention text field

## Features

### 1. **@ Mention Detection**
- Automatically detects when a user types "@" in the chat input
- Shows a suggestion overlay above the text field

### 2. **User Suggestions**
- Displays a list of available users to mention
- Filters suggestions in real-time based on text after "@"
- Matches against both username and full name
- Shows up to 5 matching users at a time

### 3. **User Selection**
- Click/tap on a user from the suggestion list to select
- Automatically inserts "@username " (with space) at the correct position
- Maintains cursor position after insertion
- Closes suggestion overlay after selection

### 4. **Multiple Mentions**
- Supports multiple @ mentions in a single message
- Each mention can be added independently

### 5. **Visual Styling**
- **Suggestion Overlay:**
  - Dark theme consistent with app design
  - Purple border matching app accent colors
  - User avatars with gradient backgrounds
  - Username displayed in pink
  - Full name displayed in gray

- **Chat Messages:**
  - @ mentions highlighted in pink color
  - Bold font weight for mentions
  - Mentions parsed using regex in displayed messages

## Usage

### Basic Usage
```dart
AtMentionTextField(
  controller: _messageController,
  hintText: 'Type a message... (use @ to mention)',
  availableUsers: _availableUsers,
  maxLines: null,
  onSubmitted: (_) => _sendMessage(),
  onUserMentioned: (user) {
    debugPrint('Mentioned user: @${user.username}');
  },
)
```

### Parameters

| Parameter | Type | Description | Required |
|-----------|------|-------------|----------|
| `controller` | `TextEditingController` | Controls the text being edited | Yes |
| `hintText` | `String` | Placeholder text | No (default: "Type a message...") |
| `availableUsers` | `List<User>` | List of users that can be mentioned | No (default: empty list) |
| `maxLines` | `int?` | Maximum lines for text field | No |
| `onSubmitted` | `Function(String)?` | Callback when text is submitted | No |
| `onUserMentioned` | `Function(User)?` | Callback when a user is mentioned | No |

## Mock Users

The chat screen includes 5 mock users for demonstration:
1. **@dr_smith** - Dr. Sarah Smith
2. **@coach_mike** - Coach Mike Johnson
3. **@nutritionist_emma** - Nutritionist Emma Wilson
4. **@trainer_alex** - Trainer Alex Rodriguez
5. **@physio_lisa** - Physiotherapist Lisa Chen

## Technical Details

### Overlay Positioning
- Uses `CompositedTransformTarget` and `CompositedTransformFollower` for precise positioning
- Overlay appears above the text field (not below) to avoid keyboard overlap
- Automatically calculates position based on number of suggestions

### Text Parsing
- Mentions detected using regex pattern: `@(\w+)`
- Real-time filtering as user types after "@"
- Case-insensitive matching

### State Management
- Uses `StatefulWidget` for managing overlay state
- Listens to `TextEditingController` changes
- Cleans up overlay on dispose to prevent memory leaks

## Color Scheme
- **Mention Color:** `AppColors.pinkPrimary` (#FF2E78)
- **Overlay Background:** `AppColors.secondaryDark` (#1A1C2C)
- **Border:** `AppColors.purplePrimary` (#8A5AFF)
- **Avatar Gradient:** `AppColors.primaryGradient`

## Future Enhancements

Possible improvements for future versions:
- [ ] Integration with real user database
- [ ] @channel and @here mentions
- [ ] User profile preview on hover/long-press
- [ ] Notification system for mentioned users
- [ ] Analytics tracking for mentions
- [ ] Mention history and suggestions based on frequent mentions
- [ ] Group mentions (@group_name)
- [ ] Role-based mentions (@doctors, @coaches)

## Testing

### Manual Testing Steps
1. Open the chat screen
2. Type "@" in the message input
3. Verify suggestion overlay appears
4. Type a few characters after "@"
5. Verify suggestions are filtered correctly
6. Select a user from suggestions
7. Verify mention is inserted correctly with space
8. Send the message
9. Verify mention is highlighted in pink in the chat bubble
10. Test multiple mentions in one message

### Edge Cases Handled
- Empty user list - no overlay shown
- No matching users - overlay closes
- Typing space after @ - overlay closes
- Multiple @ in same message - each handled independently
- Cursor position management after insertion

## Dependencies

No additional dependencies required beyond existing project dependencies:
- `flutter/material.dart`
- Existing models and theme files

## Browser/Platform Compatibility

The @ mention feature works on:
- ✅ iOS
- ✅ Android
- ✅ Web
- ✅ Desktop (Windows, macOS, Linux)

Note: On web, ensure keyboard input is properly captured by the text field.
