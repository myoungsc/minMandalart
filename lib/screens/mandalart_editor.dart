import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../core/providers/goal_provider.dart';
import '../models/goal_model.dart';

class MandalartEditor extends ConsumerStatefulWidget {
  final bool isNewBoard;
  final bool isEditMode;

  const MandalartEditor({
    super.key,
    this.isNewBoard = false,
    this.isEditMode = false,
  });

  @override
  ConsumerState<MandalartEditor> createState() => _MandalartEditorState();
}

class _MandalartEditorState extends ConsumerState<MandalartEditor> {
  final _centerGoalController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!widget.isNewBoard || widget.isEditMode) {
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
      ).showSnackBar(SnackBar(content: Text('editor.empty_goal_error'.tr())));
      return;
    }

    try {
      final db = ref.read(databaseProvider);

      if (widget.isEditMode) {
        // 수정 모드
        final currentBoard = ref.read(currentBoardProvider);
        if (currentBoard?.id == null) return;

        final description = _descriptionController.text.trim();
        final updatedBoard = currentBoard!.copyWith(
          centerGoal: _centerGoalController.text.trim(),
          description: description,
          clearDescription: description.isEmpty,
        );

        await db.updateMandalartBoard(updatedBoard);
        await ref
            .read(currentBoardProvider.notifier)
            .loadBoard(currentBoard.id!);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('editor.goal_updated'.tr())));
        }
      } else {
        // 새로 만들기 모드
        final board = MandalartBoard(
          centerGoal: _centerGoalController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          createdAt: DateTime.now(),
        );

        await db.createBoardWithEmptyGoals(board);

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('editor.goal_saved'.tr())));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${'editor.error_occurred'.tr()}: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBoard = ref.watch(currentBoardProvider);

    if (widget.isNewBoard || widget.isEditMode) {
      return _buildNewBoardForm();
    }

    if (currentBoard == null) {
      return Scaffold(
        appBar: AppBar(title: Text('app.title'.tr())),
        body: Center(child: Text('editor.board_load_error'.tr())),
      );
    }

    return _buildMandalartGrid(currentBoard);
  }

  Widget _buildNewBoardForm() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'editor.edit_board_title'.tr() : 'editor.new_board_title'.tr()),
        actions: [
          TextButton.icon(
            onPressed: _saveBoard,
            icon: const Icon(Icons.check_rounded, size: 20),
            label: Text('editor.done_button'.tr()),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              'editor.center_goal_label'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _centerGoalController,
              decoration: InputDecoration(
                hintText: 'editor.center_goal_hint'.tr(),
                prefixIcon: const Icon(Icons.flag_outlined),
              ),
              maxLines: 1,
              style: const TextStyle(fontSize: 16),
              enableSuggestions: false,
              autocorrect: false,
            ),
            const SizedBox(height: 28),
            Text(
              'editor.description_label'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'editor.description_hint'.tr(),
                prefixIcon: const Icon(Icons.description_outlined),
              ),
              maxLines: 4,
              style: const TextStyle(fontSize: 15),
              enableSuggestions: false,
              autocorrect: false,
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMandalartGrid(MandalartBoard board) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          board.centerGoal,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MandalartEditor(isEditMode: true),
                ),
              );

              if (result == true && mounted) {
                // 수정 후 홈 화면 목록도 업데이트
                ref.read(mandalartBoardsProvider.notifier).loadBoards();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'editor.progress_label'.tr(),
                        style: const TextStyle(
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
                  final goal = board.subGoals
                      .where((g) => g.position == goalIndex)
                      .firstOrNull;

                  // 보드 생성과 DB 마이그레이션이 8칸을 보장하므로 없으면 표시만 생략
                  if (goal == null) return const SizedBox.shrink();

                  return _buildGoalTile(goal);
                },
              ),
            ),
            if (board.description != null && board.description!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.3),
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
                          'editor.goal_description_label'.tr(),
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

  Widget _buildGoalTile(Goal goal) {
    final hasContent = goal.title.isNotEmpty;
    final progress = goal.progress;
    final isCompleted = progress == 100;

    return InkWell(
      onTap: () => _editGoal(goal),
      borderRadius: BorderRadius.circular(14),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      child: Container(
        decoration: BoxDecoration(
          color: hasContent
              ? (isCompleted
                    ? Theme.of(
                        context,
                      ).colorScheme.secondaryContainer.withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.surface)
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasContent
                ? (isCompleted
                      ? Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.5)
                      : Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3))
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
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
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
                        color:
                            (isCompleted
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.primary)
                                .withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    isCompleted ? 'editor.completed_badge'.tr() : '$progress%',
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

  Future<void> _persistGoal(Goal goal) async {
    try {
      await ref.read(currentBoardProvider.notifier).updateGoal(goal);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${'editor.error_occurred'.tr()}: $e')));
      }
    }
  }

  Future<void> _saveGoal(
    Goal goal,
    String title,
    String description,
    int progress,
  ) async {
    // 제목을 지운 채여도 기존 제목을 유지한다. 칸을 비우는 건 _clearGoal만 한다.
    final savedTitle = title.isNotEmpty ? title : goal.title;
    if (savedTitle.isEmpty) return;

    await _persistGoal(
      Goal(
        id: goal.id,
        title: savedTitle,
        description: description.isNotEmpty ? description : null,
        parentId: goal.parentId,
        position: goal.position,
        progress: progress.clamp(0, 100),
        createdAt: goal.createdAt,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _clearGoal(Goal goal) => _persistGoal(
    Goal(
      id: goal.id,
      title: '',
      parentId: goal.parentId,
      position: goal.position,
      createdAt: goal.createdAt,
      updatedAt: DateTime.now(),
    ),
  );

  Future<void> _editGoal(Goal goal) async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _GoalEditDialog(
        goal: goal,
        onSave: _saveGoal,
        onClear: () => _clearGoal(goal),
      ),
    );
  }
}

// 별도의 StatefulWidget으로 다이얼로그 분리
class _GoalEditDialog extends StatefulWidget {
  final Goal goal;
  final Future<void> Function(Goal, String, String, int) onSave;
  final Future<void> Function() onClear;

  const _GoalEditDialog({
    required this.goal,
    required this.onSave,
    required this.onClear,
  });

  @override
  State<_GoalEditDialog> createState() => _GoalEditDialogState();
}

class _GoalEditDialogState extends State<_GoalEditDialog> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController progressController;

  Timer? debounceTimer;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.goal.title);
    descriptionController = TextEditingController(
      text: widget.goal.description ?? '',
    );
    progressController = TextEditingController(
      text: widget.goal.progress.toString(),
    );

    // 리스너 추가
    titleController.addListener(_onTextChanged);
    descriptionController.addListener(_onTextChanged);
    progressController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    // 저장 대기 중이면 닫기 전에 저장 (완료 버튼, 뒤로가기 모두 해당)
    if (debounceTimer?.isActive ?? false) _save();
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

  Future<void> _save() => widget.onSave(
    widget.goal,
    titleController.text.trim(),
    descriptionController.text.trim(),
    int.tryParse(progressController.text) ?? 0,
  );

  void _onTextChanged() {
    // 이전 타이머 취소
    debounceTimer?.cancel();

    // 새로운 타이머 시작 (500ms 후 저장)
    debounceTimer = Timer(const Duration(milliseconds: 500), _save);
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text('editor.clear_cell_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('home.cancel_button'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('editor.clear_cell_button'.tr()),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // 닫을 때 대기 중인 저장이 비운 칸을 되살리지 않도록 먼저 취소
    debounceTimer?.cancel();
    await widget.onClear();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final progress = int.tryParse(progressController.text) ?? 0;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 25),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      title: Row(
        children: [
          Icon(
            widget.goal.title.isNotEmpty
                ? Icons.edit_outlined
                : Icons.add_circle_outline,
            size: 24,
          ),
          const SizedBox(width: 10),
          Text(widget.goal.title.isNotEmpty ? 'editor.goal_dialog_title_edit'.tr() : 'editor.goal_dialog_title_new'.tr()),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width - 50,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'editor.goal_title_label'.tr(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: 'editor.goal_title_hint'.tr(),
                  prefixIcon: const Icon(Icons.flag_outlined, size: 20),
                ),
                style: const TextStyle(fontSize: 15),
                enableSuggestions: false,
                autocorrect: false,
              ),
              const SizedBox(height: 20),
              Text(
                'editor.description_label'.tr(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: 'editor.goal_description_hint'.tr(),
                  prefixIcon: const Icon(Icons.description_outlined, size: 20),
                ),
                maxLines: 3,
                style: const TextStyle(fontSize: 14),
                enableSuggestions: false,
                autocorrect: false,
              ),
              const SizedBox(height: 20),
              Text(
                'editor.goal_progress_label'.tr(),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.3),
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
        if (widget.goal.title.isNotEmpty)
          TextButton(
            onPressed: _confirmClear,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('editor.clear_cell_button'.tr()),
          ),
        TextButton.icon(
          onPressed: () => Navigator.pop(context, false),
          icon: const Icon(Icons.check_rounded, size: 18),
          label: Text('editor.done_button'.tr()),
        ),
      ],
    );
  }
}
