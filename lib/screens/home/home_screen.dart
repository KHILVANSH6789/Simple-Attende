// ============================================================
// lib/screens/home/home_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/groups_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
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
