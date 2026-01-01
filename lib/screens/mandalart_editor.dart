import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/goal_provider.dart';
import '../models/goal_model.dart';

class MandalartEditor extends ConsumerStatefulWidget {
  final bool isNewBoard;

  const MandalartEditor({super.key, this.isNewBoard = false});

  @override
  ConsumerState<MandalartEditor> createState() => _MandalartEditorState();
}

class _MandalartEditorState extends ConsumerState<MandalartEditor> {
  final _centerGoalController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!widget.isNewBoard) {
      final board = ref.read(currentBoardProvider);
      if (board != null) {
        _centerGoalController.text = board.centerGoal;
        _descriptionController.text = board.description ?? '';
      }
    }
  }

  @override
  void dispose() {
    _centerGoalController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveBoard() async {
    if (_centerGoalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('중앙 목표를 입력해주세요')));
      return;
    }

    final board = MandalartBoard(
      centerGoal: _centerGoalController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      createdAt: DateTime.now(),
    );

    try {
      final db = ref.read(databaseProvider);
      final boardId = await db.createMandalartBoard(board);

      // Create empty goals for 8 positions (3x3 grid with center)
      for (int i = 0; i < 8; i++) {
        final goal = Goal(
          title: '',
          parentId: boardId,
          position: i,
          createdAt: DateTime.now(),
        );
        await db.createGoal(goal);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('새 목표가 생성되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBoard = ref.watch(currentBoardProvider);

    if (widget.isNewBoard) {
      return _buildNewBoardForm();
    }

    if (currentBoard == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('만다라트')),
        body: const Center(child: Text('보드를 불러올 수 없습니다')),
      );
    }

    return _buildMandalartGrid(currentBoard);
  }

  Widget _buildNewBoardForm() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('새 목표 만들기'),
        actions: [
          TextButton.icon(
            onPressed: _saveBoard,
            icon: const Icon(Icons.check_rounded, size: 20),
            label: const Text('완료'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '중앙 목표',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _centerGoalController,
              decoration: const InputDecoration(
                hintText: '예: 영어 회화 실력 향상',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              maxLines: 1,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 28),
            const Text(
              '설명 (선택사항)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: '목표에 대한 간단한 설명을 입력하세요',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 4,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMandalartGrid(MandalartBoard board) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          board.centerGoal,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '전체 진행률',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        '${board.overallProgress}%',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: board.overallProgress / 100,
                      backgroundColor: Colors.grey.withValues(alpha: 0.2),
                      color: Theme.of(context).colorScheme.primary,
                      minHeight: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: 9,
                itemBuilder: (context, index) {
                  if (index == 4) {
                    return _buildCenterTile(board);
                  }

                  final goalIndex = index > 4 ? index - 1 : index;
                  final goal = goalIndex < board.subGoals.length
                      ? board.subGoals[goalIndex]
                      : null;

                  return _buildGoalTile(goal, goalIndex);
                },
              ),
            ),
            if (board.description != null && board.description!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '목표 설명',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.secondary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      board.description!,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCenterTile(MandalartBoard board) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            board.centerGoal,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: -0.3,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildGoalTile(Goal? goal, int position) {
    final hasContent = goal != null && goal.title.isNotEmpty;
    final progress = goal?.progress ?? 0;
    final isCompleted = progress == 100;

    return InkWell(
      onTap: () => _editGoal(goal, position),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: hasContent
              ? (isCompleted
                  ? Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3)
                  : Theme.of(context).colorScheme.surface)
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasContent
                ? (isCompleted
                    ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5)
                    : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3))
                : Colors.grey.withValues(alpha: 0.25),
            width: isCompleted ? 2 : 1.5,
          ),
          boxShadow: hasContent && !isCompleted
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: hasContent
                    ? Text(
                        goal.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          letterSpacing: -0.2,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: Theme.of(context).colorScheme.secondary,
                          decorationThickness: 2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Icon(
                        Icons.add_rounded,
                        color: Colors.grey.withValues(alpha: 0.4),
                        size: 28,
                      ),
              ),
            ),
            if (hasContent && progress > 0)
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: (isCompleted
                                ? Theme.of(context).colorScheme.secondary
                                : Theme.of(context).colorScheme.primary)
                            .withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    isCompleted ? '완료' : '$progress%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<int?> _saveGoalToDb(
    Goal? goal,
    int position,
    String title,
    String description,
    int progress,
  ) async {
    final currentBoard = ref.read(currentBoardProvider);
    if (currentBoard?.id == null) return null;

    if (title.isEmpty) return goal?.id;

    final updatedGoal = Goal(
      id: goal?.id,
      title: title,
      description: description.isNotEmpty ? description : null,
      parentId: currentBoard!.id!,
      position: position,
      progress: progress.clamp(0, 100),
      createdAt: goal?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (goal?.id != null) {
        await ref.read(currentBoardProvider.notifier).updateGoal(updatedGoal);
        return goal!.id;
      } else {
        await ref.read(currentBoardProvider.notifier).createGoal(updatedGoal);
        // 생성 후 새로 생성된 goal의 ID를 반환
        final updatedBoard = ref.read(currentBoardProvider);
        final createdGoal = updatedBoard?.subGoals.firstWhere(
          (g) => g.position == position,
        );
        return createdGoal?.id;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
      return null;
    }
  }

  Future<void> _editGoal(Goal? goal, int position) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _GoalEditDialog(
        goal: goal,
        position: position,
        onSave: _saveGoalToDb,
        currentBoardProvider: currentBoardProvider,
      ),
    );
  }
}

// 별도의 StatefulWidget으로 다이얼로그 분리
class _GoalEditDialog extends StatefulWidget {
  final Goal? goal;
  final int position;
  final Future<int?> Function(Goal?, int, String, String, int) onSave;
  final StateNotifierProvider<CurrentBoardNotifier, MandalartBoard?>
  currentBoardProvider;

  const _GoalEditDialog({
    required this.goal,
    required this.position,
    required this.onSave,
    required this.currentBoardProvider,
  });

  @override
  State<_GoalEditDialog> createState() => _GoalEditDialogState();
}

class _GoalEditDialogState extends State<_GoalEditDialog> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController progressController;

  int? currentGoalId;
  Timer? debounceTimer;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.goal?.title ?? '');
    descriptionController = TextEditingController(
      text: widget.goal?.description ?? '',
    );
    progressController = TextEditingController(
      text: (widget.goal?.progress ?? 0).toString(),
    );
    currentGoalId = widget.goal?.id;

    // 리스너 추가
    titleController.addListener(_onTextChanged);
    descriptionController.addListener(_onTextChanged);
    progressController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    // 타이머 취소
    debounceTimer?.cancel();

    // 리스너 제거
    titleController.removeListener(_onTextChanged);
    descriptionController.removeListener(_onTextChanged);
    progressController.removeListener(_onTextChanged);

    // 컨트롤러 dispose
    titleController.dispose();
    descriptionController.dispose();
    progressController.dispose();

    super.dispose();
  }

  void _onTextChanged() {
    // 이전 타이머 취소
    debounceTimer?.cancel();

    // 새로운 타이머 시작 (500ms 후 저장)
    debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      // 저장 실행
      final savedId = await widget.onSave(
        widget.goal,
        widget.position,
        titleController.text.trim(),
        descriptionController.text.trim(),
        int.tryParse(progressController.text) ?? 0,
      );

      if (savedId != null && mounted) {
        setState(() {
          currentGoalId = savedId;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = int.tryParse(progressController.text) ?? 0;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Row(
        children: [
          Icon(
            widget.goal?.title.isNotEmpty == true
                ? Icons.edit_outlined
                : Icons.add_circle_outline,
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(
            widget.goal?.title.isNotEmpty == true ? '목표 수정' : '새 목표 추가',
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width - 40,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '목표 제목',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: '예: 매일 1시간 공부',
                  prefixIcon: Icon(Icons.flag_outlined, size: 20),
                ),
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 20),
              const Text(
                '설명 (선택사항)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  hintText: '세부 내용을 입력하세요',
                  prefixIcon: Icon(Icons.description_outlined, size: 20),
                ),
                maxLines: 3,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              const Text(
                '진행률',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: progress.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '$progress%',
                      onChanged: (value) {
                        setState(() {
                          progressController.text = value.round().toString();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$progress%',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('완료'),
        ),
      ],
    );
  }
}
