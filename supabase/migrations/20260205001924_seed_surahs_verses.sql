-- Quran reference data for demo scoring

create table if not exists public.surahs (
  id int primary key,
  name text not null,
  translation text not null,
  ayah_count int not null,
  summary text
);

create table if not exists public.verses (
  surah_id int not null references public.surahs (id) on delete cascade,
  ayah_id int not null,
  arabic text not null,
  transliteration text not null,
  translation text not null,
  meaning text not null,
  primary key (surah_id, ayah_id)
);

insert into public.surahs (id, name, translation, ayah_count, summary) values
  (1, 'Al-Fatihah', 'The Opening', 7, 'A short opening prayer for guidance and mercy.'),
  (112, 'Al-Ikhlas', 'Sincerity', 4, 'A declaration of Allah''s absolute oneness.')
  on conflict (id) do nothing;

insert into public.verses (surah_id, ayah_id, arabic, transliteration, translation, meaning) values
  (1, 1, 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ', 'Bismillahir Rahmanir Rahim', 'In the name of Allah, the Most Gracious, the Most Merciful.', 'Begin with Allah''s name and mercy.'),
  (1, 2, 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ', 'Alhamdu lillahi Rabbil ''alamin', 'All praise is due to Allah, Lord of the worlds.', 'Praise and gratitude belong to Allah.'),
  (1, 3, 'الرَّحْمَٰنِ الرَّحِيمِ', 'Ar-Rahmanir Rahim', 'The Most Gracious, the Most Merciful.', 'Allah is full of mercy.'),
  (1, 4, 'مَالِكِ يَوْمِ الدِّينِ', 'Maliki yawmi d-din', 'Master of the Day of Judgment.', 'Allah is in control of the final day.'),
  (1, 5, 'إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ', 'Iyyaka na''budu wa iyyaka nasta''in', 'You alone we worship, and You alone we ask for help.', 'We worship Allah and seek His help.'),
  (1, 6, 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ', 'Ihdina as-sirata al-mustaqim', 'Guide us to the straight path.', 'Ask Allah for guidance.'),
  (1, 7, 'صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ', 'Sirata alladhina an''amta ''alayhim ghayri al-maghdubi ''alayhim wa la ad-dallin', 'The path of those upon whom You have bestowed favor, not of those who have angered You nor of those who go astray.', 'Ask to stay on the path of the favored.')
  on conflict (surah_id, ayah_id) do nothing;

insert into public.verses (surah_id, ayah_id, arabic, transliteration, translation, meaning) values
  (112, 1, 'قُلْ هُوَ اللَّهُ أَحَدٌ', 'Qul huwa Allahu ahad', 'Say, He is Allah, the One.', 'Declare Allah''s oneness.'),
  (112, 2, 'اللَّهُ الصَّمَدُ', 'Allahu as-samad', 'Allah, the Eternal Refuge.', 'Allah is the one we depend on.'),
  (112, 3, 'لَمْ يَلِدْ وَلَمْ يُولَدْ', 'Lam yalid wa lam yulad', 'He neither begets nor is born.', 'Allah has no parent or child.'),
  (112, 4, 'وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ', 'Wa lam yakun lahu kufuwan ahad', 'Nor is there to Him any equivalent.', 'Nothing compares to Allah.')
  on conflict (surah_id, ayah_id) do nothing;

