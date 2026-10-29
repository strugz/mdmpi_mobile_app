import 'package:flutter/material.dart';

/// One Quote of the Day: a healthy-living saying ([reference] null) or a
/// World English Bible verse with its [reference] ("John 14:27").
class DailyQuote {
  const DailyQuote(this.text, {this.reference});

  final String text;
  final String? reference;

  bool get isVerse => reference != null;
}

/// One of the healthy-living tips under the quote.
class HealthyTip {
  const HealthyTip(
      {required this.icon, required this.title, required this.detail});

  final IconData icon;
  final String title;
  final String detail;
}

/// One day's pair: a healthy saying and a Bible verse, shown together.
class DailyQuotePair {
  const DailyQuotePair({required this.saying, required this.verse});

  final DailyQuote saying;
  final DailyQuote verse;
}

/// The Quote of the Day, the same for everyone on the same calendar day:
/// one healthy saying and one Bible verse together, changing at local
/// midnight. Each list steps one forward a day, so neither is ever shown
/// two days in a row; the same pair comes back every 90 days.
class BDailyQuotes {
  BDailyQuotes._();

  /// Any fixed date works; this one keeps the numbers small.
  static final DateTime _epoch = DateTime.utc(2026, 1, 1);

  /// Whole days from [_epoch] to [date]'s calendar day. Built from the date
  /// parts in UTC so a daylight-saving change never shifts the count.
  static int dayNumber(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).difference(_epoch).inDays;

  /// The saying and verse for [date]'s calendar day. Dart's `%` is never
  /// negative here, so days before the epoch work too.
  static DailyQuotePair forDate(DateTime date) {
    final day = dayNumber(date);
    return DailyQuotePair(
      saying: sayings[day % sayings.length],
      verse: verses[day % verses.length],
    );
  }

  /// "2026-10-28" — what the daily popup stores to show once a day.
  static String dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static const List<DailyQuote> sayings = [
    DailyQuote('A glass of water now is a small gift to the you of this afternoon.'),
    DailyQuote('Every step counts, even the short walk to the next desk.'),
    DailyQuote('Fill half your plate with color, and your body will thank you.'),
    DailyQuote('Sleep is not lost time. It is how tomorrow gets its strength.'),
    DailyQuote('Look up from the screen, find something far away, and let your eyes rest.'),
    DailyQuote('A calm mind is part of a healthy body. Breathe slowly for one minute.'),
    DailyQuote("You don't have to go far today. You just have to move."),
    DailyQuote('Stretch when you stand up. Your back has been waiting all morning.'),
    DailyQuote('Fruit is a sweet snack that loves you back.'),
    DailyQuote('Rest is part of the work, not a break from it.'),
    DailyQuote('Drink before you feel thirsty. Thirst is already a late reminder.'),
    DailyQuote('Take the stairs when you can. Small climbs build strong legs.'),
    DailyQuote('A good laugh with a friend is good for the heart.'),
    DailyQuote('Put the phone down an hour before bed, and sleep comes easier.'),
    DailyQuote('Healthy habits grow one small choice at a time.'),
    DailyQuote('Eat slowly. Your stomach needs time to tell you it is full.'),
    DailyQuote('Fresh air and sunlight are free. Step outside for a few minutes.'),
    DailyQuote('It is okay to ask for help. Caring for your mind is caring for yourself.'),
    DailyQuote('Every 20 minutes on a screen, look far away for 20 seconds.'),
    DailyQuote('Bring water for the road. A long trip is easier when you stay refreshed.'),
    DailyQuote('Vegetables at lunch keep you going through the afternoon.'),
    DailyQuote('Sleep and wake at about the same time. Your body loves a routine.'),
    DailyQuote('Be kind to yourself today. Progress matters more than perfect.'),
    DailyQuote('Sit tall, relax your shoulders, and take a deep breath.'),
    DailyQuote('A short walk after a meal helps your body and clears your head.'),
    DailyQuote('Choose water over sugary drinks most of the time.'),
    DailyQuote('Think of one thing you are thankful for today.'),
    DailyQuote('The time you give your health today, it gives back to you later.'),
    DailyQuote('Rest your hands and eyes between tasks. Small pauses prevent big aches.'),
    DailyQuote('Start the day with a glass of water and a good stretch.'),
  ];

  /// World English Bible (public domain), word for word. Line breaks in the
  /// poetry are joined with spaces; Matthew 11:28 drops the opening quote
  /// mark of a speech that runs on to verse 30.
  static const List<DailyQuote> verses = [
    DailyQuote(
        'Peace I leave with you. My peace I give to you; not as the world '
        'gives, give I to you. Don’t let your heart be troubled, neither '
        'let it be fearful.',
        reference: 'John 14:27'),
    DailyQuote(
        'Come to me, all you who labor and are heavily burdened, and I will '
        'give you rest.',
        reference: 'Matthew 11:28'),
    DailyQuote(
        'But those who wait for Yahweh will renew their strength. They will '
        'mount up with wings like eagles. They will run, and not be weary. '
        'They will walk, and not faint.',
        reference: 'Isaiah 40:31'),
    DailyQuote('I can do all things through Christ, who strengthens me.',
        reference: 'Philippians 4:13'),
    DailyQuote(
        'Beloved, I pray that you may prosper in all things and be healthy, '
        'even as your soul prospers.',
        reference: '3 John 1:2'),
    DailyQuote(
        'A cheerful heart makes good medicine, but a crushed spirit dries '
        'up the bones.',
        reference: 'Proverbs 17:22'),
    DailyQuote(
        'In peace I will both lay myself down and sleep, for you, Yahweh '
        'alone, make me live in safety.',
        reference: 'Psalm 4:8'),
    DailyQuote(
        'Don’t you be afraid, for I am with you. Don’t be dismayed, for I '
        'am your God. I will strengthen you. Yes, I will help you. Yes, I '
        'will uphold you with the right hand of my righteousness.',
        reference: 'Isaiah 41:10'),
    DailyQuote(
        'Or don’t you know that your body is a temple of the Holy Spirit '
        'who is in you, whom you have from God? You are not your own, for '
        'you were bought with a price. Therefore glorify God in your body '
        'and in your spirit, which are God’s.',
        reference: '1 Corinthians 6:19-20'),
    DailyQuote(
        'Don’t be wise in your own eyes. Fear Yahweh, and depart from evil. '
        'It will be health to your body, and nourishment to your bones.',
        reference: 'Proverbs 3:7-8'),
    DailyQuote('God is our refuge and strength, a very present help in trouble.',
        reference: 'Psalm 46:1'),
    DailyQuote(
        'Pleasant words are a honeycomb, sweet to the soul, and health to '
        'the bones.',
        reference: 'Proverbs 16:24'),
    DailyQuote(
        'When you lie down, you will not be afraid. Yes, you will lie down, '
        'and your sleep will be sweet.',
        reference: 'Proverbs 3:24'),
    DailyQuote(
        'You will keep whoever’s mind is steadfast in perfect peace, '
        'because he trusts in you.',
        reference: 'Isaiah 26:3'),
    DailyQuote(
        'Humble yourselves therefore under the mighty hand of God, that he '
        'may exalt you in due time; casting all your worries on him, '
        'because he cares for you.',
        reference: '1 Peter 5:6-7'),
    DailyQuote('He heals the broken in heart, and binds up their wounds.',
        reference: 'Psalm 147:3'),
    DailyQuote('He said, “My presence will go with you, and I will give you rest.”',
        reference: 'Exodus 33:14'),
    DailyQuote(
        'For God didn’t give us a spirit of fear, but of power, love, and '
        'self-control.',
        reference: '2 Timothy 1:7'),
  ];

  static const List<HealthyTip> tips = [
    HealthyTip(
        icon: Icons.water_drop_outlined,
        title: 'Drink enough water',
        detail: 'Keep a bottle close and sip through the day.'),
    HealthyTip(
        icon: Icons.directions_walk,
        title: 'Move every day',
        detail: 'Walk, stretch, or take the stairs. A little is better than none.'),
    HealthyTip(
        icon: Icons.eco_outlined,
        title: 'Eat more vegetables and fruit',
        detail: 'Add some color to every meal.'),
    HealthyTip(
        icon: Icons.bedtime_outlined,
        title: 'Get enough sleep',
        detail: 'Aim for a regular bedtime and a full night of rest.'),
    HealthyTip(
        icon: Icons.visibility_outlined,
        title: 'Rest your eyes from the screen',
        detail: 'Every so often, look at something far away for a few seconds.'),
    HealthyTip(
        icon: Icons.self_improvement,
        title: 'Take care of your mind',
        detail: 'Slow down, breathe, and talk to someone you trust.'),
  ];
}
