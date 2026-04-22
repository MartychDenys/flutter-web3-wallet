import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/features/tokens/domain/token.dart';
import 'package:flutter_web3_wallet/features/tokens/presentation/token_provider.dart';

class TokenTransferScreen extends ConsumerStatefulWidget {
  final Token token;
  final String walletAddress;

  const TokenTransferScreen({
    super.key,
    required this.token,
    required this.walletAddress,
  });

  @override
  ConsumerState<TokenTransferScreen> createState() => _TokenTransferScreenState();
}

class _TokenTransferScreenState extends ConsumerState<TokenTransferScreen> {
  final _privateKeyController = TextEditingController();
  final _toAddressController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _privateKeyController.dispose();
    _toAddressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _privateKeyController.text.isNotEmpty &&
      _toAddressController.text.isNotEmpty &&
      (double.tryParse(_amountController.text) ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(tokenTransferNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Send ${widget.token.symbol}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BalanceCard(token: widget.token),
            const SizedBox(height: 24),

            TextField(
              controller: _privateKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Private Key',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _toAddressController,
              decoration: const InputDecoration(
                labelText: 'Recipient Address (0x...)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.send_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Amount (${widget.token.symbol})',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.monetization_on_outlined),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    _amountController.text =
                        widget.token.balance.toStringAsFixed(6);
                    setState(() {});
                  },
                  child: const Text('MAX'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _canSend && !txState.isLoading
                    ? () {
                        ref.read(tokenTransferNotifierProvider.notifier).transfer(
                              privateKey: _privateKeyController.text,
                              contractAddress: widget.token.contractAddress,
                              toAddress: _toAddressController.text,
                              amount: double.parse(_amountController.text),
                            );
                      }
                    : null,
                icon: txState.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                label: Text(txState.isLoading ? 'Sending...' : 'Send ${widget.token.symbol}'),
              ),
            ),

            const SizedBox(height: 16),

            txState.when(
              data: (hash) => hash == null
                  ? const SizedBox()
                  : _TxSuccess(txHash: hash),
              loading: () => const SizedBox(),
              error: (e, _) => _TxError(error: e.toString()),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final Token token;

  const _BalanceCard({required this.token});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.indigo.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Text(
                token.symbol.length > 2
                    ? token.symbol.substring(0, 2)
                    : token.symbol,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(token.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${token.balance.toStringAsFixed(6)} ${token.symbol}',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TxSuccess extends StatelessWidget {
  final String txHash;

  const _TxSuccess({required this.txHash});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Transaction sent!',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            txHash,
            style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
          ),
        ],
      ),
    );
  }
}

class _TxError extends StatelessWidget {
  final String error;

  const _TxError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(error, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
