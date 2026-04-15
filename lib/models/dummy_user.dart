class DummyUser {
  final String firstName;
  final int age;
  final String headline;
  final String bio;
  final String location;
  final List<String> languages;
  final List<String> photos;
  final List<String> giveSkills;
  final List<String> getSkills;
  final String intent;

  const DummyUser({
    required this.firstName,
    required this.age,
    required this.headline,
    required this.bio,
    required this.location,
    required this.languages,
    required this.photos,
    required this.giveSkills,
    required this.getSkills,
    required this.intent,
  });
}

// Current user's "get" skills — used to highlight shared matches
const Set<String> currentUserGetSkills = {
  'Flutter',
  'UI/UX Design',
  'Machine Learning',
  'Photography',
  'Piano',
  'Spanish',
};

DummyUser? findUserByName(String name) {
  try {
    return dummyUsers.firstWhere(
      (u) => u.firstName.toLowerCase() == name.toLowerCase(),
    );
  } catch (_) {
    return null;
  }
}

const List<DummyUser> dummyUsers = [
  DummyUser(
    firstName: 'Sarah',
    age: 27,
    headline: 'Product Designer at Spotify',
    bio:
        'Design-obsessed problem solver who believes great UX can change the world. '
        'Currently exploring the intersection of AI and design systems. '
        'Always down for a good coffee chat about creative workflows.',
    location: 'San Francisco, CA',
    languages: ['English', 'French'],
    photos: [
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=800',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800',
    ],
    giveSkills: ['UI/UX Design', 'Figma', 'Brand Identity', 'Motion Graphics'],
    getSkills: ['Flutter', 'React', 'Python'],
    intent: 'Skill Swap',
  ),
  DummyUser(
    firstName: 'Marcus',
    age: 31,
    headline: 'ML Engineer at Tesla',
    bio:
        'Building intelligent systems by day, producing lo-fi beats by night. '
        "I think the best way to learn is by teaching — so let's trade knowledge. "
        'Currently deep into reinforcement learning and generative models.',
    location: 'Austin, TX',
    languages: ['English', 'German'],
    photos: [
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800',
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=800',
      'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=800',
      'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=800',
    ],
    giveSkills: [
      'Machine Learning',
      'Python',
      'Data Science',
      'Music Production',
    ],
    getSkills: ['UI/UX Design', 'Photography', 'Public Speaking'],
    intent: 'Mentorship',
  ),
  DummyUser(
    firstName: 'Yuki',
    age: 24,
    headline: 'Full-Stack Developer & Chef',
    bio:
        'Code in the morning, cook in the evening. '
        'I built my first app at 16 and my first soufflé at 20. '
        'Looking for creative people who want to exchange unconventional skills.',
    location: 'Tokyo, Japan',
    languages: ['Japanese', 'English', 'Korean'],
    photos: [
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=800',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=800',
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=800',
    ],
    giveSkills: ['React', 'Node.js', 'Cooking', 'Sushi Making'],
    getSkills: ['Flutter', 'Machine Learning', 'Photography'],
    intent: 'Co-Learning',
  ),
  DummyUser(
    firstName: 'Alex',
    age: 29,
    headline: 'Freelance Photographer',
    bio:
        'I see stories everywhere — my camera just helps me tell them. '
        'Specializing in street and portrait photography. '
        'Want to learn how tech people think so I can build my portfolio platform.',
    location: 'Berlin, Germany',
    languages: ['German', 'English', 'Spanish'],
    photos: [
      'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=800',
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=800',
      'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=800',
    ],
    giveSkills: ['Photography', 'Video Editing', 'Adobe Suite', 'Storytelling'],
    getSkills: ['Flutter', 'JavaScript', 'SEO', 'Marketing'],
    intent: 'Skill Swap',
  ),
  DummyUser(
    firstName: 'Priya',
    age: 26,
    headline: 'Data Scientist & Yoga Instructor',
    bio:
        'Balancing algorithms and asanas. '
        'I crunch numbers at a health-tech startup during the week '
        'and teach vinyasa flow on weekends. Always learning, always moving.',
    location: 'Mumbai, India',
    languages: ['Hindi', 'English', 'Tamil'],
    photos: [
      'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=800',
      'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=800',
      'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800',
    ],
    giveSkills: ['Data Science', 'Python', 'Yoga', 'Meditation'],
    getSkills: ['Piano', 'Spanish', 'Graphic Design'],
    intent: 'Co-Learning',
  ),
  DummyUser(
    firstName: 'Lina',
    age: 25,
    headline: 'Product Designer & Illustrator',
    bio:
        'Pixel-pusher turned illustrator. I spend my days designing mobile apps '
        'and my nights drawing on my iPad. Looking to trade design tips for code.',
    location: 'Barcelona, Spain',
    languages: ['Spanish', 'English', 'Catalan'],
    photos: [
      'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=800',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=800',
      'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=800',
    ],
    giveSkills: ['UI/UX Design', 'Illustration', 'Procreate', 'Figma'],
    getSkills: ['Flutter', 'Swift', 'JavaScript'],
    intent: 'Skill Swap',
  ),
];
