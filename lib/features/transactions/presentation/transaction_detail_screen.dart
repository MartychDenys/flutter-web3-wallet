import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web3_wallet/features/transactions/domain/transaction.dart';

class TransactionDetailScreen extends StatelessWidget {
  final WalletTransaction tx;
  final String walletAddress;

  const TransactionDetailScreen({
    super.key,
    required this.tx,
    required this.walletAddress,
  });

  @override
  Widget build(BuildContext context) {
    final direction = tx.directionFor(walletAddress);
    final symbol = tx.tokenSymbol ?? 'ETH';
    final isIncoming = direction == TxDirection.incoming;

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// Status card
            Card(
              color: tx.isError
                  ? Colors.red.shade50
                  : isIncoming
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Icon(
                      tx.isError
                          ? Icons.cancel
                          : isIncoming
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                      size: 48,
                      color: tx.isError
                          ? Colors.red
                          : isIncoming
                              ? Colors.green
                              : Colors.orange,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tx.isError
                          ? 'Failed'
                          : isIncoming
                              ? 'Received'
                              : 'Sent',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${tx.value.toStringAsFixed(8)} $symbol',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                    if (tx.tokenName != null)
                      Text(tx.tokenName!, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Details
            Card(
              child: Column(
                children: [
                  _DetailRow('Type', tx.type == TxType.eth ? 'ETH Transfer' : 'ERC20 Transfer'),
                  _DetailRow('Status', tx.isError ? 'Failed' : 'Success'),
                  _DetailRow('Date', _formatFullDate(tx.timestamp)),
                  _DetailRow('Fee', '${tx.fee.toStringAsFixed(8)} ETH'),
                  _CopyRow('Hash', tx.hash),
                  _CopyRow('From', tx.from),
                  _CopyRow('To', tx.to),
                ],
              ),
            ),

            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: () => _openEtherscan(context, tx.hash),
              icon: const Icon(Icons.open_in_new),
              label: const Text('View on Etherscan'),
            ),
          ],
        ),
      ),
    );
  }

  void _openEtherscan(BuildContext context, String hash) {
    final url = 'https://sepolia.etherscan.io/tx/$hash';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: SelectableText('Open in browser:\n$url'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  String _formatFullDate(DateTime dt) {
    return '${dt.day}.${dt.month}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final String label;
  final String value;

  const _CopyRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
              );
            },
          ),
        ],
      ),
    );
  }
}
