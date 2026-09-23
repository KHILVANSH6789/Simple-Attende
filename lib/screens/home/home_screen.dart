// ============================================================
// lib/screens/home/home_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/groups_provider.dart';
import '../../providers/update_provider.dart';
import '../../core/models/group_model.dart';
import '../../core/services/sound_service.dart';
import '../../widgets/group_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fabController;
  DateTime? _lastBackPressedTime;
  bool _updatePopupShown = false;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoUpdate();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _checkAutoUpdate() async {
    final updateProvider = context.read<UpdateProvider>();
    final hasUpdate = await updateProvider.checkForUpdates(silent: true);
    if (hasUpdate && mounted && !_updatePopupShown) {
      _updatePopupShown = true;
      _showUpdatePopup();
    }
  }

  void _showUpdatePopup() {
    final settings = context.read<SettingsProvider>();
    final colors = settings.colors;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Consumer<UpdateProvider>(
        builder: (context, upd, _) {
          return AlertDialog(
            backgroundColor: colors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.system_update_rounded, color: colors.accent, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Available',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'v${upd.latestVersion} is now live',
                        style: TextStyle(color: colors.accent, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: upd.isDownloading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Downloading update...',
                        style: TextStyle(color: colors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: upd.downloadProgress > 0 ? upd.downloadProgress : null,
                          backgroundColor: colors.cardBorder,
                          color: colors.accent,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(upd.downloadProgress * 100).toStringAsFixed(1)}%',
                            style: TextStyle(color: colors.accent, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          if (upd.totalMb > 0)
                            Text(
                              '${upd.downloadedMb.toStringAsFixed(1)} / ${upd.totalMb.toStringAsFixed(1)} MB',
                              style: TextStyle(color: colors.textMuted, fontSize: 12),
                            ),
                        ],
                      ),
                      if (upd.statusMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          upd.statusMessage!,
                          style: TextStyle(color: colors.textMuted, fontSize: 11),
                        ),
                      ],
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A new version of Simple Attende is ready to install! Get the latest features, improvements, and fixes.',
                        style: TextStyle(color: colors.textPrimary.withOpacity(0.9), fontSize: 13, height: 1.4),
                      ),
                      if (upd.releaseNotes.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 160),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colors.cardBorder),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              upd.releaseNotes,
                              style: TextStyle(color: colors.textMuted, fontSize: 12, height: 1.3),
                            ),
                          ),
                        ),
                      ],
                      if (upd.statusMessage != null && !upd.hasUpdate) ...[
                        const SizedBox(height: 8),
                        Text(
                          upd.statusMessage!,
                          style: TextStyle(color: colors.textMuted, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
            actions: upd.isDownloading
                ? null
                : [
                    TextButton(
                      onPressed: () {
                        _playClick();
                        Navigator.pop(ctx);
                      },
                      child: Text('Later', style: TextStyle(color: colors.textMuted)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        _playClick();
                        if (upd.isReadyToInstall) {
                          await upd.installDownloadedApk();
                        } else {
                          await upd.downloadAndInstall();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.accent,
                        foregroundColor: colors.onAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      icon: Icon(
                        upd.isReadyToInstall ? Icons.install_mobile_rounded : Icons.file_download_rounded,
                        size: 18,
                      ),
                      label: Text(
                        upd.isReadyToInstall ? 'Install Now' : 'Update Now',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
          );
        },
      ),
    );
  }

  void _playClick() {
    FeedbackService.tap(context);
  }

  void _showCreateGroupDialog() {
    _playClick();
    showDialog(
      context: context,
      builder: (ctx) => _CreateGroupDialog(),
    );
  }

  void _showEditGroupDialog(GroupModel group) {
    _playClick();
    showDialog(
      context: context,
      builder: (ctx) => _EditGroupDialog(group: group),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = settings.colors;
    final groups = context.watch<GroupsProvider>().groups;
    final update = context.watch<UpdateProvider>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressedTime == null ||
            now.difference(_lastBackPressedTime!) > const Duration(seconds: 2)) {
          _lastBackPressedTime = now;
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Press back again to exit',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colors.background, colors.backgroundGradientEnd],
            ),
          ),
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  floating: true,
                  pinned: false,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  expandedHeight: 120,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    title: null,
                    background: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/SimpleAttende_AppIcon.png',
                                  width: 38,
                                  height: 38,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Simple Attende',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                              // Update badge icon if update is available
                              if (update.hasUpdate)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Stack(
                                    children: [
                                      _IconBtn(
                                        icon: Icons.system_update_rounded,
                                        colors: colors,
                                        onTap: () {
                                          _playClick();
                                          _showUpdatePopup();
                                        },
                                      ),
                                      Positioned(
                                        right: 2,
                                        top: 2,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: colors.accent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              // Settings button
                              _IconBtn(
                                icon: Icons.settings_rounded,
                                colors: colors,
                                onTap: () {
                                  _playClick();
                                  Navigator.pushNamed(context, '/settings');
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your attendance groups',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: colors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // In-App Update Banner
                if (update.hasUpdate && !update.dismissedBanner)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.accent.withOpacity(0.18),
                              colors.accentSecondary.withOpacity(0.12),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.accent.withOpacity(0.4), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colors.accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.system_update_rounded, color: colors.onAccent, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Update v${update.latestVersion} Available',
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    update.isDownloading
                                        ? 'Downloading: ${(update.downloadProgress * 100).toStringAsFixed(0)}%'
                                        : 'Tap to download & install update',
                                    style: TextStyle(color: colors.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                _playClick();
                                _showUpdatePopup();
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: colors.accent,
                                foregroundColor: colors.onAccent,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                update.isDownloading ? 'View' : 'Update',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: Icon(Icons.close_rounded, size: 18, color: colors.textMuted),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                              onPressed: () {
                                _playClick();
                                update.dismissBanner();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Body
                groups.isEmpty
                    ? SliverFillRemaining(
                        child: _EmptyState(colors: colors),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final group = groups[index];
                              return GroupCard(
                                group: group,
                                colors: colors,
                                onTap: () {
                                  _playClick();
                                  Navigator.pushNamed(
                                    context,
                                    '/group',
                                    arguments: group.id,
                                  );
                                },
                                onEdit: () => _showEditGroupDialog(group),
                                onDelete: () => _confirmDelete(group),
                              );
                            },
                            childCount: groups.length,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
        floatingActionButton: ScaleTransition(
          scale: CurvedAnimation(
              parent: _fabController, curve: Curves.easeOutBack),
          child: FloatingActionButton.extended(
            onPressed: _showCreateGroupDialog,
            backgroundColor: colors.accent,
            foregroundColor: colors.onAccent,
            icon: const Icon(Icons.add_rounded),
            label: Text(
              'New Group',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.onAccent,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(GroupModel group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Group'),
        content: Text(
            'Delete "${group.name}"? All members and attendance data will be lost.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<GroupsProvider>().deleteGroup(group.id);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ── Edit Group Dialog ──────────────────────────────────────────
class _EditGroupDialog extends StatefulWidget {
  final GroupModel group;
  const _EditGroupDialog({required this.group});

  @override
  State<_EditGroupDialog> createState() => _EditGroupDialogState();
}

class _EditGroupDialogState extends State<_EditGroupDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.group.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FeedbackService.save(context);
    await context
        .read<GroupsProvider>()
        .updateGroupName(widget.group.id, _controller.text.trim());
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<SettingsProvider>().colors;
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Rename Group',
          style: Theme.of(context).textTheme.titleLarge),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                prefixIcon: Icon(Icons.edit_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter a name';
                if (v.trim().length < 2) return 'Name too short';
                return null;
              },
              onFieldSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
        ),
        ElevatedButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Save'),
        ),
      ],
    );
  }
}

// ── Create Group Dialog ────────────────────────────────────────
class _CreateGroupDialog extends StatefulWidget {
  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    FeedbackService.save(context);
    final group =
        await context.read<GroupsProvider>().createGroup(_controller.text.trim());
    if (mounted) {
      Navigator.pop(context);
      Navigator.pushNamed(context, '/group', arguments: group.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.watch<SettingsProvider>().colors;
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Create New Group',
          style: Theme.of(context).textTheme.titleLarge),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Give your group a name — like a clinic, class, or team.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colors.textMuted),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                hintText: 'e.g. Morning Clinic',
                prefixIcon: Icon(Icons.group_rounded),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Please enter a name';
                if (v.trim().length < 2) return 'Name too short';
                return null;
              },
              onFieldSubmitted: (_) => _create(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: colors.textMuted)),
        ),
        ElevatedButton.icon(
          onPressed: _create,
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Create'),
        ),
      ],
    );
  }
}

// ── Empty State ────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final dynamic colors;
  const _EmptyState({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: colors.accent.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_rounded,
                size: 52,
                color: colors.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No groups yet',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: colors.textPrimary,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create a group for your clinic, class, or any place where you take attendance.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textMuted,
                    height: 1.6,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (_) => _CreateGroupDialog());
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Your First Group'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Icon Button ────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final dynamic colors;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.cardBorder),
          ),
          child: Icon(icon, size: 20, color: colors.textSecondary),
        ),
      ),
    );
  }
}
