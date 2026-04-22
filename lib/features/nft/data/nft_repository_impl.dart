import 'package:flutter_web3_wallet/features/nft/data/data_sources/nft_data_source.dart';
import 'package:flutter_web3_wallet/features/nft/domain/nft.dart';
import 'package:flutter_web3_wallet/features/nft/domain/nft_repository.dart';

class NftRepositoryImpl implements NftRepository {
  final NftDataSource dataSource;
  NftRepositoryImpl(this.dataSource);

  @override
  Future<List<Nft>> getWalletNfts(String walletAddress) =>
      dataSource.getWalletNfts(walletAddress);

  @override
  Future<Nft> getNftDetails(
    String contractAddress,
    BigInt tokenId,
    String walletAddress,
  ) =>
      dataSource.getNftDetails(contractAddress, tokenId, walletAddress);

  @override
  Future<String> transferNft({
    required String privateKey,
    required String contractAddress,
    required BigInt tokenId,
    required String toAddress,
  }) =>
      dataSource.transferNft(
        privateKey: privateKey,
        contractAddress: contractAddress,
        tokenId: tokenId,
        toAddress: toAddress,
      );
}
