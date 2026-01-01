import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class AboutMandalartScreen extends StatelessWidget {
  const AboutMandalartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('만다라트란?'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.info_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '만다라트',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '만다라트는 일본의 디자이너 이마이즈미 히로아키가 개발한 목표 달성 도구입니다.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '메이저리그 야구선수 오타니 쇼헤이가 고등학교 시절 만다라트를 활용하여 목표를 체계적으로 관리한 것으로 유명합니다.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  '사용법',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStep(
              context,
              '1',
              '중앙에 달성하고 싶은 목표를 작성합니다',
              Icons.flag_outlined,
            ),
            const SizedBox(height: 14),
            _buildStep(
              context,
              '2',
              '주변 8칸에 목표 달성을 위한 핵심 요소를 작성합니다',
              Icons.grid_4x4_outlined,
            ),
            const SizedBox(height: 14),
            _buildStep(
              context,
              '3',
              '각 요소별로 구체적인 실행 방법을 작성합니다',
              Icons.edit_note_outlined,
            ),
            const SizedBox(height: 14),
            _buildStep(
              context,
              '4',
              '진행 상황을 체크하며 목표를 달성합니다',
              Icons.check_circle_outline_rounded,
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Theme.of(context).colorScheme.secondary,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '미니 만다라트',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '이 앱에서는 3x3 형태의 미니 만다라트를 제공합니다. '
                    '중앙에 핵심 목표를 배치하고, 주변 8칸에 이를 달성하기 위한 '
                    '세부 목표를 작성하세요. 간단하고 집중적인 형태로 목표를 관리할 수 있습니다.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.7,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    BuildContext context,
    String number,
    String text,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.textDisabled.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            size: 22,
          ),
        ],
      ),
    );
  }
}
