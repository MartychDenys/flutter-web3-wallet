import 'nft.dart';

abstract class NftRepository {
  Future<List<Nft>> getWalletNfts(String walletAddress);
  Future<Nft> getNftDetails(String contractAddress, BigInt tokenId, String walletAddress);
  Future<String> transferNft({
    required String privateKey,
    required String contractAddress,
    required BigInt tokenId,
    required String toAddress,
  });
}
