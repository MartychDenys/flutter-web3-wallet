import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/features/nft/data/data_sources/nft_data_source.dart';
import 'package:flutter_web3_wallet/features/nft/data/nft_repository_impl.dart';
import 'package:flutter_web3_wallet/features/nft/domain/get_wallet_nfts_usecase.dart';
import 'package:flutter_web3_wallet/features/nft/domain/nft.dart';
import 'package:flutter_web3_wallet/features/nft/domain/nft_repository.dart';
import 'package:flutter_web3_wallet/features/nft/domain/transfer_nft_usecase.dart';
import 'package:flutter_web3_wallet/features/wallet/presentation/wallet_provider.dart';

final nftRepositoryProvider = Provider<NftRepository>((ref) {
  final web3 = ref.read(web3ServiceProvider);
  return NftRepositoryImpl(NftDataSource(web3));
});

final getWalletNftsUseCaseProvider = Provider((ref) {
  return GetWalletNftsUseCase(ref.read(nftRepositoryProvider));
});

final transferNftUseCaseProvider = Provider((ref) {
  return TransferNftUseCase(ref.read(nftRepositoryProvider));
});

final walletNftsProvider =
    FutureProvider.autoDispose.family<List<Nft>, String>((ref, walletAddress) {
  if (walletAddress.isEmpty) return Future.value([]);
  return ref.read(getWalletNftsUseCaseProvider).call(walletAddress);
});

// Notifier for NFT transfer
class NftTransferNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<void> transfer({
    required String privateKey,
    required String contractAddress,
    required BigInt tokenId,
    required String toAddress,
  }) async {
    state = const AsyncLoading();
    try {
      final useCase = ref.read(transferNftUseCaseProvider);
      final txHash = await useCase(
        privateKey: privateKey,
        contractAddress: contractAddress,
        tokenId: tokenId,
        toAddress: toAddress,
      );
      state = AsyncData(txHash);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final nftTransferNotifierProvider =
    AsyncNotifierProvider<NftTransferNotifier, String?>(
  () => NftTransferNotifier(),
);
