import 'dart:typed_data';

class ChatMatch {
  final String name;
  final String photoUrl;
  final bool isOnline;

  const ChatMatch({
    required this.name,
    required this.photoUrl,
    this.isOnline = false,
  });
}

class ChatConversation {
  final String name;
  final String photoUrl;
  final String lastMessage;
  final String timeAgo;
  final bool isOnline;
  final bool isUnread;

  const ChatConversation({
    required this.name,
    required this.photoUrl,
    required this.lastMessage,
    required this.timeAgo,
    this.isOnline = false,
    this.isUnread = false,
  });
}

class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final ChatMessage? replyTo;
  final String? imageUrl;
  final Uint8List? imageBytes;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.replyTo,
    this.imageUrl,
    this.imageBytes,
  });
}

List<ChatMessage> generateDummyMessages(String contactName) {
  final now = DateTime.now();
  return [
    ChatMessage(
      id: '1',
      text: 'Hey! I saw you know Flutter, that\'s awesome!',
      isMe: false,
      timestamp: now.subtract(const Duration(hours: 2, minutes: 30)),
    ),
    ChatMessage(
      id: '2',
      text: 'Hi! Yeah I\'ve been working with it for a while now 😊',
      isMe: true,
      timestamp: now.subtract(const Duration(hours: 2, minutes: 28)),
    ),
    ChatMessage(
      id: '3',
      text: 'Would you be open to teaching me some basics? I can help you with UI/UX design in return!',
      isMe: false,
      timestamp: now.subtract(const Duration(hours: 2, minutes: 25)),
    ),
    ChatMessage(
      id: '4',
      text: 'That sounds like a great trade! I\'ve been wanting to improve my design skills',
      isMe: true,
      timestamp: now.subtract(const Duration(hours: 2, minutes: 20)),
    ),
    ChatMessage(
      id: '5',
      text: 'Perfect! When are you free this week?',
      isMe: false,
      timestamp: now.subtract(const Duration(hours: 1, minutes: 45)),
    ),
    ChatMessage(
      id: '6',
      text: 'I\'m pretty flexible, how about Thursday evening?',
      isMe: true,
      timestamp: now.subtract(const Duration(hours: 1, minutes: 40)),
    ),
    ChatMessage(
      id: '7',
      text: 'Thursday works! Should we do it online or meet up at a coffee shop?',
      isMe: false,
      timestamp: now.subtract(const Duration(hours: 1, minutes: 30)),
    ),
    ChatMessage(
      id: '8',
      text: 'Coffee shop sounds fun, any suggestions?',
      isMe: true,
      timestamp: now.subtract(const Duration(hours: 1, minutes: 25)),
    ),
    ChatMessage(
      id: '9',
      text: 'There\'s a great one downtown called The Grind, they have good wifi too',
      isMe: false,
      timestamp: now.subtract(const Duration(minutes: 45)),
    ),
    ChatMessage(
      id: '10',
      text: 'I know that place! Let\'s do it 🔥',
      isMe: true,
      timestamp: now.subtract(const Duration(minutes: 40)),
    ),
  ];
}

const List<ChatMatch> newMatches = [
  ChatMatch(
    name: 'Sarah',
    photoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
    isOnline: true,
  ),
  ChatMatch(
    name: 'Yuki',
    photoUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
    isOnline: false,
  ),
  ChatMatch(
    name: 'Alex',
    photoUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200',
    isOnline: true,
  ),
  ChatMatch(
    name: 'Priya',
    photoUrl: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=200',
    isOnline: false,
  ),
  ChatMatch(
    name: 'Marcus',
    photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    isOnline: false,
  ),
  ChatMatch(
    name: 'Lina',
    photoUrl: 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=200',
    isOnline: true,
  ),
];

const List<ChatConversation> conversations = [
  ChatConversation(
    name: 'Sarah',
    photoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
    lastMessage: "Hey! I'd love to learn Flutter from you 🚀",
    timeAgo: '2m',
    isOnline: true,
    isUnread: true,
  ),
  ChatConversation(
    name: 'Alex',
    photoUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=200',
    lastMessage: 'Can we schedule a photography session this weekend?',
    timeAgo: '15m',
    isOnline: true,
    isUnread: true,
  ),
  ChatConversation(
    name: 'Yuki',
    photoUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
    lastMessage: 'Thanks for the React tips! Really helpful 😊',
    timeAgo: '1h',
    isOnline: false,
    isUnread: false,
  ),
  ChatConversation(
    name: 'Marcus',
    photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    lastMessage: 'The ML model is working now, check it out',
    timeAgo: '3h',
    isOnline: false,
    isUnread: false,
  ),
  ChatConversation(
    name: 'Priya',
    photoUrl: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=200',
    lastMessage: 'Yoga session was great, same time next week?',
    timeAgo: '1d',
    isOnline: false,
    isUnread: false,
  ),
  ChatConversation(
    name: 'Lina',
    photoUrl: 'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=200',
    lastMessage: 'Sent you the design files!',
    timeAgo: '2d',
    isOnline: true,
    isUnread: false,
  ),
];
