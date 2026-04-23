import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/theme/app_theme.dart';
import 'package:flutter_web3_wallet/features/toss/domain/toss_state.dart';
import 'toss_provider.dart';

class TossMiningScreen extends ConsumerWidget {
  const TossMiningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tossAsync = ref.watch(tossNotifierProvider);

    return tossAsync.when(
      data: (state) => _MiningBody(state: state),
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: AppColors.error))),
    );
  }
}

class _MiningBody extends ConsumerWidget {
  final TossState state;
  const _MiningBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _BalanceCard(balance: state.balance),
          const SizedBox(height: 20),
          _MiningCard(state: state),
          const SizedBox(height: 16),
          _ClaimButton(state: state, onClaim: () {
            ref.read(tossNotifierProvider.notifier).claim();
          }),
          const SizedBox(height: 20),
          _InfoCard(),
        ],
      ),
    );
  }
}

// ─── Balance Card ─────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final double balance;
  const _BalanceCard({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(20),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(60)),
                ),
                child: const Center(
                  child: Text('🐸', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOADS Balance',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Battle Toads',
                    style: TextStyle(color: AppColors.primary.withAlpha(180), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: balance),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, _) => Text(
              value.toStringAsFixed(6),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 38,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'TOADS',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mining Card ──────────────────────────────────────────────────────────────

class _MiningCard extends StatelessWidget {
  final TossState state;
  const _MiningCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final timeLeft = state.timeUntilFull;
    final hours = timeLeft.inHours;
    final minutes = timeLeft.inMinutes % 60;
    final seconds = timeLeft.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Storage',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Text(
                  '${(state.progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: state.progress),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            builder: (context, animatedProgress, _) {
              return SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(160, 160),
                      painter: _CircularProgressPainter(progress: animatedProgress),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🐸', style: TextStyle(fontSize: 32)),
                        const SizedBox(height: 4),
                        Text(
                          '+${state.pending.toStringAsFixed(6)}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Text(
                          'TOADS',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 10, letterSpacing: 1),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          if (state.isFull)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withAlpha(80)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🐸', style: TextStyle(fontSize: 14)),
                  SizedBox(width: 8),
                  Text(
                    'Ready to claim!',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  'Full in ${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ─── Claim Button ─────────────────────────────────────────────────────────────

class _ClaimButton extends StatelessWidget {
  final TossState state;
  final VoidCallback onClaim;

  const _ClaimButton({required this.state, required this.onClaim});

  @override
  Widget build(BuildContext context) {
    final canClaim = state.canClaim;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 58,
      decoration: BoxDecoration(
        gradient: canClaim ? AppColors.tossGradient : null,
        color: canClaim ? null : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canClaim ? AppColors.primary.withAlpha(80) : AppColors.cardBorder,
        ),
        boxShadow: canClaim
            ? [BoxShadow(color: AppColors.primary.withAlpha(60), blurRadius: 16, spreadRadius: 0)]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: canClaim ? onClaim : null,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(opacity: canClaim ? 1.0 : 0.35, child: const Text('🐸', style: TextStyle(fontSize: 20))),
                const SizedBox(width: 10),
                Text(
                  'Claim ${state.pending.toStringAsFixed(6)} TOADS',
                  style: TextStyle(
                    color: canClaim ? Colors.black : AppColors.textSecondary.withAlpha(100),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _InfoRow(icon: Icons.speed_outlined, label: 'Mining rate', value: '1.2 TOADS / 24h'),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.inventory_2_outlined, label: 'Per cycle', value: '0.6 TOADS / 12h'),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.link_outlined, label: 'Network', value: 'Coming soon'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─── Custom Painter ───────────────────────────────────────────────────────────

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  _CircularProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 8.0;
    const startAngle = -math.pi / 2;

    final trackPaint = Paint()
      ..color = const Color(0xFF1A2E1A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: 3 * math.pi / 2,
          colors: const [AppColors.primaryDark, AppColors.primary, AppColors.primaryGlow],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * progress,
        false,
        progressPaint,
      );

      if (progress > 0.05) {
        final glowPaint = Paint()
          ..color = AppColors.primary.withAlpha(40)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth + 6
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          2 * math.pi * progress,
          false,
          glowPaint,
        );
      }
    }

    // 20% threshold tick
    const thresholdAngle = startAngle + 2 * math.pi * 0.20;
    final reached = progress >= 0.20;
    final tickColor = reached ? AppColors.primary : const Color(0xFF4A6650);
    final inner = center + Offset(
      (radius - strokeWidth) * math.cos(thresholdAngle),
      (radius - strokeWidth) * math.sin(thresholdAngle),
    );
    final outer = center + Offset(
      (radius + strokeWidth) * math.cos(thresholdAngle),
      (radius + strokeWidth) * math.sin(thresholdAngle),
    );
    canvas.drawLine(inner, outer, Paint()
      ..color = tickColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      old.progress != progress || (old.progress >= 0.20) != (progress >= 0.20);
}
