import 'package:flutter/material.dart';

/// One Quote of the Day: a healthy-living saying ([reference] null) or a
/// King James Version verse with its [reference] ("John 14:27").
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

  /// King James Version, word for word.
  static const List<DailyQuote> verses = [
    DailyQuote(
        'Peace I leave with you, my peace I give unto you: not as the world '
        'giveth, give I unto you. Let not your heart be troubled, neither let '
        'it be afraid.',
        reference: 'John 14:27'),
    DailyQuote(
        'Come unto me, all ye that labour and are heavy laden, and I will give '
        'you rest.',
        reference: 'Matthew 11:28'),
    DailyQuote(
        'But they that wait upon the LORD shall renew their strength; they '
        'shall mount up with wings as eagles; they shall run, and not be '
        'weary; and they shall walk, and not faint.',
        reference: 'Isaiah 40:31'),
    DailyQuote('I can do all things through Christ which strengtheneth me.',
        reference: 'Philippians 4:13'),
    DailyQuote(
        'Beloved, I wish above all things that thou mayest prosper and be in '
        'health, even as thy soul prospereth.',
        reference: '3 John 1:2'),
    DailyQuote(
        'A merry heart doeth good like a medicine: but a broken spirit drieth '
        'the bones.',
        reference: 'Proverbs 17:22'),
    DailyQuote(
        'I will both lay me down in peace, and sleep: for thou, LORD, only '
        'makest me dwell in safety.',
        reference: 'Psalm 4:8'),
    DailyQuote(
        'Fear thou not; for I am with thee: be not dismayed; for I am thy God: '
        'I will strengthen thee; yea, I will help thee; yea, I will uphold '
        'thee with the right hand of my righteousness.',
        reference: 'Isaiah 41:10'),
    DailyQuote(
        'What? know ye not that your body is the temple of the Holy Ghost '
        'which is in you, which ye have of God, and ye are not your own?',
        reference: '1 Corinthians 6:19'),
    DailyQuote(
        'Be not wise in thine own eyes: fear the LORD, and depart from evil. '
        'It shall be health to thy navel, and marrow to thy bones.',
        reference: 'Proverbs 3:7-8'),
    DailyQuote('God is our refuge and strength, a very present help in trouble.',
        reference: 'Psalm 46:1'),
    DailyQuote(
        'Pleasant words are as an honeycomb, sweet to the soul, and health to '
        'the bones.',
        reference: 'Proverbs 16:24'),
    DailyQuote(
        'When thou liest down, thou shalt not be afraid: yea, thou shalt lie '
        'down, and thy sleep shall be sweet.',
        reference: 'Proverbs 3:24'),
    DailyQuote(
        'Thou wilt keep him in perfect peace, whose mind is stayed on thee: '
        'because he trusteth in thee.',
        reference: 'Isaiah 26:3'),
    DailyQuote('Casting all your care upon him; for he careth for you.',
        reference: '1 Peter 5:7'),
    DailyQuote('He healeth the broken in heart, and bindeth up their wounds.',
        reference: 'Psalm 147:3'),
    DailyQuote('And he said, My presence shall go with thee, and I will give '
        'thee rest.',
        reference: 'Exodus 33:14'),
    DailyQuote(
        'For God hath not given us the spirit of fear; but of power, and of '
        'love, and of a sound mind.',
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
