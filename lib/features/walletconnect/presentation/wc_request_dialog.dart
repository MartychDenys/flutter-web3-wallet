import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_web3_wallet/features/walletconnect/domain/wc_session_request.dart';

class WcRequestDialog extends StatefulWidget {
  final WcSessionRequest request;
  final String walletAddress;
  final void Function(String privateKey) onApprove;
  final VoidCallback onReject;

  const WcRequestDialog({
    super.key,
    required this.request,
    required this.walletAddress,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<WcRequestDialog> createState() => _WcRequestDialogState();
}

class _WcRequestDialogState extends State<WcRequestDialog> {
  final _privateKeyController = TextEditingController();

  @override
  void dispose() {
    _privateKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.request.displayMethod),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RequestPreview(request: widget.request),
            const SizedBox(height: 16),
            const Text('Private Key to sign:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _privateKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Enter your private key',
                border: OutlineInputBorder(),
                isDense: true,
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onReject,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Reject'),
        ),
        ElevatedButton(
          onPressed: _privateKeyController.text.isEmpty
              ? null
              : () => widget.onApprove(_privateKeyController.text),
          child: const Text('Approve'),
        ),
      ],
    );
  }
}

class _RequestPreview extends StatelessWidget {
  final WcSessionRequest request;

  const _RequestPreview({required this.request});

  @override
  Widget build(BuildContext context) {
    final params = request.params as List<dynamic>;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: switch (request.type) {
        WcRequestType.personalSign => _MessagePreview(message: params[0] as String),
        WcRequestType.ethSign => _MessagePreview(message: params[1] as String),
        WcRequestType.sendTransaction => _TxPreview(txParams: params[0] as Map<String, dynamic>),
        WcRequestType.signTransaction => _TxPreview(txParams: params[0] as Map<String, dynamic>),
        WcRequestType.signTypedData => _TypedDataPreview(data: params[1] as String),
        WcRequestType.unknown => Text('Method: ${request.method}'),
      },
    );
  }
}

class _MessagePreview extends StatelessWidget {
  final String message;
  const _MessagePreview({required this.message});

  @override
  Widget build(BuildContext context) {
    // Try to decode hex message to readable text
    String displayMessage = message;
    if (message.startsWith('0x')) {
      try {
        final bytes = _hexToBytes(message.substring(2));
        displayMessage = utf8.decode(bytes, allowMalformed: true);
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Message to sign:',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(displayMessage,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
      ],
    );
  }

  List<int> _hexToBytes(String hex) => List.generate(
        hex.length ~/ 2,
        (i) => int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16),
      );
}

class _TxPreview extends StatelessWidget {
  final Map<String, dynamic> txParams;
  const _TxPreview({required this.txParams});

  @override
  Widget build(BuildContext context) {
    final to = txParams['to'] as String? ?? '';
    final valueHex = txParams['value'] as String? ?? '0x0';
    final valueWei = _parseBigIntHex(valueHex);
    final valueEth = valueWei.toDouble() / 1e18;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TxRow('To', '${to.substring(0, 8)}...${to.substring(to.length - 6)}'),
        _TxRow('Value', '${valueEth.toStringAsFixed(8)} ETH'),
        if (txParams['data'] != null && txParams['data'] != '0x')
          _TxRow('Data', 'Contract call'),
      ],
    );
  }

  BigInt _parseBigIntHex(String hex) {
    final clean = hex.startsWith('0x') ? hex.substring(2) : hex;
    if (clean.isEmpty) return BigInt.zero;
    return BigInt.parse(clean, radix: 16);
  }
}

class _TxRow extends StatelessWidget {
  final String label;
  final String value;
  const _TxRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _TypedDataPreview extends StatelessWidget {
  final String data;
  const _TypedDataPreview({required this.data});

  @override
  Widget build(BuildContext context) {
    String display = data;
    try {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      final domain = decoded['domain'] as Map<String, dynamic>?;
      display = domain?['name'] as String? ?? data;
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('EIP-712 Typed Data:',
            style: TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(display,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
