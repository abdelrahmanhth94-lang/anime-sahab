import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

void main() => runApp(const AnimeSahabApp());

const bg = Color(0xFF090B12);
const panel = Color(0xFF151A27);
const accent = Color(0xFF8B5CF6);

class AnimeSahabApp extends StatefulWidget {
  const AnimeSahabApp({super.key});
  @override
  State<AnimeSahabApp> createState() => _AnimeSahabAppState();
}
class _AnimeSahabAppState extends State<AnimeSahabApp> {
  bool english = true;
  void setLanguage(bool value) => setState(() => english = value);
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Anime Sahab',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark, surface: panel),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: panel,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    ),
    home: HomePage(english: english, onLanguageChanged: setLanguage),
  );
}

class T {
  final bool en;
  const T(this.en);
  String get app => en ? 'Anime Sahab' : 'أنمي سحاب';
  String get discover => en ? 'Discover anime' : 'اكتشف عالم الأنمي';
  String get subtitle => en ? 'Search anime titles in English or Arabic.' : 'ابحث بالعربي أو بالإنجليزي عن اسم الأنمي.';
  String get searchHint => en ? 'e.g. Naruto or Demon Slayer' : 'مثال: ناروتو أو Demon Slayer';
  String get search => en ? 'Search' : 'بحث';
  String get results => en ? 'Search results' : 'نتائج البحث';
  String get noResults => en ? 'No results. Try the English title or another spelling.' : 'لم تظهر نتائج. جرّب الاسم بالإنجليزية أو بصيغة أخرى.';
  String get licensed => en ? 'Licensed video sources' : 'مصادر الفيديو المرخّصة';
  String get noSources => en ? 'No video sources have been added yet. Add licensed links in assets/catalog.json.' : 'لا توجد مصادر فيديو مضافة بعد. أضف روابط مرخّصة داخل assets/catalog.json.';
  String get metadataNote => en ? 'Search provides anime information only. Full episodes require a licensed streaming provider.' : 'البحث يعرض معلومات الأنمي فقط. الحلقات الكاملة تحتاج مزوّد مشاهدة مرخّصاً.';
  String get about => en ? 'About' : 'حول التطبيق';
  String get details => en ? 'Anime details' : 'تفاصيل الأنمي';
  String get episodesUnknown => en ? 'Episode count unavailable' : 'عدد الحلقات غير محدد';
  String get episodes => en ? 'episodes' : 'حلقة';
  String get watchDownload => en ? 'Watch and download' : 'المشاهدة والتنزيل';
  String get rightsNote => en ? 'Anime metadata does not mean episodes are freely available. Add an authorized video provider to stream or download MP4.' : 'معلومات الأنمي لا تعني أن الحلقات متاحة مجاناً. أضف مزوّد فيديو مرخّصاً للمشاهدة أو تنزيل MP4.';
  String get watch => en ? 'Watch online' : 'مشاهدة أونلاين';
  String get download => en ? 'Download MP4 (authorized)' : 'تنزيل MP4 بشكل قانوني';
  String get noWatch => en ? 'No authorized watch URL has been added.' : 'لم تتم إضافة رابط مشاهدة مرخّص.';
  String get noDownload => en ? 'No authorized MP4 download URL has been added.' : 'لا يوجد رابط MP4 مرخّص للتنزيل.';
  String get playingError => en ? 'Could not play video. Check the URL and stream format.' : 'تعذر تشغيل الفيديو. تحقق من الرابط وصيغة البث.';
  String get downloadError => en ? 'Download failed. Check the URL and connection.' : 'فشل التنزيل. تحقق من الرابط والاتصال.';
  String get preparing => en ? 'Preparing video...' : 'جارٍ تجهيز الفيديو...';
  String get language => en ? 'العربية' : 'English';
  String get noDescription => en ? 'No description available.' : 'لا يوجد وصف متاح.';
}

class AnimeTitle {
  final String id, romaji, english, native;
  final String? cover, description;
  final int? episodes;
  AnimeTitle({required this.id, required this.romaji, required this.english, required this.native, this.cover, this.description, this.episodes});
  factory AnimeTitle.fromJson(Map<String, dynamic> j) {
    final t = (j['title'] ?? {}) as Map<String, dynamic>;
    return AnimeTitle(id: '${j['id']}', romaji: t['romaji'] ?? '', english: t['english'] ?? '', native: t['native'] ?? '',
      cover: j['coverImage']?['large'], description: j['description'], episodes: j['episodes']);
  }
  String get displayTitle => english.isNotEmpty ? english : (romaji.isNotEmpty ? romaji : native);
}

class AniListService {
  static const aliases = <String, String>{
    'ناروتو': 'Naruto', 'دراغون بول': 'Dragon Ball', 'دراجون بول': 'Dragon Ball',
    'قاتل الشياطين': 'Demon Slayer', 'جوجوتسو كايسن': 'Jujutsu Kaisen',
    'ون بيس': 'One Piece', 'هجوم العمالقة': 'Attack on Titan',
    'بليتش': 'Bleach', 'هنتر x هنتر': 'Hunter x Hunter'
  };
  static Future<List<AnimeTitle>> search(String input) async {
    final query = aliases[input.trim().toLowerCase()] ?? input.trim();
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
    final r = await http.post(Uri.parse('https://graphql.anilist.co'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'query': graph, 'variables': {'search': query}})).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final media = j['data']?['Page']?['media'] as List? ?? [];
    return media.map((e) => AnimeTitle.fromJson(e as Map<String, dynamic>)).toList();
  }
}

class LicensedSource {
  final String id, titleAr, titleEn, descriptionAr, descriptionEn, watchUrl, downloadUrl;
  LicensedSource.fromJson(Map<String, dynamic> j)
    : id = j['id'] ?? '', titleAr = j['title_ar'] ?? '', titleEn = j['title_en'] ?? '',
      descriptionAr = j['description_ar'] ?? '', descriptionEn = j['description_en'] ?? '',
      watchUrl = j['watch_url'] ?? '', downloadUrl = j['mp4_download_url'] ?? '';
}

class HomePage extends StatefulWidget {
  final bool english;
  final ValueChanged<bool> onLanguageChanged;
  const HomePage({super.key, required this.english, required this.onLanguageChanged});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final controller = TextEditingController();
  List<AnimeTitle> results = [];
  List<LicensedSource> sources = [];
  bool loading = false;
  String? error;
  String searched = '';
  T get t => T(widget.english);

  @override
  void initState() { super.initState(); _loadSources(); }
  Future<void> _loadSources() async {
    try {
      final raw = await DefaultAssetBundle.of(context).loadString('assets/catalog.json');
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (mounted) setState(() => sources = (j['sources'] as List).map((e) => LicensedSource.fromJson(e)).toList());
    } catch (_) {}
  }
  Future<void> _search() async {
    final q = controller.text.trim(); if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() { loading = true; error = null; results = []; searched = q; });
    try { final found = await AniListService.search(q); if (mounted) setState(() => results = found); }
    catch (e) { if (mounted) setState(() => error = widget.english ? 'Search failed. Check your internet connection.' : 'فشل البحث. تحقق من اتصال الإنترنت.'); }
    finally { if (mounted) setState(() => loading = false); }
  }
  @override
  void dispose() { controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: widget.english ? TextDirection.ltr : TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: Row(children: [const Icon(Icons.play_circle_fill_rounded, color: accent, size: 30), const SizedBox(width: 9), Text(t.app, style: const TextStyle(fontWeight: FontWeight.bold))]),
        actions: [TextButton(onPressed: () => widget.onLanguageChanged(!widget.english), child: Text(t.language)), const SizedBox(width: 8)]),
      body: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1000), child: ListView(padding: const EdgeInsets.all(20), children: [
        Text(t.discover, style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8), Text(t.subtitle, style: TextStyle(color: Colors.white.withOpacity(.65))),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: TextField(controller: controller, textDirection: TextDirection.auto, onSubmitted: (_) => _search(), decoration: InputDecoration(hintText: t.searchHint, prefixIcon: const Icon(Icons.search)))),
          const SizedBox(width: 10),
          FilledButton(onPressed: loading ? null : _search, style: FilledButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17)), child: Text(t.search))
        ]),
        const SizedBox(height: 24),
        if (loading) const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator())),
        if (error != null) Notice(text: error!, icon: Icons.wifi_off),
        if (!loading && searched.isNotEmpty && results.isEmpty && error == null) Notice(text: t.noResults, icon: Icons.search_off),
        if (results.isNotEmpty) ...[
          Text('${t.results} (${results.length})', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...results.map((a) => AnimeCard(anime: a, english: widget.english, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsPage(anime: a, sources: sources, english: widget.english)))))
        ],
        const SizedBox(height: 26),
        Text(t.licensed, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (sources.isEmpty) Notice(text: t.noSources, icon: Icons.verified_user_outlined)
        else ...sources.map((s) => Card(color: panel, child: ListTile(title: Text(widget.english ? s.titleEn : s.titleAr), subtitle: Text(widget.english ? s.descriptionEn : s.descriptionAr), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerPage(source: s, english: widget.english))))),
        const SizedBox(height: 16), Notice(text: t.metadataNote, icon: Icons.info_outline)
      ]))),
    ),
  );
}

class AnimeCard extends StatelessWidget {
  final AnimeTitle anime; final bool english; final VoidCallback onTap;
  const AnimeCard({super.key, required this.anime, required this.english, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(color: panel, margin: const EdgeInsets.only(bottom: 10), child: InkWell(borderRadius: BorderRadius.circular(12), onTap: onTap,
    child: Padding(padding: const EdgeInsets.all(10), child: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(9), child: anime.cover == null ? Container(width: 76, height: 104, color: Colors.white10, child: const Icon(Icons.movie)) :
        Image.network(anime.cover!, width: 76, height: 104, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 76, height: 104, color: Colors.white10, child: const Icon(Icons.broken_image)))),
      const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(anime.displayTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        if (anime.romaji.isNotEmpty) Text(anime.romaji, style: TextStyle(color: Colors.white.withOpacity(.6))),
        const SizedBox(height: 5), Text(anime.episodes == null ? (english ? 'Episode count unavailable' : 'عدد الحلقات غير محدد') : '${anime.episodes} ${english ? 'episodes' : 'حلقة'}'),
        const SizedBox(height: 5), Text(english ? 'Tap for details and authorized sources' : 'اضغط لعرض التفاصيل ومصادر المشاهدة المتاحة', style: TextStyle(color: Colors.white.withOpacity(.55), fontSize: 12))
      ])), const Icon(Icons.chevron_right, color: Colors.white54)
    ]))));
}

class DetailsPage extends StatelessWidget {
  final AnimeTitle anime; final List<LicensedSource> sources; final bool english;
  const DetailsPage({super.key, required this.anime, required this.sources, required this.english});
  @override
  Widget build(BuildContext context) {
    final t = T(english);
    final desc = (anime.description ?? '').replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&quot;', '"').replaceAll('&amp;', '&');
    return Directionality(textDirection: english ? TextDirection.ltr : TextDirection.rtl, child: Scaffold(appBar: AppBar(title: Text(t.details)),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        if (anime.cover != null) Center(child: ClipRRect(borderRadius: BorderRadius.circular(14), child: Image.network(anime.cover!, height: 250))),
        const SizedBox(height: 18), Text(anime.displayTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        if (anime.native.isNotEmpty) Text(anime.native), const SizedBox(height: 12), Text(desc.isEmpty ? t.noDescription : desc),
        const SizedBox(height: 22), Text(t.watchDownload, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8), Notice(text: t.rightsNote, icon: Icons.lock_outline),
        ...sources.map((s) => Card(color: panel, child: ListTile(title: Text(english ? s.titleEn : s.titleAr), subtitle: Text('Licensed source required'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerPage(source: s, english: english)))))
      ])));
  }
}

class PlayerPage extends StatefulWidget {
  final LicensedSource source; final bool english;
  const PlayerPage({super.key, required this.source, required this.english});
  @override
  State<PlayerPage> createState() => _PlayerPageState();
}
class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? video; bool busy = false; String? message;
  T get t => T(widget.english);
  Future<void> play() async {
    final url = widget.source.watchUrl;
    if (!url.startsWith('https://')) { setState(() => message = t.noWatch); return; }
    setState(() { busy = true; message = null; });
    try {
      final c = VideoPlayerController.networkUrl(Uri.parse(url)); await c.initialize(); await c.play();
      if (!mounted) { await c.dispose(); return; } await video?.dispose(); setState(() => video = c);
    } catch (_) { setState(() => message = t.playingError); }
    finally { if (mounted) setState(() => busy = false); }
  }
  Future<void> download() async {
    final url = widget.source.downloadUrl;
    if (!url.startsWith('https://')) { setState(() => message = t.noDownload); return; }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final safe = widget.source.id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final path = '${dir.path}/$safe.mp4';
      await Dio().download(url, path, options: Options(followRedirects: true, validateStatus: (s) => s != null && s >= 200 && s < 400));
      if (mounted) setState(() => message = widget.english ? 'Saved MP4: $path' : 'تم حفظ ملف MP4: $path');
    } catch (_) { if (mounted) setState(() => message = t.downloadError); }
  }
  @override
  void dispose() { video?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Directionality(textDirection: widget.english ? TextDirection.ltr : TextDirection.rtl,
    child: Scaffold(appBar: AppBar(title: Text(widget.english ? widget.source.titleEn : widget.source.titleAr)),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        AspectRatio(aspectRatio: 16/9, child: Container(decoration: BoxDecoration(color: panel, borderRadius: BorderRadius.circular(16)),
          child: video != null && video!.value.isInitialized ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Stack(alignment: Alignment.bottomCenter, children: [
            VideoPlayer(video!), VideoProgressIndicator(video!, allowScrubbing: true),
            Center(child: IconButton.filled(onPressed: () => setState(() => video!.value.isPlaying ? video!.pause() : video!.play()), icon: Icon(video!.value.isPlaying ? Icons.pause : Icons.play_arrow)))
          ])) : const Center(child: Icon(Icons.play_circle_outline, size: 76, color: accent)))),
        const SizedBox(height: 18), FilledButton.icon(onPressed: busy ? null : play, icon: const Icon(Icons.play_arrow), label: Text(busy ? t.preparing : t.watch)),
        const SizedBox(height: 10), OutlinedButton.icon(onPressed: download, icon: const Icon(Icons.download), label: Text(t.download)),
        if (message != null) ...[const SizedBox(height: 14), Notice(text: message!, icon: Icons.info_outline)]
      ])));
  }
}

class Notice extends StatelessWidget {
  final String text; final IconData icon;
  const Notice({super.key, required this.text, required this.icon});
  @override
  Widget build(BuildContext context) => Card(color: panel, child: Padding(padding: const EdgeInsets.all(16),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: accent), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(height: 1.5)))])));
}
