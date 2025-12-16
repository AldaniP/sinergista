import 'article_model.dart';

class ArticleData {
  static final List<Article> allArticles = [
    // Time Management
    Article(
      id: 'tm1',
      title: 'Pomodoro Technique',
      category: ArticleCategory.timeManagement.displayName,
      iconEmoji: ArticleCategory.timeManagement.emoji,
      summary: 'Teknik manajemen waktu dengan interval 25 menit fokus',
      readTimeMinutes: 3,
      content: '''
# Pomodoro Technique

Teknik Pomodoro adalah metode manajemen waktu yang dikembangkan oleh Francesco Cirillo pada akhir 1980-an.

## Cara Kerja:
1. Pilih tugas yang ingin dikerjakan
2. Set timer 25 menit (= 1 Pomodoro)
3. Kerja fokus tanpa distraksi
4. Istirahat 5 menit
5. Setelah 4 Pomodoro, istirahat 15-30 menit

## Keuntungan:
- Meningkatkan konsentrasi
- Mengurangi kelelahan mental
- Mudah track progress
- Cocok untuk tugas berat

## Tips:
- Matikan notifikasi HP
- Siapkan semua yang dibutuhkan sebelum mulai
- Catat distraksi yang muncul untuk dikerjakan nanti
''',
    ),
    Article(
      id: 'tm2',
      title: 'Time Blocking',
      category: ArticleCategory.timeManagement.displayName,
      iconEmoji: ArticleCategory.timeManagement.emoji,
      summary: 'Alokasikan blok waktu spesifik untuk setiap aktivitas',
      readTimeMinutes: 4,
      content: '''
# Time Blocking

Time blocking adalah metode scheduling di mana kamu membagi hari menjadi blok-blok waktu untuk tugas tertentu.

## Langkah-langkah:
1. List semua tugas hari ini
2. Estimasi waktu tiap tugas
3. Alokasikan blok waktu di kalender
4. Ikuti jadwal yang sudah dibuat

## Best Practices:
- Buat buffer time 10-15% untuk hal tak terduga
- Blok waktu paling produktif untuk tugas terberat
- Grouping tugas sejenis (batch processing)

## Contoh Jadwal:
- 08:00-10:00: Deep Work (coding/writing)
- 10:00-11:00: Email & meetings
- 11:00-12:00: Review & planning
''',
    ),

    // Focus Techniques
    Article(
      id: 'ft1',
      title: 'Deep Work',
      category: ArticleCategory.focusTechniques.displayName,
      iconEmoji: ArticleCategory.focusTechniques.emoji,
      summary: 'Fokus intensif tanpa distraksi untuk hasil maksimal',
      readTimeMinutes: 5,
      content: '''
# Deep Work

Deep Work adalah kemampuan untuk fokus tanpa distraksi pada tugas kognitif yang menantang.

## 4 Aturan Deep Work:
1. Work Deeply - Ciptakan ritual dan rutinitas
2. Embrace Boredom - Latih kemampuan fokus
3. Quit Social Media - Kurangi distraksi digital
4. Drain the Shallows - Minimalkan tugas superfisial

## Strategi Implementasi:
**Monastic**: Eliminasi total semua distraksi
**Bimodal**: Dedikasikan periode tertentu untuk deep work
**Rhythmic**: Jadwalkan deep work rutin setiap hari
**Journalistic**: Manfaatkan celah waktu kosong

## Tips:
- Pilih lokasi khusus untuk deep work
- Set durasi spesifik (90-120 menit ideal)
- Track jam deep work per minggu
''',
    ),

    // Study Tips
    Article(
      id: 'st1',
      title: 'Active Recall',
      category: ArticleCategory.studyTips.displayName,
      iconEmoji: ArticleCategory.studyTips.emoji,
      summary: 'Teknik belajar dengan mengingat informasi secara aktif',
      readTimeMinutes: 4,
      content: '''
# Active Recall

Active recall adalah teknik belajar dengan aktif mengingat informasi tanpa melihat materi.

## Kenapa Efektif?
- Strengthen memory pathways
- Identifikasi gap pemahaman
- Lebih efisien dari re-reading

## Cara Praktik:
1. Baca materi
2. Tutup buku
3. Tulis/ucapkan apa yang diingat
4. Check dan isi yang terlewat
5. Ulangi setelah beberapa hari

## Tools:
- Flashcards (Anki, Quizlet)
- Practice questions
- Teach others
- Mind maps dari ingatan
''',
    ),
    Article(
      id: 'st2',
      title: 'Spaced Repetition',
      category: ArticleCategory.studyTips.displayName,
      iconEmoji: ArticleCategory.studyTips.emoji,
      summary: 'Review materi dengan interval waktu yang meningkat',
      readTimeMinutes: 3,
      content: '''
# Spaced Repetition

Teknik review materi dengan jarak waktu yang semakin panjang untuk optimasi retensi.

## Jadwal Ideal:
- Day 1: Pelajari materi
- Day 2: Review ke-1
- Day 4: Review ke-2
- Day 7: Review ke-3
- Day 14: Review ke-4
- Day 30: Review ke-5

## Prinsip:
Review tepat sebelum kamu lupa = retensi maksimal

## Apps Recommended:
- Anki (paling powerful)
- Quizlet
- RemNote
''',
    ),

    // Productivity Hacks
    Article(
      id: 'ph1',
      title: '2-Minute Rule',
      category: ArticleCategory.productivityHacks.displayName,
      iconEmoji: ArticleCategory.productivityHacks.emoji,
      summary: 'Jika bisa selesai dalam 2 menit, lakukan sekarang',
      readTimeMinutes: 2,
      content: '''
# 2-Minute Rule

Jika ada tugas yang bisa diselesaikan dalam 2 menit atau kurang, lakukan segera.

## Manfaat:
- Hindari akumulasi tugas kecil
- Reduce mental clutter
- Build momentum
- Feel accomplished

## Contoh Tugas:
- Reply email singkat
- Cuci piring
- Simpan file ke folder
- Schedule meeting

## Tips:
Gunakan timer untuk maintain awareness dan hindari overestimate waktu.
''',
    ),
    Article(
      id: 'ph2',
      title: 'Eat the Frog',
      category: ArticleCategory.productivityHacks.displayName,
      iconEmoji: ArticleCategory.productivityHacks.emoji,
      summary: 'Kerjakan tugas tersulit di pagi hari',
      readTimeMinutes: 3,
      content: '''
# Eat the Frog

"If it's your job to eat a frog, it's best to do it first thing in the morning."

## Konsep:
Tackle tugas paling sulit/penting di awal hari saat energi masih fresh.

## Cara Identify Your Frog:
1. Tugas dengan impact terbesar
2. Tugas yang paling kamu hindari
3. Tugas dengan deadline mendekat

## Implementasi:
- Tentukan "frog" malam sebelumnya
- Lakukan di jam paling produktif (biasanya pagi)
- Jangan check email/sosmed dulu
- Selesaikan minimal 1 jam fokus

Setelah frog selesai, sisa hari terasa lebih ringan!
''',
    ),

    // Work-Life Balance
    Article(
      id: 'wl1',
      title: 'Digital Detox',
      category: ArticleCategory.workLifeBalance.displayName,
      iconEmoji: ArticleCategory.workLifeBalance.emoji,
      summary: 'Kurangi screen time untuk kesehatan mental',
      readTimeMinutes: 4,
      content: '''
# Digital Detox

Periode sengaja mengurangi atau menghentikan penggunaan device digital.

## Signs Kamu Perlu Detox:
- Cek HP hal pertama bangun
- FOMO terus-menerus
- Susah fokus tanpa HP
- Tidur terganggu karena screen time

## Cara Memulai:
**Level 1 - Screen-Free Zones:**
- No phone di meja makan
- No device 1 jam sebelum tidur
- Kamar bebas gadget

**Level 2 - Digital Sabbath:**
- 1 hari per minggu tanpa sosmed
- Matikan notifikasi non-esensial

## Tips:
- Ganti alarm HP dengan alarm fisik
- Read physical books
- Outdoor activities
''',
    ),
    Article(
      id: 'wl2',
      title: 'Power Naps',
      category: ArticleCategory.workLifeBalance.displayName,
      iconEmoji: ArticleCategory.workLifeBalance.emoji,
      summary: 'Tidur siang singkat untuk boost energi',
      readTimeMinutes: 3,
      content: '''
# Power Naps

Tidur siang singkat (10-20 menit) untuk refresh otak dan boost produktivitas.

## Durasi Optimal:
- **10-20 menit**: Quick refresh, no grogginess
- **30 menit**: Not recommended (sleep inertia)
- **90 menit**: Full sleep cycle (jika benar-benar butuh)

## Best Time:
- 1-3 PM (post-lunch dip)
- Hindari setelah jam 4 PM

## Tips:
- Dark, quiet environment
- Set alarm (jangan over-sleep)
- Caffeine nap: minum kopi lalu langsung tidur 20 menit

## Benefits:
- Improve memory
- Better mood
- Increased alertness
- Enhanced creativity
''',
    ),
  ];

  static List<Article> getArticlesByCategory(String category) {
    return allArticles
        .where((article) => article.category == category)
        .toList();
  }

  static Map<String, List<Article>> getArticlesGroupedByCategory() {
    final Map<String, List<Article>> grouped = {};
    for (var article in allArticles) {
      if (!grouped.containsKey(article.category)) {
        grouped[article.category] = [];
      }
      grouped[article.category]!.add(article);
    }
    return grouped;
  }
}
