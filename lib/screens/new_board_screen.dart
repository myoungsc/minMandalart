import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/goal_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/mm_widgets.dart';
import '../models/goal_model.dart';
import 'board_screen.dart';

class NewBoardScreen extends ConsumerStatefulWidget {
  const NewBoardScreen({super.key});

  @override
  ConsumerState<NewBoardScreen> createState() => _NewBoardScreenState();
}

class _NewBoardScreenState extends ConsumerState<NewBoardScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  bool _showError = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() => _showError = false));
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);

    final messenger = ScaffoldMessenger.of(context);
    final description = _description.text.trim();
    try {
      final id = await ref
          .read(databaseProvider)
          .createBoardWithEmptyGoals(
            MandalartBoard(
              centerGoal: title,
              description: description.isEmpty ? null : description,
              createdAt: DateTime.now(),
            ),
          );
      await ref.read(mandalartBoardsProvider.notifier).loadBoards();
      await ref.read(currentBoardProvider.notifier).loadBoard(id);
      if (!mounted) return;
      showMmSnack(messenger, context, 'new.created'.tr());
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BoardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('common.error'.tr(namedArgs: {'error': '$e'}))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    final preview = _title.text.trim();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'common.close'.tr(),
          iconSize: 26,
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('new.title'.tr()),
      ),
      bottomNavigationBar: BottomAction(
        child: PrimaryButton(label: 'new.create'.tr(), onTap: _create),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ExcludeSemantics(
                child: SizedBox(
                  width: 132,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridView.count(
                      crossAxisCount: 3,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (int i = 0; i < 9; i++)
                          if (i == 4)
                            Container(
                              padding: const EdgeInsets.all(4),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: c.center,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                preview.isNotEmpty ? preview : 'common.center_goal'.tr(),
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: c.onCenter,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  height: 1.25,
                                ),
                              ),
                            )
                          else
                            const DashedBox(radius: 4),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            FieldLabel('common.center_goal'.tr(), required: true),
            const SizedBox(height: 8),
            MmField(
              controller: _title,
              hint: 'common.center_hint'.tr(),
              emphasized: true,
              hasError: _showError,
              maxLength: 40,
              singleParagraph: true,
            ),
            const SizedBox(height: 8),
            if (_showError)
              FieldError('new.error'.tr())
            else
              FieldHelper(
                'new.helper'.tr(namedArgs: {'count': '${_title.text.length}'}),
              ),
            const SizedBox(height: 22),
            FieldLabel('common.description_optional'.tr()),
            const SizedBox(height: 8),
            MmField(
              controller: _description,
              hint: 'common.description_hint'.tr(),
              minLines: 3,
              maxLength: 100,
            ),
          ],
        ),
      ),
    );
  }
}
