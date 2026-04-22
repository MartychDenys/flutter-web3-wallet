import 'package:flutter/material.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

class WcSessionProposalDialog extends StatelessWidget {
  final SessionProposalEvent proposal;
  final String walletAddress;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const WcSessionProposalDialog({
    super.key,
    required this.proposal,
    required this.walletAddress,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final dApp = proposal.params.proposer.metadata;
    final namespaces = {
      ...proposal.params.requiredNamespaces,
      ...proposal.params.optionalNamespaces,
    };
    final allMethods = namespaces.values
        .expand((ns) => ns.methods)
        .toSet()
        .toList()
      ..sort();

    return AlertDialog(
      title: const Text('Connection Request'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dApp.icons.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    dApp.icons.first,
                    width: 64,
                    height: 64,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.web, size: 64),
                  ),
                ),
              ),

            Text(
              dApp.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              dApp.url,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),
            const Divider(),

            // Wallet info
            ListTile(
              dense: true,
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('Wallet'),
              subtitle: Text(
                walletAddress.isEmpty
                    ? 'No address set'
                    : '${walletAddress.substring(0, 8)}...${walletAddress.substring(walletAddress.length - 6)}',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.lan_outlined),
              title: const Text('Network'),
              subtitle: const Text('Sepolia Testnet (11155111)'),
            ),

            if (allMethods.isNotEmpty) ...[
              const Divider(),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Requested permissions:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: allMethods
                    .map((m) => Chip(
                          label: Text(m, style: const TextStyle(fontSize: 11)),
                          backgroundColor: Colors.indigo.shade50,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: onReject,
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Reject'),
        ),
        ElevatedButton(
          onPressed: walletAddress.isEmpty ? null : onApprove,
          child: const Text('Connect'),
        ),
      ],
    );
  }
}
