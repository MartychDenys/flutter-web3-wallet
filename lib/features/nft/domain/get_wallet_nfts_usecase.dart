import 'nft.dart';
import 'nft_repository.dart';

class GetWalletNftsUseCase {
  final NftRepository repository;
  GetWalletNftsUseCase(this.repository);

  Future<List<Nft>> call(String walletAddress) =>
      repository.getWalletNfts(walletAddress);
}
