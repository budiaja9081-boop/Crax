import 'package:flutter/material.dart';
import '../services/session.dart';
import '../theme/laxx_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/liquid_button.dart';

class ProfileScreen extends StatefulWidget {
  final Session session;
  final String user;

  const ProfileScreen({super.key, required this.session, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _name = TextEditingController();
  final _cur = TextEditingController();
  final _new = TextEditingController();
  bool _busy = false;
  String? _msg;
  bool _ok = false;

  @override
  void initState() {
    super.initState();
    widget.session.profile(widget.user).then((pr) {
      if (mounted) _name.text = pr['name'] ?? widget.user;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _cur.dispose();
    _new.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    final err = await widget.session.updateProfile(
      widget.user,
      name: _name.text,
      currentPass: _cur.text,
      newPass: _new.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _ok = err == null;
      _msg = err ?? 'Profil tersimpan';
    });
    if (err == null) {
      _cur.clear();
      _new.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('Edit Profil')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Username: ${widget.user}', style: t.bodySmall),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                        hintText: 'Nama tampilan',
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cur,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Password lama (isi jika ganti password)',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _new,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Password baru (kosongkan jika tidak diganti)',
                        prefixIcon: Icon(Icons.lock_reset),
                      ),
                    ),
                    if (_msg != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _msg!,
                        style: TextStyle(color: _ok ? Laxx.ok : Laxx.danger),
                      ),
                    ],
                    const SizedBox(height: 16),
                    LiquidButton(
                      label: 'SIMPAN PROFIL',
                      icon: Icons.save_outlined,
                      loading: _busy,
                      onPressed: _busy ? null : _save,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Wallpaper aplikasi', style: t.titleMedium),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => pickWallpaper('app'),
                      icon: const Icon(Icons.wallpaper),
                      label: const Text('Ganti wallpaper'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        await widget.session.setWallpaper('app', null);
                        AppBackground.version.value++;
                      },
                      child: const Text(
                        'Hapus wallpaper',
                        style: TextStyle(color: Laxx.danger),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
