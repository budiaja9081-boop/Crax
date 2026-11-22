import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/shell_screen.dart';
import 'services/session.dart';
import 'theme/laxx_theme.dart';

void main() => runApp(const CraxApp());

class CraxApp extends StatelessWidget {
  const CraxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crax',
      theme: Laxx.theme,
      home: const _Gate(),
    );
  }
}

class _Gate extends StatefulWidget {
  const _Gate();

  @override
  State<_Gate> createState() => _GateState();
}

class _GateState extends State<_Gate> {
  final _session = Session();
  String? _user;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _session.currentUser().then((u) {
      if (mounted) {
        setState(() {
          _user = u;
          _ready = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_user == null) {
      return LoginScreen(
        session: _session,
        onLogin: (u) => setState(() => _user = u),
      );
    }
    return ShellScreen(
      session: _session,
      user: _user!,
      onLogout: () async {
        await _session.logout();
        if (mounted) setState(() => _user = null);
      },
    );
  }
}
