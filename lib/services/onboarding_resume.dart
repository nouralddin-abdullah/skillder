/// Given the user profile from `GET /users/me`, returns the onboarding step
/// index the user should resume on.
///
/// Logic is sequential: each later mandatory field implies all earlier ones
/// were filled. Steps 4 (Basics) and 5 (Lifestyle) are skippable, so once the
/// user has filled the last mandatory field (`intents`) we just send them to
/// step 4 and let them go through the rest of the flow.
int onboardingResumeStep(Map<String, dynamic> me) {
  final headline = me['headline'];
  final photos = me['photos'];
  final hasHeadline = headline is String && headline.trim().isNotEmpty;
  final hasPhoto = photos is List && photos.isNotEmpty;

  if (!hasHeadline || !hasPhoto) return 0;

  final give = me['giveSkills'];
  if (give is! List || give.isEmpty) return 1;

  final get = me['getSkills'];
  if (get is! List || get.isEmpty) return 2;

  final intents = me['intents'];
  if (intents is! List || intents.isEmpty) return 3;

  // All mandatory done but onboardingComplete still false → resume on Basics.
  return 4;
}
