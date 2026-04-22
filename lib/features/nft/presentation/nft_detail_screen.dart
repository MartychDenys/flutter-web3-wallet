import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/features/nft/domain/nft.dart';
import 'package:flutter_web3_wallet/features/nft/presentation/nft_provider.dart';

class NftDetailScreen extends ConsumerStatefulWidget {
  final Nft nft;
  final String walletAddress;

  const NftDetailScreen({super.key, required this.nft, required this.walletAddress});

  @override
  ConsumerState<NftDetailScreen> createState() => _NftDetailScreenState();
}

class _NftDetailScreenState extends ConsumerState<NftDetailScreen> {
  final _privateKeyController = TextEditingController();
  final _toAddressController = TextEditingController();
  bool _showTransfer = false;

  @override
  void dispose() {
    _privateKeyController.dispose();
    _toAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(nftTransferNotifierProvider);
    final nft = widget.nft;
    final imageUrl = nft.metadata?.imageUrl;

    return Scaffold(
      appBar: AppBar(title: Text(nft.displayName)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            AspectRatio(
              aspectRatio: 1,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(nft),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    )
                  : _buildPlaceholder(nft),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nft.displayName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${nft.collectionName} · #${nft.tokenId}',
                    style: const TextStyle(color: Colors.grey),
                  ),

                  if (nft.metadata?.description != null) ...[
                    const SizedBox(height: 12),
                    Text(nft.metadata!.description!),
                  ],

                  // Attributes
                  if (nft.metadata != null && nft.metadata!.attributes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text('Attributes',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: nft.metadata!.attributes
                          .map((a) => _AttributeChip(attribute: a))
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Contract info
                  Card(
                    child: Column(
                      children: [
                        _InfoRow('Contract', nft.contractAddress, copyable: true),
                        _InfoRow('Token ID', '#${nft.tokenId}'),
                        _InfoRow('Standard', 'ERC-721'),
                        _InfoRow('Network', 'Sepolia Testnet'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Transfer section
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _showTransfer = !_showTransfer),
                    icon: Icon(_showTransfer ? Icons.expand_less : Icons.send_outlined),
                    label: Text(_showTransfer ? 'Cancel' : 'Transfer NFT'),
                  ),

                  if (_showTransfer) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _privateKeyController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Private Key',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _toAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Recipient Address (0x...)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.send_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _canTransfer && !txState.isLoading
                            ? _transfer
                            : null,
                        icon: txState.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send),
                        label: Text(txState.isLoading ? 'Transferring...' : 'Transfer'),
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  txState.when(
                    data: (hash) => hash == null
                        ? const SizedBox()
                        : _TxResult(txHash: hash, isSuccess: true),
                    loading: () => const SizedBox(),
                    error: (e, _) => _TxResult(txHash: e.toString(), isSuccess: false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canTransfer =>
      _privateKeyController.text.isNotEmpty && _toAddressController.text.isNotEmpty;

  void _transfer() {
    ref.read(nftTransferNotifierProvider.notifier).transfer(
          privateKey: _privateKeyController.text,
          contractAddress: widget.nft.contractAddress,
          tokenId: widget.nft.tokenId,
          toAddress: _toAddressController.text,
        );
  }

  Widget _buildPlaceholder(Nft nft) {
    return Container(
      color: Colors.indigo.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_outlined, size: 80, color: Colors.indigo),
            Text('#${nft.tokenId}',
                style: const TextStyle(
                    color: Colors.indigo, fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _AttributeChip extends StatelessWidget {
  final NftAttribute attribute;
  const _AttributeChip({required this.attribute});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade200),
      ),
      child: Column(
        children: [
          Text(attribute.traitType,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(attribute.value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;

  const _InfoRow(this.label, this.value, {this.copyable = false});

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
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
                );
              },
              child: const Icon(Icons.copy, size: 14, color: Colors.grey),
            ),
        ],
      ),
    );
  }
}

class _TxResult extends StatelessWidget {
  final String txHash;
  final bool isSuccess;
  const _TxResult({required this.txHash, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isSuccess ? Colors.green.shade200 : Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error_outline,
            color: isSuccess ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              txHash,
              style: TextStyle(
                fontSize: 12,
                color: isSuccess ? Colors.green.shade800 : Colors.red.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
