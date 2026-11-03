import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/goal_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/mm_widgets.dart';
import '../models/goal_model.dart';
import 'cell_sheets.dart';
import 'home_screen.dart';
import 'share_screen.dart';

/// 보드 상세. 현재 보드(currentBoardProvider)를 보여 준다.
class BoardScreen extends ConsumerWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(currentBoardProvider);
    if (board == null) return const Scaffold();

    final c = context.mm;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: isTwoPane(context) ? null : const BackIcon(),
        actions: [
          IconButton(
            tooltip: 'common.board_menu'.tr(),
            iconSize: 26,
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => _showBoardMenu(context, ref, board),
          ),
        ],
      ),
      bottomNavigationBar: BottomAction(
        child: PrimaryButton(
          label: 'board.share'.tr(),
          icon: Icons.ios_share_rounded,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ShareScreen(board: board)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              board.centerGoal,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.3,
              ),
            ),
            if (board.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 2),
              Text(
                board.description!,
                style: TextStyle(fontSize: 14, height: 1.5, color: c.muted),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 12,
              runSpacing: 4,
              children: [
                Text(
                  '${board.overallProgress}%',
                  style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -1.5,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    'board.stats'.tr(
                      namedArgs: {
                        'done': '${board.completedCount}',
                        'filled': '${board.filledCount}',
                      },
                    ),
                    style: TextStyle(fontSize: 13, color: c.muted, height: 1.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ExcludeSemantics(child: _ProgressSegments(board: board)),
            if (board.completedCount == 8) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: c.accent,
                  border: Border.all(color: c.line, width: 2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.celebration_rounded, size: 22, color: MmColors.onAccent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'board.all_done'.tr(),
                        style: const TextStyle(
                          color: MmColors.onAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (board.filledCount == 0) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.touch_app_rounded, size: 20, color: c.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'board.all_empty'.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: c.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (int i = 0; i < 9; i++)
                  if (i == 4) _CenterCell(board: board) else _gridCell(board, i > 4 ? i - 1 : i),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridCell(MandalartBoard board, int position) {
    final goal = board.subGoals.where((g) => g.position == position).firstOrNull;
    // 보드 생성과 DB 마이그레이션이 8칸을 보장하므로 없으면 표시만 생략
    if (goal == null) return const SizedBox.shrink();
    return BoardCell(goal: goal);
  }
}

/// 8칸 진행 막대. 칸마다 1개.
class _ProgressSegments extends StatelessWidget {
  final MandalartBoard board;

  const _ProgressSegments({required this.board});

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    final byPosition = {for (final g in board.subGoals) g.position: g};
    return Row(
      children: [
        for (int i = 0; i < 8; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: SizedBox(
              height: 10,
              child: (byPosition[i]?.status ?? GoalStatus.empty) == GoalStatus.empty
                  ? const DashedBox(radius: 0, strokeWidth: 1.5)
                  : Container(
                      decoration: BoxDecoration(
                        color: c.surface,
                        border: Border.all(color: c.line, width: 1.5),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: byPosition[i]!.progress / 100,
                        heightFactor: 1,
                        child: ColoredBox(color: c.ink),
                      ),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 눌렀을 때 0.96배로 줄어드는 칸 공통 동작.
class _CellPress extends StatefulWidget {
  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;

  const _CellPress({
    required this.semanticLabel,
    required this.onTap,
    required this.child,
  });

  @override
  State<_CellPress> createState() => _CellPressState();
}

class _CellPressState extends State<_CellPress> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 100),
          child: widget.child,
        ),
      ),
    );
  }
}

class _CenterCell extends StatelessWidget {
  final MandalartBoard board;

  const _CenterCell({required this.board});

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    return _CellPress(
      semanticLabel: 'board.edit_center'.tr(),
      onTap: () => showCenterSheet(context),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: c.center,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'common.center_goal'.tr(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.centerLabel,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(Icons.edit_rounded, size: 16, color: c.onCenter),
              ],
            ),
            const Spacer(),
            Flexible(
              flex: 6,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  board.centerGoal,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.onCenter,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BoardCell extends StatelessWidget {
  final Goal goal;

  const BoardCell({super.key, required this.goal});

  String _semanticLabel() {
    final status = switch (goal.status) {
      GoalStatus.done => 'board.status_done'.tr(),
      GoalStatus.inProgress => 'board.status_in_progress'.tr(
        namedArgs: {'pct': '${goal.progress}'},
      ),
      _ => 'board.status_todo'.tr(),
    };
    return '${goal.title}, $status';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    final status = goal.status;

    if (status == GoalStatus.empty) {
      return _CellPress(
        semanticLabel: 'board.empty_cell'.tr(),
        onTap: () => showCellSheet(context, goal.id!),
        child: DashedBox(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 28, color: c.muted),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    'board.fill'.tr(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final done = status == GoalStatus.done;
    final foreground = done ? MmColors.onAccent : c.ink;
    return _CellPress(
      semanticLabel: _semanticLabel(),
      onTap: () => showCellSheet(context, goal.id!),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          decoration: BoxDecoration(
            color: done ? c.accent : c.surface,
            border: Border.all(color: c.line, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              if (status == GoalStatus.inProgress)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: goal.progress / 100,
                      widthFactor: 1,
                      child: ColoredBox(color: c.accentSoft),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          goal.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: foreground,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ),
                      _statusLine(c, status, foreground),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusLine(MmColors c, GoalStatus status, Color foreground) {
    return switch (status) {
      GoalStatus.inProgress => FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timelapse_rounded, size: 16, color: foreground),
            const SizedBox(width: 3),
            Text(
              '${goal.progress}%',
              style: TextStyle(
                color: foreground,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
      ),
      GoalStatus.done => Row(
        children: [
          Icon(Icons.check_circle_rounded, size: 17, color: foreground),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              'board.status_done'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      _ => Row(
        children: [
          Icon(Icons.radio_button_unchecked_rounded, size: 16, color: c.muted),
          const SizedBox(width: 3),
          Expanded(
            child: Text(
              'board.status_todo'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    };
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final bool danger;
  final VoidCallback onTap;

  const _MenuItem(this.icon, this.label, this.onTap, {this.danger = false});
}

Future<void> _showMenuSheet(
  BuildContext context,
  String title,
  List<_MenuItem> items,
) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    builder: (sheetContext) {
      final c = sheetContext.mm;
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: c.muted,
                ),
              ),
            ),
            for (final item in items)
              InkWell(
                onTap: () {
                  Navigator.pop(sheetContext);
                  item.onTap();
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: Row(
                      children: [
                        Icon(item.icon, size: 22, color: item.danger ? c.error : c.ink),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              color: item.danger ? c.error : c.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}

Future<void> _showBoardMenu(BuildContext context, WidgetRef ref, MandalartBoard board) {
  return _showMenuSheet(context, board.centerGoal, [
    _MenuItem(
      Icons.edit_rounded,
      'board.edit_center'.tr(),
      () => showCenterSheet(context),
    ),
    _MenuItem(
      Icons.delete_rounded,
      'board.menu_delete'.tr(),
      () => _deleteBoard(context, ref, board),
      danger: true,
    ),
  ]);
}

/// 홈 카드의 ⋮ 메뉴.
Future<void> showCardMenu(BuildContext context, WidgetRef ref, MandalartBoard board) {
  return _showMenuSheet(context, board.centerGoal, [
    _MenuItem(Icons.ios_share_rounded, 'board.menu_share'.tr(), () {
      detailNavigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => ShareScreen(board: board)),
      );
    }),
    _MenuItem(
      Icons.delete_rounded,
      'board.menu_delete'.tr(),
      () => _deleteBoard(context, ref, board),
      danger: true,
    ),
  ]);
}

Future<void> _deleteBoard(BuildContext context, WidgetRef ref, MandalartBoard board) async {
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showConfirmDialog(
    context,
    title: 'board.delete_title'.tr(),
    body: 'board.delete_body'.tr(namedArgs: {'title': board.centerGoal}),
    confirmLabel: 'board.delete_cta'.tr(),
  );
  if (!confirmed || !context.mounted) return;

  final currentBoard = ref.read(currentBoardProvider.notifier);
  final isCurrent = ref.read(currentBoardProvider)?.id == board.id;
  final boards = ref.read(mandalartBoardsProvider.notifier);
  final navigator = detailNavigatorKey.currentState;
  final snackContext = navigator?.context ?? context;

  if (isCurrent) {
    navigator?.popUntil((route) => route.isFirst);
    currentBoard.clearBoard();
  }
  await boards.deleteBoard(board.id!);
  if (snackContext.mounted) {
    showMmSnack(messenger, snackContext, 'board.deleted'.tr());
  }
}
