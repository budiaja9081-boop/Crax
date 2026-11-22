import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class Hashes {
  static Map<String, String> of(String text) {
    final b = utf8.encode(text);
    return {
      'MD5': md5.convert(b).toString(),
      'SHA-1': sha1.convert(b).toString(),
      'SHA-256': sha256.convert(b).toString(),
      'SHA-512': sha512.convert(b).toString(),
    };
  }
}

class PhoneInfo {
  final String number;
  final String country;
  final String operator;
  final bool valid;
  final String note;

  PhoneInfo(this.number, this.country, this.operator, this.valid, this.note);

  String get waLink => 'https://wa.me/$number';
}

class PhoneTool {
  static const _countries = {
    '1': 'Amerika Serikat / Kanada',
    '7': 'Rusia / Kazakhstan',
    '33': 'Prancis',
    '44': 'Inggris',
    '49': 'Jerman',
    '55': 'Brasil',
    '60': 'Malaysia',
    '61': 'Australia',
    '62': 'Indonesia',
    '63': 'Filipina',
    '65': 'Singapura',
    '66': 'Thailand',
    '81': 'Jepang',
    '82': 'Korea Selatan',
    '84': 'Vietnam',
    '86': 'Tiongkok',
    '91': 'India',
  };

  // Prefiks operator Indonesia (berdasarkan alokasi umum, bisa berubah karena porting nomor)
  static const _idOperators = {
    'Telkomsel': ['811', '812', '813', '821', '822', '823', '851', '852', '853'],
    'Indosat': ['814', '815', '816', '855', '856', '857', '858'],
    'XL': ['817', '818', '819', '859', '877', '878'],
    'Axis': ['831', '832', '833', '838'],
    'Tri': ['895', '896', '897', '898', '899'],
    'Smartfren': ['881', '882', '883', '884', '885', '886', '887', '888', '889'],
  };

  static PhoneInfo? parse(String raw) {
    var d = raw.replaceAll(RegExp(r'[^0-9+]'), '');
    var note = '';
    if (d.startsWith('+')) {
      d = d.substring(1);
    } else if (d.startsWith('00')) {
      d = d.substring(2);
    } else if (d.startsWith('0')) {
      d = '62${d.substring(1)}';
      note = 'Awalan 0 dianggap nomor Indonesia.';
    }
    if (d.length < 8 || d.length > 15) return null;

    var country = 'Tidak dikenal';
    var cc = '';
    for (final len in [3, 2, 1]) {
      if (d.length > len && _countries.containsKey(d.substring(0, len))) {
        cc = d.substring(0, len);
        country = _countries[cc]!;
        break;
      }
    }

    var operator = '-';
    var valid = true;
    if (cc == '62') {
      final pre = d.substring(2, 5);
      for (final e in _idOperators.entries) {
        if (e.value.contains(pre)) {
          operator = e.key;
          break;
        }
      }
      valid = d.startsWith('628') && d.length >= 10 && d.length <= 13;
    }
    return PhoneInfo(d, country, operator, valid, note);
  }
}

class IpTool {
  static Future<Map<String, String>> lookup(String ip) async {
    final res = await http
        .get(Uri.parse('https://ipwho.is/${ip.trim()}'))
        .timeout(const Duration(seconds: 12));
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    if (j['success'] != true) {
      throw Exception(j['message'] ?? 'Lookup gagal');
    }
    final c = (j['connection'] ?? {}) as Map<String, dynamic>;
    final tz = (j['timezone'] ?? {}) as Map<String, dynamic>;
    return {
      'IP': '${j['ip'] ?? '-'}',
      'Tipe': '${j['type'] ?? '-'}',
      'Negara': '${j['country'] ?? '-'} (${j['country_code'] ?? '-'})',
      'Wilayah': '${j['region'] ?? '-'}',
      'Kota': '${j['city'] ?? '-'}',
      'Kode pos': '${j['postal'] ?? '-'}',
      'Koordinat': '${j['latitude'] ?? '-'}, ${j['longitude'] ?? '-'}',
      'Zona waktu': '${tz['id'] ?? '-'}',
      'ISP': '${c['isp'] ?? '-'}',
      'Organisasi': '${c['org'] ?? '-'}',
      'ASN': '${c['asn'] ?? '-'}',
    };
  }
}
