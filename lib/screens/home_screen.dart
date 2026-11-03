import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/goal_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/mm_widgets.dart';
import '../models/goal_model.dart';
import 'board_screen.dart';
import 'new_board_screen.dart';
import 'settings_screen.dart';

/// 폭이 이 값 이상이면 목록 + 상세 2단(펼친 폴더블).
const double twoPaneWidth = 600;
const double _listPaneWidth = 300;

bool isTwoPane(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= twoPaneWidth;

/// 화면 이동은 모두 이 Navigator를 쓴다. 폭이 바뀌어도 같은 Navigator가 유지되므로
/// 접고 펼쳐도 스택이 보존된다. 시트와 다이얼로그는 전체 창 기준인 바깥 Navigator에 뜬다.
final detailNavigatorKey = GlobalKey<NavigatorState>();

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final twoPane = isTwoPane(context);
    final c = context.mm;
    return NavigatorPopHandler(
      onPopWithResult: (_) => detailNavigatorKey.currentState?.maybePop(),
      child: Row(
        children: [
          if (twoPane)
            Container(
              width: _listPaneWidth + 2 + MediaQuery.paddingOf(context).left,
              decoration: BoxDecoration(
                color: c.bg,
                border: Border(right: BorderSide(color: c.line, width: 2)),
              ),
              child: const Material(
                type: MaterialType.transparency,
                child: SafeArea(right: false, child: _BoardListPane()),
              ),
            ),
          Expanded(
            // 경계가 없으면 화면이 먼저 그려진 왼쪽 목록의 접근성 정보까지 차단한다.
            child: Semantics(
              container: true,
              // 2단에서는 왼쪽 여백(카메라 영역 등)을 목록이 이미 처리한다.
              child: MediaQuery.removePadding(
                context: context,
                removeLeft: twoPane,
                child: Navigator(
                  key: detailNavigatorKey,
                  onGenerateRoute: (_) =>
                      MaterialPageRoute(builder: (_) => const _DetailRoot()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 상세 영역의 맨 아래 화면. 1단에서는 홈, 2단에서는 선택한 보드를 보여 준다.
class _DetailRoot extends ConsumerStatefulWidget {
  const _DetailRoot();

  @override
  ConsumerState<_DetailRoot> createState() => _DetailRootState();
}

class _DetailRootState extends ConsumerState<_DetailRoot> {
  bool _wasTwoPane = false;

  @override
  Widget build(BuildContext context) {
    final twoPane = isTwoPane(context);
    final current = ref.watch(currentBoardProvider);

    // 2단에서 접으면 보던 보드를 1단 화면으로 이어서 보여 준다.
    if (_wasTwoPane && !twoPane && current != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !Navigator.of(context).canPop()) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const BoardScreen()),
          );
        }
      });
    }
    _wasTwoPane = twoPane;

    if (!twoPane) {
      return const Scaffold(body: SafeArea(child: _BoardListPane()));
    }

    if (current != null) return const BoardScreen();

    // 2단에서 선택이 없으면 첫 보드를 연다.
    final boards = ref.watch(mandalartBoardsProvider).valueOrNull ?? const [];
    if (boards.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(currentBoardProvider) == null) {
          ref.read(currentBoardProvider.notifier).loadBoard(boards.first.id!);
        }
      });
    }
    final c = context.mm;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.grid_view_rounded, size: 36, color: c.muted),
              const SizedBox(height: 10),
              Text(
                'home.pick_board'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: c.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoardListPane extends ConsumerWidget {
  const _BoardListPane();

  void _pushDetail(Widget screen) {
    final nav = detailNavigatorKey.currentState!;
    nav.popUntil((route) => route.isFirst);
    nav.push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openNew() {
    detailNavigatorKey.currentState!.push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const NewBoardScreen(),
      ),
    );
  }

  Future<void> _openBoard(BuildContext context, WidgetRef ref, MandalartBoard board) async {
    final twoPane = isTwoPane(context);
    await ref.read(currentBoardProvider.notifier).loadBoard(board.id!);
    if (twoPane) {
      detailNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    } else {
      _pushDetail(const BoardScreen());
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mm;
    final boards = ref.watch(mandalartBoardsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 6, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'app.name'.tr(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1.2,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'home.settings'.tr(),
                iconSize: 26,
                icon: const Icon(Icons.settings_rounded),
                onPressed: () => _pushDetail(const SettingsScreen()),
              ),
            ],
          ),
        ),
        Expanded(
          child: boards.when(
            loading: () => const _HomeSkeleton(),
            error: (error, _) => _HomeError(
              onRetry: () =>
                  ref.read(mandalartBoardsProvider.notifier).loadBoards(),
            ),
            data: (list) {
              if (list.isEmpty) return _HomeEmpty(onCreate: _openNew);
              final selectedId = isTwoPane(context)
                  ? ref.watch(currentBoardProvider)?.id
                  : null;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 2, 0, 14),
                      child: Row(
                        children: [
                          Text(
                            'home.my_boards'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                            decoration: BoxDecoration(
                              color: c.ink,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${list.length}',
                              style: TextStyle(
                                color: c.bg,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = (constraints.maxWidth - 12) / 2;
                        return Wrap(
                          spacing: 12,
                          runSpacing: 14,
                          children: [
                            for (final board in list)
                              SizedBox(
                                width: width,
                                child: _BoardCard(
                                  board: board,
                                  selected: board.id == selectedId,
                                  onTap: () => _openBoard(context, ref, board),
                                ),
                              ),
                            SizedBox(
                              width: width,
                              child: _NewBoardTile(onTap: _openNew),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BoardCard extends ConsumerWidget {
  final MandalartBoard board;
  final bool selected;
  final VoidCallback onTap;

  const _BoardCard({
    required this.board,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.mm;
    final muted = TextStyle(fontSize: 12, color: c.muted, height: 1.4);
    return ShadowPressable(
      onTap: onTap,
      color: selected ? c.accentSoft : c.surface,
      shadowColor: c.line,
      borderColor: c.line,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MiniBoard(board: board),
            const SizedBox(height: 10),
            Text(
              board.centerGoal,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${board.overallProgress}%',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(10, 0),
                  child: IconButton(
                    tooltip: 'common.board_menu'.tr(),
                    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                    padding: EdgeInsets.zero,
                    iconSize: 22,
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () => showCardMenu(context, ref, board),
                  ),
                ),
              ],
            ),
            Text(
              'home.stats'.tr(
                namedArgs: {
                  'done': '${board.completedCount}',
                  'filled': '${board.filledCount}',
                },
              ),
              style: muted,
            ),
            Text(DateFormat('yyyy.MM.dd').format(board.createdAt), style: muted),
          ],
        ),
      ),
    );
  }
}

/// 보드 축소 그림. 정사각형.
class MiniBoard extends StatelessWidget {
  final MandalartBoard board;

  const MiniBoard({super.key, required this.board});

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    final byPosition = {for (final g in board.subGoals) g.position: g};
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (int i = 0; i < 9; i++)
            if (i == 4)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: c.center,
                  borderRadius: BorderRadius.circular(3),
                ),
              )
            else
              _miniCell(c, byPosition[i > 4 ? i - 1 : i]),
        ],
      ),
    );
  }

  Widget _miniCell(MmColors c, Goal? goal) {
    final status = goal?.status ?? GoalStatus.empty;
    if (status == GoalStatus.empty) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: c.tile,
          borderRadius: BorderRadius.circular(3),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        decoration: BoxDecoration(
          color: status == GoalStatus.done ? c.accent : c.surface,
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: c.line, width: 1.5),
        ),
        alignment: Alignment.bottomCenter,
        child: status == GoalStatus.inProgress
            ? FractionallySizedBox(
                heightFactor: goal!.progress / 100,
                widthFactor: 1,
                child: ColoredBox(color: c.accent),
              )
            : null,
      ),
    );
  }
}

class _NewBoardTile extends StatelessWidget {
  final VoidCallback onTap;

  const _NewBoardTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 180,
          child: DashedBox(
            radius: 8,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
                    child: Icon(Icons.add_rounded, size: 28, color: c.bg),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'home.new_board'.tr(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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

class _HomeEmpty extends StatelessWidget {
  final VoidCallback onCreate;

  const _HomeEmpty({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        children: [
          SizedBox(
            width: 156,
            child: AspectRatio(
              aspectRatio: 1,
              child: GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (int i = 0; i < 9; i++)
                    if (i == 4)
                      Container(
                        decoration: BoxDecoration(
                          color: c.center,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(Icons.flag_rounded, size: 28, color: c.centerLabel),
                      )
                    else
                      const DashedBox(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'home.empty_title'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, height: 1.3),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              'home.empty_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.55, color: c.muted),
            ),
          ),
          const SizedBox(height: 26),
          PrimaryButton(
            label: 'home.first_board'.tr(),
            icon: Icons.add_rounded,
            onTap: onCreate,
          ),
        ],
      ),
    );
  }
}

class _HomeError extends StatelessWidget {
  final VoidCallback onRetry;

  const _HomeError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 88, 24, 24),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              border: Border.all(color: c.line, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.error_rounded, size: 32),
          ),
          const SizedBox(height: 18),
          Text(
            'home.error_title'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.3),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: Text(
              'home.error_body'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 1.5, color: c.muted),
            ),
          ),
          const SizedBox(height: 22),
          ShadowPressable(
            onTap: onRetry,
            color: c.surface,
            shadowColor: c.line,
            borderColor: c.line,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'home.retry'.tr(),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
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
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = context.mm.tile;
    return Semantics(
      label: 'home.loading'.tr(),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 84,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              mainAxisSpacing: 14,
              crossAxisSpacing: 12,
              childAspectRatio: 0.74,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (int i = 0; i < 4; i++)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
