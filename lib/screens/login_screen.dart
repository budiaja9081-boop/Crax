import 'package:flutter/material.dart';
import '../services/session.dart';
import '../theme/laxx_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/liquid_button.dart';

class LoginScreen extends StatefulWidget {
  final Session session;
  final void Function(String user) onLogin;

  const LoginScreen({super.key, required this.session, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  bool _busy = false;
  String? _msg;

  @override
  void dispose() {
    _user.dispose();
    _pass.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    final u = _user.text.trim();
    final p = _pass.text;
    String? err;
    if (_register) {
      err = await widget.session.register(u, p, _name.text.trim());
      if (err == null) err = await widget.session.login(u, p);
    } else {
      err = await widget.session.login(u, p);
    }
    if (!mounted) return;
    if (err != null) {
      setState(() {
        _busy = false;
        _msg = err;
      });
    } else {
      widget.onLogin(u);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 84,
                      height: 84,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Laxx.accent, Laxx.accent2],
                        ),
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(color: Laxx.accent.withOpacity(0.4), blurRadius: 36),
                        ],
                      ),
                      child: const Icon(Icons.shield_outlined, color: Laxx.bg, size: 42),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'CRAX',
                    textAlign: TextAlign.center,
                    style: t.headlineMedium?.copyWith(letterSpacing: 6),
                  ),
                  Text(
                    'Toolkit Keamanan Siber',
                    textAlign: TextAlign.center,
                    style: t.bodySmall,
                  ),
                  const SizedBox(height: 28),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _user,
                          decoration: const InputDecoration(
                            hintText: 'Username',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_register) ...[
                          TextField(
                            controller: _name,
                            decoration: const InputDecoration(
                              hintText: 'Nama tampilan',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: _pass,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        if (_msg != null) ...[
                          const SizedBox(height: 12),
                          Text(_msg!, style: const TextStyle(color: Laxx.danger)),
                        ],
                        const SizedBox(height: 18),
                        LiquidButton(
                          label: _register ? 'DAFTAR' : 'MASUK',
                          icon: _register ? Icons.person_add_alt : Icons.login,
                          loading: _busy,
                          onPressed: _busy ? null : _submit,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                    _register = !_register;
                                    _msg = null;
                                  }),
                          child: Text(
                            _register ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar',
                            style: const TextStyle(color: Laxx.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
