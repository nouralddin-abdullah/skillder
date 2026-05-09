/// Computes a 0–100 profile completion percentage from a `/users/me` response.
///
/// Easy to tweak: change the numbers in [_weights] and the conditions below.
/// Keep totals adding up to 100.
library;

class _Weights {
  // Photos — biggest weight; cap at 4 (Tinder/Bumble UX research sweet spot).
  static const int photoFirst = 10;
  static const int photoExtra = 5; // each of 2nd–4th
  static const int photoCap = 4; // photos beyond this give nothing

  static const int headline = 10;
  static const int giveSkills = 8; // round nums; 7.5+7.5 → 8+7
  static const int getSkills = 7;
  static const int intent = 5;

  static const int bio = 10;
  static const int prompts = 10; // first prompt only; more give nothing

  // Basics — 4 fields × 4 = 16
  static const int basicsPerField = 4;

  // Lifestyle — 3 fields × 3 = 9
  static const int lifestylePerField = 3;
}

int profileCompletion(Map<String, dynamic> me) {
  int score = 0;

  // Photos
  final photos = me['photos'];
  final photoCount = photos is List ? photos.length : 0;
  if (photoCount >= 1) score += _Weights.photoFirst;
  final extras = (photoCount - 1).clamp(0, _Weights.photoCap - 1);
  score += extras * _Weights.photoExtra;

  // Headline
  if (_isNonEmptyString(me['headline'])) score += _Weights.headline;

  // Skills + intent
  if (_isNonEmptyList(me['giveSkills'])) score += _Weights.giveSkills;
  if (_isNonEmptyList(me['getSkills'])) score += _Weights.getSkills;
  if (_isNonEmptyList(me['intents'])) score += _Weights.intent;

  // Bio
  if (_isNonEmptyString(me['bio'])) score += _Weights.bio;

  // Prompts — ≥1 only
  if (_isNonEmptyList(me['prompts'])) score += _Weights.prompts;

  // Basics
  for (final f in const ['education', 'careerStage', 'domain', 'workStyle']) {
    if (_isNonEmptyString(me[f])) score += _Weights.basicsPerField;
  }

  // Lifestyle
  for (final f in const ['fuelSource', 'focusSoundtrack', 'rechargeMode']) {
    if (_isNonEmptyString(me[f])) score += _Weights.lifestylePerField;
  }

  return score.clamp(0, 100);
}

bool _isNonEmptyString(dynamic v) =>
    v is String && v.trim().isNotEmpty;

bool _isNonEmptyList(dynamic v) => v is List && v.isNotEmpty;
