import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/features/transactions/domain/transaction.dart';
import 'package:flutter_web3_wallet/features/transactions/presentation/transaction_provider.dart';
import 'transaction_detail_screen.dart';

class TransactionListScreen extends ConsumerWidget {
  final String walletAddress;

  const TransactionListScreen({super.key, required this.walletAddress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (walletAddress.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Enter wallet address in the Wallet tab')),
      );
    }

    final txAsync = ref.watch(transactionsProvider(walletAddress));

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(transactionsProvider(walletAddress)),
          ),
        ],
      ),
      body: txAsync.when(
        data: (txs) {
          if (txs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No transactions found', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.separated(
            itemCount: txs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
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
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('$e', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(transactionsProvider(walletAddress)),
                child: const Text('Retry'),
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

    return ListTile(
      leading: _DirectionIcon(direction: direction, isError: tx.isError),
      title: Row(
        children: [
          Expanded(
            child: Text(
              isIncoming ? 'Received $symbol' : 'Sent $symbol',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${isIncoming ? '+' : '-'}${tx.value.toStringAsFixed(6)} $symbol',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: tx.isError
                  ? Colors.grey
                  : isIncoming
                      ? Colors.green.shade700
                      : Colors.red.shade700,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Text(
            tx.shortHash,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          const Spacer(),
          Text(
            _formatDate(tx.timestamp),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(
              tx: tx,
              walletAddress: walletAddress,
            ),
          ),
        );
      },
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
      return CircleAvatar(
        backgroundColor: Colors.red.shade100,
        child: const Icon(Icons.error_outline, color: Colors.red, size: 20),
      );
    }
    switch (direction) {
      case TxDirection.incoming:
        return CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: const Icon(Icons.arrow_downward, color: Colors.green, size: 20),
        );
      case TxDirection.outgoing:
        return CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child: const Icon(Icons.arrow_upward, color: Colors.red, size: 20),
        );
      case TxDirection.self:
        return CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: const Icon(Icons.sync, color: Colors.blue, size: 20),
        );
    }
  }
}
