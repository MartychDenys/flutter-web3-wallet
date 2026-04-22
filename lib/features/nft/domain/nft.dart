class Nft {
  final String contractAddress;
  final String collectionName;
  final String collectionSymbol;
  final BigInt tokenId;
  final String? tokenUri;
  final NftMetadata? metadata;

  const Nft({
    required this.contractAddress,
    required this.collectionName,
    required this.collectionSymbol,
    required this.tokenId,
    this.tokenUri,
    this.metadata,
  });

  Nft copyWith({NftMetadata? metadata}) => Nft(
        contractAddress: contractAddress,
        collectionName: collectionName,
        collectionSymbol: collectionSymbol,
        tokenId: tokenId,
        tokenUri: tokenUri,
        metadata: metadata ?? this.metadata,
      );

  String get displayName => metadata?.name ?? '$collectionName #$tokenId';
}

class NftMetadata {
  final String? name;
  final String? description;
  final String? imageUrl;
  final List<NftAttribute> attributes;

  const NftMetadata({
    this.name,
    this.description,
    this.imageUrl,
    this.attributes = const [],
  });

  factory NftMetadata.fromJson(Map<String, dynamic> json) {
    final rawImage = json['image'] as String?;
    return NftMetadata(
      name: json['name'] as String?,
      description: json['description'] as String?,
      imageUrl: rawImage != null ? _resolveIpfs(rawImage) : null,
      attributes: (json['attributes'] as List<dynamic>? ?? [])
          .map((a) => NftAttribute.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }

  // Convert ipfs:// to https gateway URL
  static String _resolveIpfs(String url) {
    if (url.startsWith('ipfs://')) {
      return url.replaceFirst('ipfs://', 'https://ipfs.io/ipfs/');
    }
    return url;
  }
}

class NftAttribute {
  final String traitType;
  final String value;

  const NftAttribute({required this.traitType, required this.value});

  factory NftAttribute.fromJson(Map<String, dynamic> json) => NftAttribute(
        traitType: json['trait_type']?.toString() ?? '',
        value: json['value']?.toString() ?? '',
      );
}
