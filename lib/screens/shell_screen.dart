import 'package:flutter/material.dart';
import '../services/session.dart';
import '../theme/laxx_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/liquid_nav.dart';
import 'codex_screen.dart';
import 'files_screen.dart';
import 'profile_screen.dart';
import 'tools_screen.dart';

class ShellScreen extends StatefulWidget {
  final Session session;
  final String user;
  final Future<void> Function() onLogout;

  const ShellScreen({
    super.key,
    required this.session,
    required this.user,
    required this.onLogout,
  });

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _tab = 0;

  Future<void> _menu(String v) async {
    if (v == 'profile') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(session: widget.session, user: widget.user),
        ),
      );
    } else if (v == 'wall') {
      await pickWallpaper('app');
    } else if (v == 'logout') {
      await widget.onLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'CRAX',
            style: t.titleLarge?.copyWith(letterSpacing: 8, fontSize: 22),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              color: Laxx.surfaceHi,
              onSelected: _menu,
              itemBuilder: (_) => <PopupMenuEntry<String>>[
                const PopupMenuItem(
                  value: 'profile',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit profil'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'wall',
                  child: ListTile(
                    leading: Icon(Icons.wallpaper),
                    title: Text('Ganti wallpaper'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Keluar'),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: IndexedStack(
                index: _tab,
                children: const [ToolsScreen(), FilesScreen(), CodexScreen()],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 12 + bottomPad,
              child: LiquidNav(
                icons: const [
                  Icons.grid_view_rounded,
                  Icons.folder_outlined,
                  Icons.code_rounded,
                ],
                labels: const ['TOOLS', 'FILES', 'CODEX'],
                index: _tab,
                onTap: (i) => setState(() => _tab = i),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
