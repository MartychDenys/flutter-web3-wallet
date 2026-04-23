import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/theme/app_theme.dart';
import 'package:flutter_web3_wallet/features/transactions/domain/transaction.dart';
import 'package:flutter_web3_wallet/features/transactions/presentation/transaction_provider.dart';
import 'transaction_detail_screen.dart';

class TransactionListScreen extends ConsumerWidget {
  final String walletAddress;

  const TransactionListScreen({super.key, required this.walletAddress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (walletAddress.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('History'), centerTitle: true),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textSecondary),
              SizedBox(height: 16),
              Text(
                'No wallet connected',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                'Enter an address in the Wallet tab',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final txAsync = ref.watch(transactionsProvider(walletAddress));

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(transactionsProvider(walletAddress)),
          ),
        ],
      ),
      body: txAsync.when(
        data: (txs) {
          if (txs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Icon(Icons.receipt_long_outlined, size: 36, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No transactions yet',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your transaction history will appear here',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: txs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _TxTile(
              tx: txs[i],
              walletAddress: walletAddress,
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(transactionsProvider(walletAddress)),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final WalletTransaction tx;
  final String walletAddress;

  const _TxTile({required this.tx, required this.walletAddress});

  @override
  Widget build(BuildContext context) {
    final direction = tx.directionFor(walletAddress);
    final isIncoming = direction == TxDirection.incoming;
    final symbol = tx.tokenSymbol ?? 'ETH';

    Color amountColor;
    if (tx.isError) {
      amountColor = AppColors.textSecondary;
    } else if (isIncoming) {
      amountColor = AppColors.accent;
    } else {
      amountColor = AppColors.error;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailScreen(tx: tx, walletAddress: walletAddress),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            _DirectionIcon(direction: direction, isError: tx.isError),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isIncoming ? 'Received $symbol' : 'Sent $symbol',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tx.shortHash,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncoming ? '+' : '-'}${tx.value.toStringAsFixed(6)} $symbol',
                  style: TextStyle(
                    color: amountColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatDate(tx.timestamp),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}.${dt.month}.${dt.year}';
  }
}

class _DirectionIcon extends StatelessWidget {
  final TxDirection direction;
  final bool isError;

  const _DirectionIcon({required this.direction, required this.isError});

  @override
  Widget build(BuildContext context) {
    if (isError) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.error_outline, color: AppColors.error, size: 20),
      );
    }
    switch (direction) {
      case TxDirection.incoming:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_downward_rounded, color: AppColors.accent, size: 20),
        );
      case TxDirection.outgoing:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.error.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.arrow_upward_rounded, color: AppColors.error, size: 20),
        );
      case TxDirection.self:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.sync_rounded, color: AppColors.primary, size: 20),
        );
    }
  }
}
