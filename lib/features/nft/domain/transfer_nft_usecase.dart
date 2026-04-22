import 'nft_repository.dart';

class TransferNftUseCase {
  final NftRepository repository;
  TransferNftUseCase(this.repository);

  Future<String> call({
    required String privateKey,
    required String contractAddress,
    required BigInt tokenId,
    required String toAddress,
  }) =>
      repository.transferNft(
        privateKey: privateKey,
        contractAddress: contractAddress,
        tokenId: tokenId,
        toAddress: toAddress,
      );
}
