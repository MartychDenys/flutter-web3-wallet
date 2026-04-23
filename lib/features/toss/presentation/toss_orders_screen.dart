import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/theme/app_theme.dart';
import 'package:flutter_web3_wallet/features/toss/domain/toss_order.dart';
import 'toss_provider.dart';

class TossOrdersScreen extends ConsumerStatefulWidget {
  const TossOrdersScreen({super.key});

  @override
  ConsumerState<TossOrdersScreen> createState() => _TossOrdersScreenState();
}

class _TossOrdersScreenState extends ConsumerState<TossOrdersScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh every 30s so status chips update while screen is open
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(tossNotifierProvider).valueOrNull?.orders ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders'), centerTitle: true),
      body: orders.isEmpty
          ? const _EmptyOrders()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _OrderCard(order: orders[i]),
            ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🛍️', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text(
            'Замовлень ще немає',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Майнь TOADS і купуй мерч у Shop',
            style: TextStyle(
                color: AppColors.textSecondary.withAlpha(180), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Order card ───────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final TossOrder order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final status = order.status;
    final (label, color, icon) = _statusMeta(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header row ────────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: Center(
                  child: Text(order.emoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.itemName,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Розмір: ${order.size}  ·  ${order.price.toInt()} TOADS',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Status chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 12, color: color),
                    const SizedBox(width: 4),
                    Text(label,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: AppColors.cardBorder, height: 1),
          const SizedBox(height: 12),

          // ── Progress bar ──────────────────────────────────────────
          _StatusStepper(status: status),

          const SizedBox(height: 12),

          // ── Shipping info ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${order.shipName}  ·  ${order.shipCity}\n${order.shipAddress}',
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        height: 1.5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Text(
            '#${order.id.substring(order.id.length - 6)}  ·  ${_formatDate(order.createdAt)}',
            style: TextStyle(
                color: AppColors.textSecondary.withAlpha(120), fontSize: 11),
          ),
        ],
      ),
    );
  }

  (String, Color, IconData) _statusMeta(String status) => switch (status) {
        'shipped' => ('Shipped', const Color(0xFF2196F3), Icons.local_shipping),
        'delivered' => ('Delivered', AppColors.primary, Icons.check_circle),
        _ => ('Processing', const Color(0xFFFF9800), Icons.hourglass_top),
      };

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

// ─── Status stepper ───────────────────────────────────────────────────────────

class _StatusStepper extends StatelessWidget {
  final String status;
  const _StatusStepper({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = ['Processing', 'Shipped', 'Delivered'];
    final currentIndex = status == 'delivered'
        ? 2
        : status == 'shipped'
            ? 1
            : 0;

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final filled = i ~/ 2 < currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: filled ? AppColors.primary : AppColors.cardBorder,
            ),
          );
        }
        final stepIndex = i ~/ 2;
        final done = stepIndex <= currentIndex;
        return Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: done ? AppColors.primary : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done ? AppColors.primary : AppColors.cardBorder,
                  width: 1.5,
                ),
              ),
              child: done
                  ? const Icon(Icons.check, size: 13, color: Colors.black)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              steps[stepIndex],
              style: TextStyle(
                  color: done ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight:
                      done ? FontWeight.w600 : FontWeight.normal),
            ),
          ],
        );
      }),
    );
  }
}
