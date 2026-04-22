import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_web3_wallet/core/web3/web3_service.dart';
import 'package:flutter_web3_wallet/features/nft/domain/nft.dart';

class NftDataSource {
  static const _etherscanBase = 'https://api-sepolia.etherscan.io/api';
  // Reuse same key as EtherscanDataSource
  static const _apiKey = 'YourEtherscanApiKeyHere';

  final Web3Service web3Service;
  final Dio _dio;

  NftDataSource(this.web3Service) : _dio = Dio();

  /// Returns deduplicated list of NFTs owned by the wallet
  /// via Etherscan ERC-721 transfer history
  Future<List<Nft>> getWalletNfts(String walletAddress) async {
    final response = await _dio.get(_etherscanBase, queryParameters: {
      'module': 'account',
      'action': 'tokennfttx',
      'address': walletAddress,
      'startblock': 0,
      'endblock': 99999999,
      'sort': 'desc',
      'apikey': _apiKey,
    });

    final result = response.data as Map<String, dynamic>;
    if (result['status'] != '1') return [];

    final txList = result['result'] as List<dynamic>;

    // Build current ownership map from transfer history
    // Key = contractAddress:tokenId → last tx decides ownership
    final Map<String, _NftRef> owned = {};
    final addr = walletAddress.toLowerCase();

    for (final tx in txList) {
      final map = tx as Map<String, dynamic>;
      final contract = (map['contractAddress'] as String).toLowerCase();
      final tokenId = BigInt.parse(map['tokenId'] as String);
      final key = '$contract:$tokenId';
      final to = (map['to'] as String).toLowerCase();

      // Most recent tx for this token decides who owns it now
      if (!owned.containsKey(key)) {
        owned[key] = _NftRef(
          contractAddress: map['contractAddress'] as String,
          tokenId: tokenId,
          collectionName: map['tokenName'] as String? ?? '',
          collectionSymbol: map['tokenSymbol'] as String? ?? '',
          currentOwner: to,
        );
      }
    }

    // Keep only tokens currently owned by the wallet
    final ownedNfts = owned.values
        .where((ref) => ref.currentOwner == addr)
        .toList();

    // Enrich with tokenURI + metadata (parallel, ignore failures)
    final nfts = await Future.wait(
      ownedNfts.map((ref) => _enrichNft(ref)),
    );

    return nfts;
  }

  Future<Nft> getNftDetails(
    String contractAddress,
    BigInt tokenId,
    String walletAddress,
  ) async {
    final info = await web3Service.getNftCollectionInfo(contractAddress);
    final tokenUri = await web3Service
        .getNftTokenUri(contractAddress, tokenId)
        .catchError((_) => '');

    NftMetadata? metadata;
    if (tokenUri.isNotEmpty) {
      metadata = await _fetchMetadata(tokenUri);
    }

    return Nft(
      contractAddress: contractAddress,
      collectionName: info['name'] ?? '',
      collectionSymbol: info['symbol'] ?? '',
      tokenId: tokenId,
      tokenUri: tokenUri,
      metadata: metadata,
    );
  }

  Future<String> transferNft({
    required String privateKey,
    required String contractAddress,
    required BigInt tokenId,
    required String toAddress,
  }) {
    return web3Service.transferNft(
      privateKey: privateKey,
      contractAddress: contractAddress,
      tokenId: tokenId,
      toAddress: toAddress,
    );
  }

  Future<Nft> _enrichNft(_NftRef ref) async {
    try {
      final tokenUri = await web3Service.getNftTokenUri(
        ref.contractAddress,
        ref.tokenId,
      );
      final resolved = _resolveIpfs(tokenUri);
      NftMetadata? metadata;
      if (resolved.isNotEmpty) {
        metadata = await _fetchMetadata(resolved);
      }
      return Nft(
        contractAddress: ref.contractAddress,
        collectionName: ref.collectionName,
        collectionSymbol: ref.collectionSymbol,
        tokenId: ref.tokenId,
        tokenUri: tokenUri,
        metadata: metadata,
      );
    } catch (_) {
      return Nft(
        contractAddress: ref.contractAddress,
        collectionName: ref.collectionName,
        collectionSymbol: ref.collectionSymbol,
        tokenId: ref.tokenId,
      );
    }
  }

  Future<NftMetadata?> _fetchMetadata(String uri) async {
    try {
      final url = _resolveIpfs(uri);
      final response = await _dio.get(url);
      final json = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;
      return NftMetadata.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  String _resolveIpfs(String url) {
    if (url.startsWith('ipfs://')) {
      return url.replaceFirst('ipfs://', 'https://ipfs.io/ipfs/');
    }
    return url;
  }
}

class _NftRef {
  final String contractAddress;
  final BigInt tokenId;
  final String collectionName;
  final String collectionSymbol;
  final String currentOwner;

  _NftRef({
    required this.contractAddress,
    required this.tokenId,
    required this.collectionName,
    required this.collectionSymbol,
    required this.currentOwner,
  });
}
