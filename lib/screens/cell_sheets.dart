import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/goal_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/mm_widgets.dart';
import '../models/goal_model.dart';

const _autoSaveDelay = Duration(milliseconds: 500);
const _maxTitleLength = 40;
const _maxDescriptionLength = 100;

Future<void> showCellSheet(BuildContext context, int goalId) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (_) => _CellSheet(goalId: goalId),
  );
}

Future<void> showCenterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    isScrollControlled: true,
    // 제목이 비어 있으면 닫히지 않아야 하므로 끌어내리기를 쓰지 않는다.
    enableDrag: false,
    builder: (_) => const _CenterSheet(),
  );
}

/// 세부 목표 편집. 입력은 자동 저장되고, 닫을 때 대기 중인 저장을 마저 처리한다.
class _CellSheet extends ConsumerStatefulWidget {
  final int goalId;

  const _CellSheet({required this.goalId});

  @override
  ConsumerState<_CellSheet> createState() => _CellSheetState();
}

class _CellSheetState extends ConsumerState<_CellSheet> {
  late final CurrentBoardNotifier _notifier;
  late final TextEditingController _title;
  late final TextEditingController _memo;
  final _newItem = TextEditingController();
  late ScaffoldMessengerState _messenger;
  late String _savedTitle;
  Timer? _saveTimer;

  Goal? _readGoal() => ref
      .read(currentBoardProvider)
      ?.subGoals
      .where((g) => g.id == widget.goalId)
      .firstOrNull;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(currentBoardProvider.notifier);
    final goal = _readGoal();
    _savedTitle = goal?.title ?? '';
    _title = TextEditingController(text: _savedTitle)..addListener(_onTextChanged);
    _memo = TextEditingController(text: goal?.description ?? '')
      ..addListener(_onTextChanged);
    _newItem.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
  }

  @override
  void dispose() {
    if (_saveTimer?.isActive ?? false) _save();
    _saveTimer?.cancel();
    _title.dispose();
    _memo.dispose();
    _newItem.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {});
    _saveTimer?.cancel();
    _saveTimer = Timer(_autoSaveDelay, _save);
  }

  Future<void> _save() async {
    // 제목을 지운 채여도 저장된 제목을 유지한다. 칸을 비우는 건 "칸 비우기"만 한다.
    final typed = _title.text.trim();
    final title = typed.isNotEmpty ? typed : _savedTitle;
    if (title.isEmpty) return;
    _savedTitle = title;
    final memo = _memo.text.trim();
    await _guard(
      _notifier.updateGoalText(widget.goalId, title, memo.isEmpty ? null : memo),
    );
  }

  /// 체크리스트 동작 전에 입력 중인 제목을 먼저 저장한다.
  Future<void> _flush() async {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      await _save();
    }
  }

  Future<void> _guard(Future<void> write) async {
    try {
      await write;
    } catch (e) {
      _messenger.showSnackBar(
        SnackBar(
          content: Text('common.error'.tr(namedArgs: {'error': '$e'})),
        ),
      );
    }
  }

  Future<void> _toggleDone(Goal goal) async {
    await _flush();
    await _guard(_notifier.setGoalCompleted(widget.goalId, goal.progress < 100));
  }

  Future<void> _addItem() async {
    final text = _newItem.text.trim();
    if (text.isEmpty) return;
    _newItem.clear();
    await _flush();
    await _guard(_notifier.addChecklistItem(widget.goalId, text));
  }

  Future<void> _clear() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'cell.clear_title'.tr(),
      body: 'cell.clear_body'.tr(),
      confirmLabel: 'cell.clear_cta'.tr(),
    );
    if (!confirmed || !mounted) return;

    // 닫을 때 대기 중인 저장이 비운 칸을 되살리지 않도록 먼저 취소
    _saveTimer?.cancel();
    await _guard(_notifier.clearGoal(widget.goalId));
    if (!mounted) return;
    showMmSnack(_messenger, context, 'cell.cleared'.tr());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    ref.watch(currentBoardProvider);
    final goal = _readGoal();
    if (goal == null) return const SizedBox.shrink();

    final locked = _title.text.trim().isEmpty;
    final items = goal.checklistItems;
    final doneCount = items.where((i) => i.isDone).length;

    return MmSheetFrame(
      label: 'cell.sheet_label'.tr(),
      onDone: () => Navigator.maybePop(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FieldLabel('cell.title_label'.tr()),
          const SizedBox(height: 8),
          MmField(
            controller: _title,
            hint: 'cell.title_hint'.tr(),
            emphasized: true,
            maxLength: _maxTitleLength,
            singleParagraph: true,
          ),
          const SizedBox(height: 8),
          FieldHelper(
            'cell.title_helper'.tr(namedArgs: {'count': '${_title.text.length}'}),
          ),
          const SizedBox(height: 18),
          FieldLabel('cell.memo_label'.tr()),
          const SizedBox(height: 8),
          MmField(controller: _memo, hint: 'cell.memo_hint'.tr()),
          const SizedBox(height: 18),
          if (locked) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: c.tile,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_rounded, size: 18, color: c.muted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'cell.locked'.tr(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: c.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          Opacity(
            opacity: locked ? 0.38 : 1,
            child: IgnorePointer(
              ignoring: locked,
              child: ExcludeSemantics(
                excluding: locked,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (items.isEmpty) ...[
                      _DoneToggle(
                        value: goal.progress >= 100,
                        onChanged: () => _toggleDone(goal),
                      ),
                      const SizedBox(height: 18),
                    ],
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'cell.checklist'.tr(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (items.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: c.accent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'cell.progress'.tr(
                                  namedArgs: {
                                    'done': '$doneCount',
                                    'total': '${items.length}',
                                    'pct': '${goal.progress}',
                                  },
                                ),
                                style: const TextStyle(
                                  color: MmColors.onAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (items.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: FieldHelper('cell.auto_hint'.tr()),
                      ),
                    for (final item in items) _itemRow(c, item),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 52),
                      child: Row(
                        children: [
                          Icon(Icons.add_rounded, size: 22, color: c.muted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _newItem,
                              autocorrect: false,
                              enableSuggestions: false,
                              textInputAction: TextInputAction.done,
                              // 포커스를 유지해 항목을 이어서 추가할 수 있게 한다.
                              onEditingComplete: _addItem,
                              style: TextStyle(fontSize: 15, color: c.ink),
                              decoration: InputDecoration(
                                hintText: 'cell.add_hint'.tr(),
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_newItem.text.trim().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: _addItem,
                              style: FilledButton.styleFrom(
                                backgroundColor: c.ink,
                                foregroundColor: c.bg,
                                minimumSize: const Size(44, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                tapTargetSize: MaterialTapTargetSize.padded,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              child: Text(
                                'cell.add_button'.tr(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (goal.title.isNotEmpty) ...[
            const SizedBox(height: 6),
            Center(
              child: TextButton.icon(
                onPressed: _clear,
                style: TextButton.styleFrom(
                  foregroundColor: c.muted,
                  minimumSize: const Size(44, 44),
                ),
                icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                label: Text(
                  'cell.clear'.tr(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _itemRow(MmColors c, ChecklistItem item) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.tile)),
      ),
      child: Row(
        children: [
          Transform.translate(
            offset: const Offset(-11, 0),
            child: Checkbox(
              value: item.isDone,
              onChanged: (value) =>
                  _guard(_notifier.setChecklistItemDone(item, value ?? false)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                item.title,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: item.isDone ? c.muted : c.ink,
                  decoration: item.isDone ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(10, 0),
            child: IconButton(
              tooltip: 'cell.delete_item'.tr(),
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              padding: EdgeInsets.zero,
              iconSize: 20,
              color: c.muted,
              icon: const Icon(Icons.close_rounded),
              onPressed: () => _guard(_notifier.deleteChecklistItem(item)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoneToggle extends StatelessWidget {
  final bool value;
  final VoidCallback onChanged;

  const _DoneToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: c.line, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'cell.toggle_title'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'cell.toggle_subtitle'.tr(),
                    style: TextStyle(fontSize: 12, color: c.muted, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(value: value, onChanged: (_) => onChanged()),
          ],
        ),
      ),
    );
  }
}

/// 중앙 목표 수정. 제목이 비어 있으면 오류를 보여 주고 닫히지 않는다.
class _CenterSheet extends ConsumerStatefulWidget {
  const _CenterSheet();

  @override
  ConsumerState<_CenterSheet> createState() => _CenterSheetState();
}

class _CenterSheetState extends ConsumerState<_CenterSheet> {
  late final CurrentBoardNotifier _notifier;
  late final TextEditingController _title;
  late final TextEditingController _description;
  bool _showError = false;
  Timer? _saveTimer;

  bool get _titleEmpty => _title.text.trim().isEmpty;

  @override
  void initState() {
    super.initState();
    _notifier = ref.read(currentBoardProvider.notifier);
    final board = ref.read(currentBoardProvider);
    _title = TextEditingController(text: board?.centerGoal ?? '')
      ..addListener(_onChanged);
    _description = TextEditingController(text: board?.description ?? '')
      ..addListener(_onChanged);
  }

  @override
  void dispose() {
    if (_saveTimer?.isActive ?? false) _save();
    _saveTimer?.cancel();
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() => _showError = false);
    _saveTimer?.cancel();
    _saveTimer = Timer(_autoSaveDelay, _save);
  }

  Future<void> _save() async {
    if (_titleEmpty) return;
    final description = _description.text.trim();
    await _notifier.updateBoardText(
      _title.text.trim(),
      description.isEmpty ? null : description,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_titleEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _showError = true);
      },
      child: MmSheetFrame(
        label: 'center.sheet_label'.tr(),
        onDone: () => Navigator.maybePop(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FieldLabel('common.center_goal'.tr(), required: true),
            const SizedBox(height: 8),
            MmField(
              controller: _title,
              hint: 'common.center_hint'.tr(),
              emphasized: true,
              hasError: _showError,
              maxLength: _maxTitleLength,
              singleParagraph: true,
            ),
            const SizedBox(height: 8),
            if (_showError)
              FieldError('center.error'.tr())
            else
              FieldHelper('center.helper'.tr()),
            const SizedBox(height: 18),
            FieldLabel('common.description_optional'.tr()),
            const SizedBox(height: 8),
            MmField(
              controller: _description,
              hint: 'common.description_hint'.tr(),
              minLines: 3,
              maxLength: _maxDescriptionLength,
            ),
          ],
        ),
      ),
    );
  }
}
