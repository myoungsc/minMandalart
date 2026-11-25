import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/backup/backup_codec.dart';
import '../core/providers/goal_provider.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/mm_widgets.dart';
import 'settings_screen.dart';

const _maxBytes = 5 * 1024 * 1024;

/// 백업·복원. 전체 보드를 JSON 파일로 저장·공유하고, 파일을 골라 불러온다.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  final _shareKey = GlobalKey();
  bool _busy = false;

  String get _fileName =>
      'minimanda_backup_${DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '')}.json';

  /// 진행 중에는 버튼을 모두 막아 같은 작업이 두 번 실행되지 않게 한다.
  Future<void> _run(Future<void> Function() task) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await task();
    } on FormatException {
      if (mounted) _showSnack('backup.invalid_file'.tr());
    } catch (e) {
      if (mounted) _showSnack('common.error'.tr(namedArgs: {'error': '$e'}));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showDone(String message) =>
      showMmSnack(ScaffoldMessenger.of(context), context, message);

  Future<void> _save() async {
    final json = await ref.read(mandalartBoardsProvider.notifier).exportJson();
    final uri = await FilePicker.saveFile(
      fileName: _fileName,
      bytes: utf8.encode(json),
      mimeType: 'application/json',
    );
    if (uri != null && mounted) _showDone('backup.save_done'.tr());
  }

  Future<void> _share() async {
    final json = await ref.read(mandalartBoardsProvider.notifier).exportJson();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$_fileName');
    await file.writeAsString(json);
    if (!mounted) return;
    final box = _shareKey.currentContext!.findRenderObject() as RenderBox;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json')],
        // iPad에서는 공유 창을 띄울 기준 위치가 필요하다.
        sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _import({required bool replace}) async {
    final picked = await FilePicker.pickFile();
    if (picked == null || !mounted) return;
    // Android 일부 파일 관리자는 .json을 걸러 내지 못하므로 확장자를 직접 검사한다.
    if (!picked.name.toLowerCase().endsWith('.json') ||
        (await picked.length() ?? 0) > _maxBytes) {
      throw const FormatException('확장자 또는 크기');
    }
    final bytes = await picked.readAsBytes();
    if (bytes.length > _maxBytes) throw const FormatException('크기');
    // UTF-8이 아니면 FormatException. 메모장 등이 붙이는 BOM은 jsonDecode가 못 읽으므로 뗀다.
    var json = utf8.decode(bytes);
    if (json.startsWith('﻿')) json = json.substring(1);
    final boards = decodeBackup(json);
    final count = boards.length;
    if (!mounted) return;

    if (replace) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'backup.import_confirm_title'.tr(),
        body: 'backup.replace_confirm_body'.tr(namedArgs: {'count': '$count'}),
        confirmLabel: 'backup.import_replace'.tr(),
      );
      if (!confirmed || !mounted) return;
    }

    await ref
        .read(mandalartBoardsProvider.notifier)
        .importBoards(boards, replace: replace);
    if (!mounted) return;
    _showDone('backup.import_done'.tr(namedArgs: {'count': '$count'}));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.mm;
    final hasBoards =
        ref.watch(mandalartBoardsProvider).valueOrNull?.isNotEmpty ?? false;
    final canExport = hasBoards && !_busy;

    Widget row(String label, IconData icon, VoidCallback? onTap, {Key? key}) {
      return Opacity(
        key: key,
        opacity: onTap == null ? 0.38 : 1,
        child: SettingsRow(
          icon: icon,
          label: label,
          onTap: onTap,
          trailing: Icon(Icons.chevron_right_rounded, size: 22, color: c.muted),
        ),
      );
    }

    Widget hint(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Text(
            text,
            style: TextStyle(fontSize: 14, height: 1.5, color: c.muted),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const BackIcon(),
        title: Text('backup.title'.tr()),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SettingsSectionLabel('backup.export'.tr()),
            hint('backup.export_hint'.tr()),
            SettingsGroup(
              children: [
                row(
                  'backup.save'.tr(),
                  Icons.save_alt_rounded,
                  canExport ? () => _run(_save) : null,
                ),
                row(
                  'backup.share'.tr(),
                  Icons.ios_share_rounded,
                  canExport ? () => _run(_share) : null,
                  key: _shareKey,
                ),
              ],
            ),
            const SizedBox(height: 24),
            SettingsSectionLabel('backup.import'.tr()),
            hint('backup.import_hint'.tr()),
            SettingsGroup(
              children: [
                row(
                  'backup.import_merge'.tr(),
                  Icons.playlist_add_rounded,
                  _busy ? null : () => _run(() => _import(replace: false)),
                ),
                row(
                  'backup.import_replace'.tr(),
                  Icons.restore_rounded,
                  _busy ? null : () => _run(() => _import(replace: true)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
