import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/features/nft/domain/nft.dart';
import 'package:flutter_web3_wallet/features/nft/presentation/nft_provider.dart';
import 'nft_detail_screen.dart';

class NftGridScreen extends ConsumerWidget {
  final String walletAddress;

  const NftGridScreen({super.key, required this.walletAddress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (walletAddress.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Enter wallet address in the Wallet tab')),
      );
    }

    final nftsAsync = ref.watch(walletNftsProvider(walletAddress));

    return Scaffold(
      appBar: AppBar(
        title: const Text('NFTs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(walletNftsProvider(walletAddress)),
          ),
        ],
      ),
      body: nftsAsync.when(
        data: (nfts) {
          if (nfts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No NFTs found', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text(
                    'Mint some on Sepolia testnet\nto see them here',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  '${nfts.length} NFT${nfts.length != 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: nfts.length,
                  itemBuilder: (context, i) => _NftCard(
                    nft: nfts[i],
                    walletAddress: walletAddress,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('$e', textAlign: TextAlign.center),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(walletNftsProvider(walletAddress)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NftCard extends StatelessWidget {
  final Nft nft;
  final String walletAddress;

  const _NftCard({required this.nft, required this.walletAddress});

  @override
  Widget build(BuildContext context) {
    final imageUrl = nft.metadata?.imageUrl;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NftDetailScreen(nft: nft, walletAddress: walletAddress),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _Placeholder(nft: nft),
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      },
                    )
                  : _Placeholder(nft: nft),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nft.displayName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    nft.collectionName,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final Nft nft;
  const _Placeholder({required this.nft});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.indigo.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_outlined, size: 40, color: Colors.indigo),
            const SizedBox(height: 4),
            Text(
              '#${nft.tokenId}',
              style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
