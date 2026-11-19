import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/goal_model.dart';

/// 오늘 날짜(시간 없음). 이 값을 보는 위젯은 날짜가 바뀌면 남은 일수를 다시 그린다.
class TodayNotifier extends StateNotifier<DateTime> {
  TodayNotifier() : super(dateOnly(DateTime.now()));

  void refresh() {
    final today = dateOnly(DateTime.now());
    if (today != state) state = today;
  }
}

final todayProvider = StateNotifierProvider<TodayNotifier, DateTime>(
  (ref) => TodayNotifier(),
);

/// 자정이 지나거나 앱이 다시 앞으로 오면 [todayProvider]를 갱신한다.
/// 타이머를 위젯 수명에 묶으려고 provider가 아니라 위젯에 둔다. `MaterialApp.builder`에서 감싼다.
class TodayRefresher extends ConsumerStatefulWidget {
  final Widget child;

  const TodayRefresher({super.key, required this.child});

  @override
  ConsumerState<TodayRefresher> createState() => _TodayRefresherState();
}

class _TodayRefresherState extends ConsumerState<TodayRefresher> {
  late final AppLifecycleListener _lifecycle;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    _scheduleMidnight();
  }

  void _refresh() {
    ref.read(todayProvider.notifier).refresh();
    _scheduleMidnight();
  }

  void _scheduleMidnight() {
    _timer?.cancel();
    final now = DateTime.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    // 타이머가 자정 직전에 울려 날짜가 그대로인 일이 없게 1초 늦춘다.
    _timer = Timer(nextDay.difference(now) + const Duration(seconds: 1), _refresh);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
