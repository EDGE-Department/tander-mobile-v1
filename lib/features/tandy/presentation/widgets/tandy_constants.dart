/// Design constants and content data for the Tandy AI module.
///
/// All magic numbers, color values, and static content live here
/// so widgets remain pure rendering logic.
library;

import 'dart:ui';

// ── Brand Colors ────────────────────────────────────────────────────

const Color kTandyOrange = Color(0xFFE67E22);
const Color kTandyTeal = Color(0xFF0F9D94);
const Color kTandyPurple = Color(0xFF7C3AED);
const Color kTandyGreen = Color(0xFF2E8B57);
const Color kTandyBlue = Color(0xFF2F6FDE);

// ── Layout ──────────────────────────────────────────────────────────

const double kThreadMaxWidth = 840;
const double kChatMaxWidth = 760;

// ── Greeting Suggestions ────────────────────────────────────────────

const List<String> kDefaultPrompts = <String>[
  'I feel overwhelmed today',
  'Can you help me slow down?',
  'I need encouragement',
  'Can we talk about my day?',
];

// ── Breathing Exercise: 4-7-8 Phases ────────────────────────────────

const int kBreathingInhaleDuration = 4;
const int kBreathingHoldDuration = 7;
const int kBreathingExhaleDuration = 8;
const int kBreathingRestDuration = 2;
const int kBreathingTotalCycles = 4;
const int kBreathingCycleDuration =
    kBreathingInhaleDuration +
    kBreathingHoldDuration +
    kBreathingExhaleDuration +
    kBreathingRestDuration; // 21s
const int kBreathingSessionDuration =
    kBreathingCycleDuration * kBreathingTotalCycles; // 84s

const Color kInhaleColor = Color(0xFFE67E22);
const Color kHoldColor = Color(0xFF7C3AED);
const Color kExhaleColor = Color(0xFF0F9D94);
const Color kRestColor = Color(0xFF2E8B57);

// ── Meditation Presets ──────────────────────────────────────────────

class MeditationPreset {
  const MeditationPreset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.durationMinutes,
    required this.color,
    required this.bestFor,
    required this.guidanceSteps,
  });

  final String id;
  final String title;
  final String subtitle;
  final int durationMinutes;
  final Color color;
  final String bestFor;
  final List<String> guidanceSteps;
}

const List<MeditationPreset> kMeditationPresets = <MeditationPreset>[
  MeditationPreset(
    id: 'morning-calm',
    title: 'Morning Calm',
    subtitle: 'Start your day with clarity and lightness',
    durationMinutes: 5,
    color: kTandyOrange,
    bestFor: 'Fresh starts',
    guidanceSteps: <String>[
      'Find a comfortable position and gently close your eyes.',
      'Take three deep breaths, letting each exhale release any tension.',
      'Notice the quality of light behind your eyelids.',
      'Set a gentle intention for your day — just one word or feeling.',
      'Breathe naturally, returning to your intention when the mind wanders.',
      'When ready, slowly open your eyes and carry this calm forward.',
    ],
  ),
  MeditationPreset(
    id: 'deep-rest',
    title: 'Deep Rest',
    subtitle: 'Unwind from the day and settle the nervous system',
    durationMinutes: 10,
    color: kTandyPurple,
    bestFor: 'Evening reset',
    guidanceSteps: <String>[
      'Lie or sit comfortably and let your body relax completely.',
      'Scan slowly from the top of your head down to your feet.',
      'At each area, breathe in and invite that part of you to soften.',
      'Notice any thoughts without following them — like clouds passing.',
      'With each breath, sink a little deeper into stillness.',
      'Stay here as long as feels right, returning when you are ready.',
    ],
  ),
  MeditationPreset(
    id: 'gratitude',
    title: 'Gratitude Moment',
    subtitle: 'Reconnect with warmth, care, and perspective',
    durationMinutes: 7,
    color: kTandyGreen,
    bestFor: 'Gentle grounding',
    guidanceSteps: <String>[
      'Settle into stillness and place one hand over your heart.',
      'Think of someone who has brought warmth to your life recently.',
      'Let the feeling of gratitude grow naturally — no pressure.',
      'Expand this warmth to include yourself. You are worthy of kindness.',
      'Bring to mind one small thing today that went well, however small.',
      'Carry this gentle appreciation as you return to your day.',
    ],
  ),
];

// ── Mood Check-in Options ───────────────────────────────────────────

class MoodOption {
  const MoodOption({
    required this.id,
    required this.emoji,
    required this.label,
    required this.accentColor,
    required this.chatMessage,
  });

  final String id;
  final String emoji;
  final String label;
  final Color accentColor;
  final String chatMessage;
}

const List<MoodOption> kMoodOptions = <MoodOption>[
  MoodOption(
    id: 'happy',
    emoji: '\u{1F60A}',
    label: 'Good',
    accentColor: Color(0xFF22C55E),
    chatMessage:
        "I'm feeling good today! I'd love to keep this positive energy going.",
  ),
  MoodOption(
    id: 'calm',
    emoji: '\u{1F60C}',
    label: 'Calm',
    accentColor: kTandyTeal,
    chatMessage:
        "I'm feeling calm today. Let's keep this peaceful momentum going.",
  ),
  MoodOption(
    id: 'anxious',
    emoji: '\u{1F630}',
    label: 'Anxious',
    accentColor: Color(0xFFEF4444),
    chatMessage:
        "I'm feeling a bit anxious right now. Can you help me work through it?",
  ),
  MoodOption(
    id: 'sad',
    emoji: '\u{1F61E}',
    label: 'Low',
    accentColor: Color(0xFF3B82F6),
    chatMessage:
        "I'm feeling a bit low today and could really use some support.",
  ),
];

// ── Daily Motivational Messages ─────────────────────────────────────

class DailyMessage {
  const DailyMessage({
    required this.id,
    required this.text,
    required this.accentColor,
  });

  final String id;
  final String text;
  final Color accentColor;
}

const List<DailyMessage> kDailyMessages = <DailyMessage>[
  DailyMessage(
    id: 'step',
    text:
        "You don't have to have it all figured out. Every small step forward is worth celebrating.",
    accentColor: kTandyOrange,
  ),
  DailyMessage(
    id: 'breathe',
    text:
        "Take a slow breath. Right now, in this moment, you are safe and supported. That's more than enough.",
    accentColor: kTandyTeal,
  ),
  DailyMessage(
    id: 'worth',
    text:
        'Your feelings are valid — every single one of them. Talking about them is the bravest thing you can do.',
    accentColor: kTandyPurple,
  ),
];

// ── Emotion Indicator Styles ────────────────────────────────────────

class EmotionStyle {
  const EmotionStyle({
    required this.emoji,
    required this.label,
    required this.backgroundFrom,
    required this.backgroundTo,
    required this.borderColor,
    required this.textColor,
  });

  final String emoji;
  final String label;
  final Color backgroundFrom;
  final Color backgroundTo;
  final Color borderColor;
  final Color textColor;
}

const Map<String, EmotionStyle> kEmotionStyles = <String, EmotionStyle>{
  'happy': EmotionStyle(
    emoji: '\u{1F60A}',
    label: 'Happy',
    backgroundFrom: Color(0xFFD1FAE5),
    backgroundTo: Color(0xFFA7F3D0),
    borderColor: Color(0x2E065F46),
    textColor: Color(0xFF065F46),
  ),
  'sad': EmotionStyle(
    emoji: '\u{1F622}',
    label: 'Sad',
    backgroundFrom: Color(0xFFDBEAFE),
    backgroundTo: Color(0xFFBFDBFE),
    borderColor: Color(0x2E1E3A5F),
    textColor: Color(0xFF1E3A5F),
  ),
  'anxious': EmotionStyle(
    emoji: '\u{1F630}',
    label: 'Anxious',
    backgroundFrom: Color(0xFFFEF3C7),
    backgroundTo: Color(0xFFFDE68A),
    borderColor: Color(0x2E92400E),
    textColor: Color(0xFF78350F),
  ),
  'lonely': EmotionStyle(
    emoji: '\u{1F97A}',
    label: 'Lonely',
    backgroundFrom: Color(0xFFEDE9FE),
    backgroundTo: Color(0xFFDDD6FE),
    borderColor: Color(0x2E5B21B6),
    textColor: Color(0xFF5B21B6),
  ),
  'angry': EmotionStyle(
    emoji: '\u{1F624}',
    label: 'Upset',
    backgroundFrom: Color(0xFFFEE2E2),
    backgroundTo: Color(0xFFFECACA),
    borderColor: Color(0x2E991B1B),
    textColor: Color(0xFF7F1D1D),
  ),
  'grateful': EmotionStyle(
    emoji: '\u{1F64F}',
    label: 'Grateful',
    backgroundFrom: Color(0xFFD1FAE5),
    backgroundTo: Color(0xFFA7F3D0),
    borderColor: Color(0x2E065F46),
    textColor: Color(0xFF065F46),
  ),
  'hopeful': EmotionStyle(
    emoji: '\u2728',
    label: 'Hopeful',
    backgroundFrom: Color(0xFFFEF0E0),
    backgroundTo: Color(0xFFFDE1C1),
    borderColor: Color(0x2E9A3412),
    textColor: Color(0xFF7C2D12),
  ),
  'confused': EmotionStyle(
    emoji: '\u{1F615}',
    label: 'Confused',
    backgroundFrom: Color(0xFFF3E8FF),
    backgroundTo: Color(0xFFE9D5FF),
    borderColor: Color(0x2E6B21A8),
    textColor: Color(0xFF6B21A8),
  ),
  'neutral': EmotionStyle(
    emoji: '\u263A\uFE0F',
    label: 'Calm',
    backgroundFrom: Color(0xFFF4F1EC),
    backgroundTo: Color(0xFFEAE5DD),
    borderColor: Color(0x2657534E),
    textColor: Color(0xFF44403C),
  ),
};

const EmotionStyle kFallbackEmotionStyle = EmotionStyle(
  emoji: '\u263A\uFE0F',
  label: 'Calm',
  backgroundFrom: Color(0xFFF4F1EC),
  backgroundTo: Color(0xFFEAE5DD),
  borderColor: Color(0x2657534E),
  textColor: Color(0xFF44403C),
);
