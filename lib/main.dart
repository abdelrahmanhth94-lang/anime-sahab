import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const AnimeSahabApp());
}

const Color bg = Color(0xFF090B12);
const Color panel = Color(0xFF151A27);
const Color accent = Color(0xFF8B5CF6);

class AnimeSahabApp extends StatefulWidget {
  const AnimeSahabApp({super.key});

  @override
  State<AnimeSahabApp> createState() => _AnimeSahabAppState();
}

class _AnimeSahabAppState extends State<AnimeSahabApp> {
  bool english = true;

  void setLanguage(bool value) {
    setState(() => english = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anime Sahab',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.dark,
          surface: panel,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: HomePage(english: english, onLanguageChanged: setLanguage),
    );
  }
}

class T {
  final bool en;
  const T(this.en);

  String get app => en ? 'Anime Sahab' : 'أنمي سحاب';
  String get discover => en ? 'Discover anime' : 'اكتشف عالم الأنمي';
  String get subtitle => en
      ? 'Search anime titles in English or Arabic.'
      : 'ابحث بالعربي أو بالإنجليزي عن اسم الأنمي.';
  String get searchHint => en
      ? 'e.g. Naruto or Demon Slayer'
      : 'مثال: ناروتو أو Demon Slayer';
  String get search => en ? 'Search' : 'بحث';
  String get results => en ? 'Search results' : 'نتائج البحث';
  String get noResults => en
      ? 'No results. Try the English title or another spelling.'
      : 'لم تظهر نتائج. جرّب الاسم بالإنجليزية أو بصيغة أخرى.';
  String get licensed => en ? 'Licensed video sources' : 'مصادر الفيديو المرخّصة';
  String get noSources => en
      ? 'No video sources have been added yet. Add licensed links in assets/catalog.json.'
      : 'لا توجد مصادر فيديو مضافة بعد. أضف روابط مرخّصة داخل assets/catalog.json.';
  String get metadataNote => en
      ? 'Search provides anime information only. Full episodes require a licensed streaming provider.'
      : 'البحث يعرض معلومات الأنمي فقط. الحلقات الكاملة تحتاج مزوّد مشاهدة مرخّصاً.';
  String get details => en ? 'Anime details' : 'تفاصيل الأنمي';
  String get episodesUnknown => en ? 'Episode count unavailable' : 'عدد الحلقات غير محدد';
  String get episodes => en ? 'episodes' : 'حلقة';
  String get watchDownload => en ? 'Watch and download' : 'المشاهدة والتنزيل';
  String get rightsNote => en
      ? 'Anime metadata does not mean episodes are freely available. Add an authorized video provider to stream or download MP4.'
      : 'معلومات الأنمي لا تعني أن الحلقات متاحة مجاناً. أضف مزوّد فيديو مرخّصاً للمشاهدة أو تنزيل MP4.';
  String get watch => en ? 'Watch online' : 'مشاهدة أونلاين';
  String get download => en ? 'Download MP4 (authorized)' : 'تنزيل MP4 بشكل قانوني';
  String get noWatch => en
      ? 'No authorized watch URL has been added.'
      : 'لم تتم إضافة رابط مشاهدة مرخّص.';
  String get noDownload => en
      ? 'No authorized MP4 download URL has been added.'
      : 'لا يوجد رابط MP4 مرخّص للتنزيل.';
  String get playingError => en
      ? 'Could not play video. Check the URL and stream format.'
      : 'تعذر تشغيل الفيديو. تحقق من الرابط وصيغة البث.';
  String get downloadError => en
      ? 'Download failed. Check the URL and connection.'
      : 'فشل التنزيل. تحقق من الرابط والاتصال.';
  String get preparing => en ? 'Preparing video...' : 'جارٍ تجهيز الفيديو...';
  String get language => en ? 'العربية' : 'English';
  String get noDescription => en ? 'No description available.' : 'لا يوجد وصف متاح.';
  String get licensedRequired => en
      ? 'A licensed source is required.'
      : 'يلزم مصدر مشاهدة مرخّص.';
}

class AnimeTitle {
  final String id;
  final String romaji;
  final String english;
  final String native;
  final String? cover;
  final String? description;
  final int? episodes;

  AnimeTitle({
    required this.id,
    required this.romaji,
    required this.english,
    required this.native,
    this.cover,
    this.description,
    this.episodes,
  });

  factory AnimeTitle.fromJson(Map<String, dynamic> json) {
    final title = (json['title'] as Map<String, dynamic>?) ?? {};
    final coverImage = json['coverImage'] as Map<String, dynamic>?;

    return AnimeTitle(
      id: '${json['id'] ?? ''}',
      romaji: title['romaji'] as String? ?? '',
      english: title['english'] as String? ?? '',
      native: title['native'] as String? ?? '',
      cover: coverImage?['large'] as String?,
      description: json['description'] as String?,
      episodes: json['episodes'] as int?,
    );
  }

  String get displayTitle =>
      english.isNotEmpty ? english : (romaji.isNotEmpty ? romaji : native);
}

class AniListService {
  static const Map<String, String> aliases = {
    'ناروتو': 'Naruto',
    'دراغون بول': 'Dragon Ball',
    'دراجون بول': 'Dragon Ball',
    'قاتل الشياطين': 'Demon Slayer',
    'جوجوتسو كايسن': 'Jujutsu Kaisen',
    'ون بيس': 'One Piece',
    'هجوم العمالقة': 'Attack on Titan',
    'بليتش': 'Bleach',
    'هنتر x هنتر': 'Hunter x Hunter',
  };

  static Future<List<AnimeTitle>> search(String input) async {
    final normalized = input.trim();
    final query = aliases[normalized.toLowerCase()] ?? normalized;

    const graph = r'''
      query ($search: String) {
        Page(perPage: 20) {
          media(search: $search, type: ANIME, sort: SEARCH_MATCH) {
            id
            title { romaji english native }
            coverImage { large }
            description(asHtml: false)
            episodes
          }
        }
      }
    ''';

    final response = await http
        .post(
          Uri.parse('https://graphql.anilist.co'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'query': graph,
            'variables': {'search': query},
          }),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final media = json['data']?['Page']?['media'] as List? ?? [];
    return media
        .map((item) => AnimeTitle.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

class LicensedSource {
  final String id;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final String watchUrl;
  final String downloadUrl;

  LicensedSource.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String? ?? '',
        titleAr = json['title_ar'] as String? ?? '',
        titleEn = json['title_en'] as String? ?? '',
        descriptionAr = json['description_ar'] as String? ?? '',
        descriptionEn = json['description_en'] as String? ?? '',
        watchUrl = json['watch_url'] as String? ?? '',
        downloadUrl = json['mp4_download_url'] as String? ?? '';
}

class HomePage extends StatefulWidget {
  final bool english;
  final ValueChanged<bool> onLanguageChanged;

  const HomePage({
    super.key,
    required this.english,
    required this.onLanguageChanged,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController controller = TextEditingController();
  List<AnimeTitle> results = [];
  List<LicensedSource> sources = [];
  bool loading = false;
  String? error;
  String searched = '';

  T get t => T(widget.english);

  @override
  void initState() {
    super.initState();
    _loadSources();
  }

  Future<void> _loadSources() async {
    try {
      final raw = await rootBundle.loadString('assets/catalog.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final items = (json['sources'] as List? ?? [])
          .map((item) => LicensedSource.fromJson(item as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() => sources = items);
      }
    } catch (_) {
      // An empty catalog is valid; the interface will show the no-sources note.
    }
  }

  Future<void> _search() async {
    final query = controller.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      loading = true;
      error = null;
      results = [];
      searched = query;
    });

    try {
      final found = await AniListService.search(query);
      if (mounted) setState(() => results = found);
    } catch (_) {
      if (mounted) {
        setState(() {
          error = widget.english
              ? 'Search failed. Check your internet connection.'
              : 'فشل البحث. تحقق من اتصال الإنترنت.';
        });
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _openDetails(AnimeTitle anime) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => DetailsPage(
          anime: anime,
          sources: sources,
          english: widget.english,
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${t.results} (${results.length})',
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        for (final anime in results)
          AnimeCard(
            anime: anime,
            english: widget.english,
            onTap: () => _openDetails(anime),
          ),
      ],
    );
  }

  Widget _buildSources() {
    if (sources.isEmpty) {
      return Notice(text: t.noSources, icon: Icons.verified_user_outlined);
    }

    return Column(
      children: [
        for (final source in sources)
          Card(
            color: panel,
            child: ListTile(
              title: Text(widget.english ? source.titleEn : source.titleAr),
              subtitle: Text(
                widget.english ? source.descriptionEn : source.descriptionAr,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => PlayerPage(
                      source: source,
                      english: widget.english,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.english ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Icon(Icons.play_circle_fill_rounded, color: accent, size: 30),
              const SizedBox(width: 9),
              Text(t.app, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => widget.onLanguageChanged(!widget.english),
              child: Text(t.language),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  t.discover,
                  style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  t.subtitle,
                  style: TextStyle(color: Colors.white.withOpacity(0.65)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        textDirection: widget.english
                            ? TextDirection.ltr
                            : TextDirection.rtl,
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          hintText: t.searchHint,
                          prefixIcon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: loading ? null : _search,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 17,
                        ),
                      ),
                      child: Text(t.search),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                if (error != null)
                  Notice(text: error!, icon: Icons.wifi_off),
                if (!loading && searched.isNotEmpty && results.isEmpty && error == null)
                  Notice(text: t.noResults, icon: Icons.search_off),
                if (results.isNotEmpty) _buildResults(),
                const SizedBox(height: 26),
                Text(
                  t.licensed,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildSources(),
                const SizedBox(height: 16),
                Notice(text: t.metadataNote, icon: Icons.info_outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimeCard extends StatelessWidget {
  final AnimeTitle anime;
  final bool english;
  final VoidCallback onTap;

  const AnimeCard({
    super.key,
    required this.anime,
    required this.english,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget cover = anime.cover == null
        ? Container(
            width: 76,
            height: 104,
            color: Colors.white10,
            child: const Icon(Icons.movie),
          )
        : Image.network(
            anime.cover!,
            width: 76,
            height: 104,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 76,
              height: 104,
              color: Colors.white10,
              child: const Icon(Icons.broken_image),
            ),
          );

    return Card(
      color: panel,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: cover,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.displayTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (anime.romaji.isNotEmpty)
                      Text(
                        anime.romaji,
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),
                    const SizedBox(height: 5),
                    Text(
                      anime.episodes == null
                          ? (english ? 'Episode count unavailable' : 'عدد الحلقات غير محدد')
                          : '${anime.episodes} ${english ? 'episodes' : 'حلقة'}',
                    ),
                    const SizedBox(height: 5),
                    Text(
                      english
                          ? 'Tap for details and authorized sources'
                          : 'اضغط لعرض التفاصيل ومصادر المشاهدة المتاحة',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}

class DetailsPage extends StatelessWidget {
  final AnimeTitle anime;
  final List<LicensedSource> sources;
  final bool english;

  const DetailsPage({
    super.key,
    required this.anime,
    required this.sources,
    required this.english,
  });

  @override
  Widget build(BuildContext context) {
    final t = T(english);
    final description = (anime.description ?? '')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&');

    return Directionality(
      textDirection: english ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(t.details)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (anime.cover != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(anime.cover!, height: 250),
                ),
              ),
            const SizedBox(height: 18),
            Text(
              anime.displayTitle,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (anime.native.isNotEmpty) Text(anime.native),
            const SizedBox(height: 12),
            Text(description.isEmpty ? t.noDescription : description),
            const SizedBox(height: 22),
            Text(
              t.watchDownload,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Notice(text: t.rightsNote, icon: Icons.lock_outline),
            for (final source in sources)
              Card(
                color: panel,
                child: ListTile(
                  title: Text(english ? source.titleEn : source.titleAr),
                  subtitle: Text(t.licensedRequired),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => PlayerPage(
                          source: source,
                          english: english,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PlayerPage extends StatefulWidget {
  final LicensedSource source;
  final bool english;

  const PlayerPage({
    super.key,
    required this.source,
    required this.english,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? video;
  bool busy = false;
  String? message;

  T get t => T(widget.english);

  Future<void> play() async {
    final url = widget.source.watchUrl;
    if (!url.startsWith('https://')) {
      setState(() => message = t.noWatch);
      return;
    }

    setState(() {
      busy = true;
      message = null;
    });

    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      await controller.play();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      final oldController = video;
      setState(() => video = controller);
      await oldController?.dispose();
    } catch (_) {
      if (mounted) setState(() => message = t.playingError);
      await controller?.dispose();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> download() async {
    final url = widget.source.downloadUrl;
    if (!url.startsWith('https://')) {
      setState(() => message = t.noDownload);
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final safeName = widget.source.id.replaceAll(
        RegExp(r'[^a-zA-Z0-9_-]'),
        '_',
      );
      final path = '${directory.path}/$safeName.mp4';

      await Dio().download(
        url,
        path,
        options: Options(
          followRedirects: true,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
        ),
      );

      if (mounted) {
        setState(() {
          message = widget.english ? 'Saved MP4: $path' : 'تم حفظ ملف MP4: $path';
        });
      }
    } catch (_) {
      if (mounted) setState(() => message = t.downloadError);
    }
  }

  Widget _buildVideoSurface() {
    final currentVideo = video;
    if (currentVideo == null || !currentVideo.value.isInitialized) {
      return const Center(
        child: Icon(Icons.play_circle_outline, size: 76, color: accent),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(currentVideo),
          VideoProgressIndicator(currentVideo, allowScrubbing: true),
          Center(
            child: IconButton.filled(
              onPressed: () {
                setState(() {
                  if (currentVideo.value.isPlaying) {
                    currentVideo.pause();
                  } else {
                    currentVideo.play();
                  }
                });
              },
              icon: Icon(
                currentVideo.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: widget.english ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.english ? widget.source.titleEn : widget.source.titleAr),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _buildVideoSurface(),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: busy ? null : play,
              icon: const Icon(Icons.play_arrow),
              label: Text(busy ? t.preparing : t.watch),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: download,
              icon: const Icon(Icons.download),
              label: Text(t.download),
            ),
            if (message != null) ...[
              const SizedBox(height: 14),
              Notice(text: message!, icon: Icons.info_outline),
            ],
          ],
        ),
      ),
    );
  }
}

class Notice extends StatelessWidget {
  final String text;
  final IconData icon;

  const Notice({
    super.key,
    required this.text,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: panel,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
