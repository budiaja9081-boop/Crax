import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

typedef Log = void Function(String);

class ScanItem {
  final String label;
  final String value;
  final String level; // high | medium | low | info | ok
  const ScanItem(this.label, this.value, [this.level = 'info']);
}

class WebForm {
  final String method;
  final Uri action;
  final List<String> inputs;
  WebForm(this.method, this.action, this.inputs);
}

class Crawled {
  final List<ScanItem> pages;
  final Set<Uri> paramUrls;
  final List<WebForm> forms;
  final Set<String> scripts;
  Crawled(this.pages, this.paramUrls, this.forms, this.scripts);
}

const _ua = 'Mozilla/5.0 (Crax Security Toolkit; authorized testing)';

Uri toUri(String t) {
  var s = t.trim();
  if (!s.startsWith('http://') && !s.startsWith('https://')) s = 'https://$s';
  return Uri.parse(s);
}

Future<http.Response?> fetch(
  Uri u, {
  String method = 'GET',
  Map<String, String> headers = const {},
  Map<String, String>? form,
  bool follow = true,
  int secs = 10,
}) async {
  try {
    final req = http.Request(method, u)..followRedirects = follow;
    req.headers['User-Agent'] = _ua;
    req.headers.addAll(headers);
    if (form != null) req.bodyFields = form;
    final s = await req.send().timeout(Duration(seconds: secs));
    return await http.Response.fromStream(s);
  } catch (_) {
    return null;
  }
}

String _levelFor(String code) {
  if (code.startsWith('2')) return 'ok';
  if (code.startsWith('3')) return 'info';
  if (code.startsWith('4')) return 'low';
  if (code.startsWith('5')) return 'medium';
  return 'low';
}

String _pathLabel(Uri u) {
  final p = u.path.isEmpty ? '/' : u.path;
  return u.hasQuery ? '$p?${u.query}' : p;
}

// ================= SUBDOMAIN =================

Future<List<String>> _crt(String d) async {
  final r = await fetch(Uri.parse('https://crt.sh/?q=%25.$d&output=json'), secs: 30);
  if (r == null || r.statusCode != 200) return [];
  try {
    final out = <String>[];
    for (final row in jsonDecode(r.body) as List) {
      out.addAll(((row['name_value'] ?? '') as String).split('\n'));
    }
    return out;
  } catch (_) {
    return [];
  }
}

Future<List<String>> _hackerTarget(String d) async {
  final r = await fetch(Uri.parse('https://api.hackertarget.com/hostsearch/?q=$d'), secs: 20);
  if (r == null || r.statusCode != 200) return [];
  return [
    for (final line in r.body.split('\n'))
      if (line.contains(',')) line.split(',').first,
  ];
}

Future<List<String>> _otx(String d) async {
  final r = await fetch(
    Uri.parse('https://otx.alienvault.com/api/v1/indicators/domain/$d/passive_dns'),
    secs: 20,
  );
  if (r == null || r.statusCode != 200) return [];
  try {
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    final list = (j['passive_dns'] as List?) ?? [];
    return [for (final e in list) ((e as Map)['hostname'] ?? '') as String];
  } catch (_) {
    return [];
  }
}

Future<String> _status(String url) async {
  final r = await fetch(Uri.parse(url), secs: 6);
  return r == null ? 'timeout' : '${r.statusCode}';
}

Future<List<ScanItem>> subdomains(String target, Log log) async {
  final d = toUri(target).host;
  final sources = <ScanItem>[];
  final all = <String>{};

  Future<void> source(String name, Future<List<String>> Function() get) async {
    log('Ambil dari $name...');
    final got = (await get())
        .map((s) => s.trim().toLowerCase().replaceFirst('*.', ''))
        .where((s) => s.isNotEmpty && s.endsWith(d))
        .toSet();
    all.addAll(got);
    sources.add(ScanItem(
      'Sumber $name',
      got.isEmpty ? 'kosong / gagal diakses' : '${got.length} entri',
      got.isEmpty ? 'low' : 'ok',
    ));
  }

  await source('crt.sh', () => _crt(d));
  await source('HackerTarget', () => _hackerTarget(d));
  await source('AlienVault OTX', () => _otx(d));

  final list = all.toList()..sort();
  log('${list.length} subdomain unik. Cek status code...');
  final results = <ScanItem>[];
  for (var i = 0; i < list.length; i += 10) {
    final chunk = list.sublist(i, min(i + 10, list.length));
    final codes = await Future.wait(chunk.map((s) => _status('https://$s')));
    for (var j = 0; j < chunk.length; j++) {
      final v = codes[j] == 'timeout' ? 'tidak merespons' : 'HTTP ${codes[j]}';
      results.add(ScanItem(chunk[j], v, _levelFor(codes[j])));
    }
  }
  return [
    ScanItem('Ringkasan', '${list.length} subdomain unik dari 3 sumber', 'info'),
    ...sources,
    ...results,
  ];
}

// ================= CRAWLER =================

final _hrefRe = RegExp(r'''href\s*=\s*["']([^"'#>\s]+)''', caseSensitive: false);
final _formRe = RegExp(r'<form[\s\S]*?</form>', caseSensitive: false);
final _nameRe = RegExp(r'''name\s*=\s*["']([^"']+)''', caseSensitive: false);
final _actionRe = RegExp(r'''action\s*=\s*["']([^"']*)''', caseSensitive: false);
final _methodRe = RegExp(r'''method\s*=\s*["']([^"']+)''', caseSensitive: false);
final _scriptRe = RegExp(r'''<script[^>]+src\s*=\s*["']([^"']+)''', caseSensitive: false);

Future<Crawled> crawlSite(String target, Log log, {int max = 25}) async {
  final start = toUri(target);
  final queue = <Uri>[start];
  final seen = <String>{};
  final pages = <ScanItem>[];
  final params = <Uri>{};
  final forms = <WebForm>[];
  final scripts = <String>{};

  while (queue.isNotEmpty && seen.length < max) {
    final u = queue.removeAt(0).replace(fragment: '');
    if (!seen.add(u.toString())) continue;
    log('[${seen.length}/$max] $u');

    final r = await fetch(u);
    if (r == null) {
      pages.add(ScanItem(_pathLabel(u), 'tidak merespons', 'low'));
      continue;
    }
    pages.add(ScanItem(_pathLabel(u), 'HTTP ${r.statusCode}', _levelFor('${r.statusCode}')));
    if (!(r.headers['content-type'] ?? '').contains('html')) continue;

    final body = r.body;
    for (final m in _hrefRe.allMatches(body)) {
      final link = u.resolve(m.group(1)!).replace(fragment: '');
      if ((link.scheme == 'http' || link.scheme == 'https') && link.host == start.host) {
        queue.add(link);
        if (link.hasQuery) params.add(link);
      }
    }
    for (final m in _formRe.allMatches(body)) {
      final block = m.group(0)!;
      final method = (_methodRe.firstMatch(block)?.group(1) ?? 'GET').toUpperCase();
      final action = u.resolve(_actionRe.firstMatch(block)?.group(1) ?? '');
      final inputs = [for (final n in _nameRe.allMatches(block)) n.group(1)!];
      forms.add(WebForm(method, action, inputs));
    }
    for (final m in _scriptRe.allMatches(body)) {
      scripts.add(u.resolve(m.group(1)!).toString());
    }
  }
  return Crawled(pages, params, forms, scripts);
}

Future<List<ScanItem>> crawlerReport(String target, Log log) async {
  final c = await crawlSite(target, log);
  return [
    ScanItem('Ringkasan',
        '${c.pages.length} halaman, ${c.forms.length} form, ${c.paramUrls.length} URL berparameter',
        'info'),
    for (final p in c.pages) ScanItem('[HALAMAN] ${p.label}', p.value, p.level),
    for (final f in c.forms)
      ScanItem('[FORM ${f.method}]', '${f.action}\ninput: ${f.inputs.join(', ')}', 'info'),
    for (final u in c.paramUrls) ScanItem('[PARAMETER]', u.toString(), 'info'),
    for (final s in c.scripts) ScanItem('[SCRIPT]', s, 'info'),
  ];
}

// ================= XSS DETECTOR =================

Future<List<ScanItem>> xssDetect(String target, Log log) async {
  final c = await crawlSite(target, log, max: 15);
  final marker = 'crax${Random().nextInt(99999)}';
  final probe = '$marker"\'<>';
  final out = <ScanItem>[];
  var tests = 0;
  var hits = 0;

  Future<void> check(String method, Uri action, Map<String, String> data, String label) async {
    if (tests >= 40) return;
    tests++;
    log('Tes $label');
    final url = method == 'POST'
        ? action
        : action.replace(queryParameters: {...action.queryParameters, ...data});
    final r = method == 'POST'
        ? await fetch(action, method: 'POST', form: data)
        : await fetch(url);
    if (r == null || !(r.headers['content-type'] ?? '').contains('html')) return;

    final body = r.body;
    final idx = body.indexOf(probe);
    if (idx < 0) return;
    hits++;
    final from = max(0, idx - 60);
    final to = min(body.length, idx + probe.length + 60);
    final snippet = body.substring(from, to).replaceAll(RegExp(r'\s+'), ' ');
    out.add(ScanItem(
      'KANDIDAT XSS (refleksi tanpa encoding)',
      'Metode: $method\nURL: $url\nData: $data\nPayload uji: $probe\nBukti: ...$snippet...',
      'high',
    ));
  }

  for (final u in c.paramUrls) {
    for (final name in u.queryParameters.keys) {
      await check('GET', u, {name: probe}, 'GET ${u.path} ?$name');
    }
  }
  for (final f in c.forms) {
    if (f.inputs.isEmpty) continue;
    await check(
      f.method,
      f.action,
      {for (final i in f.inputs) i: probe},
      '${f.method} ${f.action.path} [form]',
    );
  }

  out.insert(
    0,
    ScanItem(
      'Ringkasan',
      '$tests titik input diuji, $hits kandidat. Payload uji hanya penanda dan karakter pembatas, bukan kode eksekusi. Buka URL di browser untuk memastikan karakter < > dan tanda kutip muncul utuh.',
      'info',
    ),
  );
  if (hits == 0) {
    out.add(const ScanItem('Hasil', 'Tidak ada refleksi tanpa encoding dari titik input yang diuji', 'ok'));
  }
  return out;
}

// ================= CRAX SCAN =================

const _wantHeaders = <(String, String, String, String)>[
  ('strict-transport-security', 'HSTS tidak ada', 'Koneksi bisa diturunkan ke HTTP', 'medium'),
  ('content-security-policy', 'CSP tidak ada', 'Dampak XSS jadi jauh lebih besar', 'medium'),
  ('x-content-type-options', 'X-Content-Type-Options tidak ada', 'Browser bisa menebak tipe file sendiri', 'low'),
  ('referrer-policy', 'Referrer-Policy tidak ada', 'URL halaman bisa bocor ke situs lain', 'low'),
  ('permissions-policy', 'Permissions-Policy tidak ada', 'Fitur browser tidak dibatasi', 'low'),
];

// (path, level, catatan)
const _paths = <(String, String, String)>[
  ('/.git/HEAD', 'high', 'Repo git bocor'),
  ('/.git/config', 'high', 'Konfigurasi git bocor'),
  ('/.svn/entries', 'high', 'Metadata SVN bocor'),
  ('/.env', 'high', 'File environment / kredensial'),
  ('/.env.local', 'high', 'File environment lokal'),
  ('/.npmrc', 'high', 'Token npm bisa bocor'),
  ('/.aws/credentials', 'high', 'Kredensial AWS'),
  ('/id_rsa', 'high', 'Private key SSH'),
  ('/.htpasswd', 'high', 'Hash password basic auth'),
  ('/.htaccess', 'medium', 'Konfigurasi server'),
  ('/.DS_Store', 'medium', 'Daftar file folder'),
  ('/backup.zip', 'high', 'Arsip backup'),
  ('/site.zip', 'high', 'Arsip website'),
  ('/backup.sql', 'high', 'Dump database'),
  ('/dump.sql', 'high', 'Dump database'),
  ('/db.sql', 'high', 'Dump database'),
  ('/wp-config.php.bak', 'high', 'Backup config WordPress'),
  ('/config.php.bak', 'high', 'Backup config PHP'),
  ('/config.json', 'medium', 'Konfigurasi aplikasi'),
  ('/web.config', 'medium', 'Konfigurasi IIS'),
  ('/phpinfo.php', 'high', 'Info PHP lengkap'),
  ('/info.php', 'high', 'Info PHP lengkap'),
  ('/server-status', 'medium', 'Status server Apache'),
  ('/server-info', 'medium', 'Info server Apache'),
  ('/debug', 'medium', 'Halaman debug'),
  ('/admin', 'low', 'Panel admin'),
  ('/administrator', 'low', 'Panel admin'),
  ('/wp-admin', 'low', 'Panel admin WordPress'),
  ('/phpmyadmin', 'medium', 'Panel database'),
  ('/adminer.php', 'medium', 'Panel database'),
  ('/test.php', 'low', 'File test tertinggal'),
  ('/composer.json', 'medium', 'Daftar dependensi PHP'),
  ('/package.json', 'low', 'Daftar dependensi Node'),
  ('/Dockerfile', 'medium', 'Konfigurasi container'),
  ('/docker-compose.yml', 'medium', 'Konfigurasi container'),
  ('/swagger.json', 'low', 'Dokumentasi API'),
  ('/openapi.json', 'low', 'Dokumentasi API'),
  ('/api/docs', 'low', 'Dokumentasi API'),
  ('/graphql', 'low', 'Endpoint GraphQL'),
  ('/crossdomain.xml', 'low', 'Kebijakan lintas domain'),
  ('/robots.txt', 'info', 'Cek path yang disembunyikan'),
  ('/sitemap.xml', 'info', 'Peta situs'),
  ('/.well-known/security.txt', 'info', 'Kontak keamanan'),
];

const _sqlSigs = [
  'you have an error in your sql',
  'sql syntax',
  'mysql_fetch',
  'unclosed quotation mark',
  'pg_query',
  'postgresql',
  'sqlite3::',
  'ora-00',
  'microsoft ole db',
  'syntax error at or near',
];

Future<List<ScanItem>> _headers(Uri base) async {
  final r = await fetch(base);
  if (r == null) return [const ScanItem('Homepage', 'Tidak merespons', 'high')];
  final h = {for (final e in r.headers.entries) e.key.toLowerCase(): e.value};
  final out = <ScanItem>[];

  for (final w in _wantHeaders) {
    if (!h.containsKey(w.$1)) out.add(ScanItem(w.$2, w.$3, w.$4));
  }
  final csp = h['content-security-policy'] ?? '';
  if (!h.containsKey('x-frame-options') && !csp.contains('frame-ancestors')) {
    out.add(const ScanItem('Rentan clickjacking', 'Tidak ada X-Frame-Options maupun frame-ancestors', 'medium'));
  }
  final sc = (h['set-cookie'] ?? '').toLowerCase();
  if (sc.isNotEmpty) {
    if (!sc.contains('httponly')) {
      out.add(const ScanItem('Cookie tanpa HttpOnly', 'JavaScript bisa membaca cookie', 'medium'));
    }
    if (!sc.contains('secure')) {
      out.add(const ScanItem('Cookie tanpa Secure', 'Cookie bisa lewat HTTP biasa', 'medium'));
    }
    if (!sc.contains('samesite')) {
      out.add(const ScanItem('Cookie tanpa SameSite', 'Rentan CSRF pada sebagian skenario', 'low'));
    }
  }
  if (h.containsKey('server')) out.add(ScanItem('Server terekspos', h['server']!, 'low'));
  if (h.containsKey('x-powered-by')) {
    out.add(ScanItem('X-Powered-By terekspos', h['x-powered-by']!, 'low'));
  }
  return out;
}

Future<ScanItem> _redirect(String host) async {
  final r = await fetch(Uri.parse('http://$host'), follow: false, secs: 8);
  if (r == null) return const ScanItem('HTTP ke HTTPS', 'Tidak bisa dicek', 'info');
  final loc = r.headers['location'] ?? '';
  if (r.statusCode >= 300 && r.statusCode < 400 && loc.startsWith('https://')) {
    return const ScanItem('HTTP ke HTTPS', 'Dialihkan ke HTTPS', 'ok');
  }
  return ScanItem('HTTP tidak dialihkan ke HTTPS',
      'HTTP ${r.statusCode}, versi tidak terenkripsi masih bisa diakses', 'medium');
}

Future<List<ScanItem>> _cors(Uri base) async {
  const test = 'https://crax-cors-test.invalid';
  final r = await fetch(base, headers: {'Origin': test}, secs: 8);
  if (r == null) return [];
  final acao = r.headers['access-control-allow-origin'];
  final cred = (r.headers['access-control-allow-credentials'] ?? '').toLowerCase() == 'true';
  if (acao == null) return [];
  if (acao == test) {
    final extra = cred ? ' DENGAN credentials' : '';
    return [
      ScanItem('CORS memantulkan Origin asing',
          'Server mengizinkan origin sembarang$extra', cred ? 'high' : 'medium'),
    ];
  }
  if (acao == '*') {
    return [const ScanItem('CORS wildcard', 'Semua origin bisa membaca respons', 'low')];
  }
  return [];
}

Future<ScanItem> _trace(Uri base) async {
  final r = await fetch(base, method: 'TRACE', secs: 8);
  if (r != null && r.statusCode == 200 && r.body.toUpperCase().contains('TRACE')) {
    return const ScanItem('HTTP TRACE aktif',
        'Method TRACE dibalas 200, bisa dipakai untuk membaca header sensitif', 'medium');
  }
  return const ScanItem('HTTP TRACE', 'Tidak aktif / ditolak', 'ok');
}

Future<List<ScanItem>> _sqlProbe(Crawled c, Log log) async {
  final out = <ScanItem>[];
  var n = 0;
  for (final u in c.paramUrls) {
    if (n >= 15) break;
    n++;
    for (final name in u.queryParameters.keys) {
      log('Cek error SQL di $name');
      final probeUrl = u.replace(queryParameters: {...u.queryParameters, name: "'"});
      final r = await fetch(probeUrl, secs: 8);
      if (r == null) continue;
      final low = r.body.toLowerCase();
      final sig = _sqlSigs.where((s) => low.contains(s)).toList();
      if (sig.isNotEmpty) {
        out.add(ScanItem(
          'KANDIDAT SQLi (error-based)',
          'URL: $probeUrl\nParameter: $name\nPayload uji: \'\nSignature: ${sig.first}',
          'high',
        ));
      }
    }
  }
  return out;
}

Future<List<ScanItem>> craxScan(String target, Log log) async {
  final base = toUri(target);
  final port = base.hasPort ? ':${base.port}' : '';
  final origin = '${base.scheme}://${base.host}$port';
  final out = <ScanItem>[];

  log('Cek header & cookie...');
  out.addAll(await _headers(base));
  log('Cek redirect HTTP...');
  out.add(await _redirect(base.host));
  log('Cek CORS...');
  out.addAll(await _cors(base));
  log('Cek HTTP TRACE...');
  out.add(await _trace(base));

  log('Cek soft-404...');
  final probe = await fetch(Uri.parse('$origin/crax-${Random().nextInt(99999999)}'), secs: 8);
  if (probe?.statusCode == 200) {
    out.add(const ScanItem('Soft-404',
        'Server membalas 200 untuk path acak, pengecekan path dilewati', 'low'));
  } else {
    for (var i = 0; i < _paths.length; i += 8) {
      final chunk = _paths.sublist(i, min(i + 8, _paths.length));
      log('Cek path ${i + 1}-${i + chunk.length} dari ${_paths.length}');
      final res = await Future.wait(
        chunk.map((p) => fetch(Uri.parse('$origin${p.$1}'), secs: 8)),
      );
      for (var j = 0; j < chunk.length; j++) {
        final r = res[j];
        if (r != null && r.statusCode == 200 && r.bodyBytes.isNotEmpty) {
          out.add(ScanItem('Terbuka: ${chunk[j].$1}',
              '${chunk[j].$3} (HTTP 200)', chunk[j].$2));
        }
      }
    }
  }

  log('Cek error SQL...');
  final c = await crawlSite(target, log, max: 12);
  out.addAll(await _sqlProbe(c, log));

  final highs = out.where((i) => i.level == 'high').length;
  out.insert(0, ScanItem(
    'Ringkasan',
    '${out.length} temuan, $highs prioritas tinggi. Ini indikator awal, verifikasi manual sebelum melapor.',
    'info',
  ));
  return out;
}

// ================= WIFI INFO =================

const _commonPass = {
  '12345678', 'password', 'password123', '00000000', '11111111',
  'qwerty123', '12341234', 'rahasia123', 'indonesia', 'admin1234',
};

Future<List<ScanItem>> wifiCheck(String raw, Log log) async {
  final s = raw.trim();
  if (!s.toUpperCase().startsWith('WIFI:')) {
    return const [
      ScanItem('Format', 'Tempel string QR WiFi, contoh: WIFI:T:WPA;S:Rumah;P:pass123;;', 'high'),
    ];
  }
  var ssid = '-';
  var enc = '';
  var pass = '';
  for (final part in s.substring(5).split(';')) {
    final i = part.indexOf(':');
    if (i <= 0) continue;
    final k = part.substring(0, i).toUpperCase();
    final v = part.substring(i + 1);
    if (k == 'S') ssid = v;
    if (k == 'T') enc = v.toUpperCase();
    if (k == 'P') pass = v;
  }
  log('Menganalisis konfigurasi...');

  final out = <ScanItem>[ScanItem('SSID', ssid, 'info')];

  String encLevel;
  String encNote;
  if (enc.isEmpty || enc == 'NOPASS') {
    encLevel = 'high';
    encNote = 'Tanpa password, siapa pun di sekitar bisa terhubung';
  } else if (enc == 'WEP') {
    encLevel = 'high';
    encNote = 'WEP sudah rusak dan bisa dibobol dalam hitungan menit';
  } else if (enc == 'WPA') {
    encLevel = 'medium';
    encNote = 'WPA1 sudah usang, pakai WPA2-AES atau WPA3';
  } else {
    encLevel = 'ok';
    encNote = 'Enkripsi modern ($enc)';
  }
  out.add(ScanItem('Keamanan enkripsi', encNote, encLevel));

  if (enc.isNotEmpty && enc != 'NOPASS') {
    final issues = <String>[];
    if (pass.length < 8) issues.add('kurang dari 8 karakter');
    else if (pass.length < 12) issues.add('di bawah 12 karakter');
    final classes = [
      RegExp(r'[a-z]'), RegExp(r'[A-Z]'), RegExp(r'[0-9]'), RegExp(r'[^a-zA-Z0-9]'),
    ].where((r) => r.hasMatch(pass)).length;
    if (classes < 3) issues.add('variasi karakter rendah');
    final isCommon = _commonPass.contains(pass.toLowerCase());
    if (isCommon) issues.add('termasuk password umum');

    final level = (pass.length < 8 || isCommon) ? 'high' : (issues.isEmpty ? 'ok' : 'medium');
    out.add(ScanItem(
      'Kekuatan password',
      issues.isEmpty ? 'Cukup kuat (${pass.length} karakter)' : issues.join(', '),
      level,
    ));
  }

  if (RegExp(r'^(TP-LINK|IndiHome|ZTE|Huawei|MERCUSYS|D-Link|Tenda|Linksys|NETGEAR|ASUS)',
          caseSensitive: false)
      .hasMatch(ssid)) {
    out.add(const ScanItem('SSID bawaan pabrik',
        'Nama ini menunjukkan merek router, ganti supaya tidak mudah ditebak', 'medium'));
  }

  out.addAll(const [
    ScanItem('Checklist 1', 'Matikan WPS di pengaturan router', 'info'),
    ScanItem('Checklist 2', 'Ganti password admin router (bukan password WiFi)', 'info'),
    ScanItem('Checklist 3', 'Update firmware router ke versi terbaru', 'info'),
    ScanItem('Checklist 4', 'Pakai WPA2-AES atau WPA3, nonaktifkan TKIP', 'info'),
    ScanItem('Checklist 5', 'Buat guest network untuk tamu', 'info'),
    ScanItem('Checklist 6', 'Cek daftar perangkat terhubung dan hapus yang tidak dikenal', 'info'),
    ScanItem('Batasan', 'Aplikasi tidak bisa memindai WiFi orang lain atau cek WPS dari jarak jauh', 'info'),
  ]);
  return out;
}
