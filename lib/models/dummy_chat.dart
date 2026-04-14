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
