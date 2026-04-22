import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:web3dart/crypto.dart';

class EnsService {
  static const _rpc = 'https://cloudflare-eth.com';

  bool isEnsName(String input) =>
      input.trim().toLowerCase().endsWith('.eth');

  Future<String?> resolve(String ensName) async {
    try {
      final name = ensName.trim().toLowerCase();
      final node = _namehash(name);
      final nodeHex = node.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

      // ENS Universal Resolver on Ethereum mainnet
      const resolver = '0xc0497E381f536Be9ce14B0dD3817cBcAe57d2F62';

      // addr(bytes32 node) = selector 0x3b3b57de
      final data = '0x3b3b57de$nodeHex';

      final body = jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'eth_call',
        'params': [
          {'to': resolver, 'data': data},
          'latest',
        ],
      });

      final response = await http.post(
        Uri.parse(_rpc),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final result = json['result'] as String?;

      if (result == null || result == '0x' || result.length < 66) return null;

      final address = '0x${result.substring(result.length - 40)}';
      if (address == '0x0000000000000000000000000000000000000000') return null;

      return address;
    } catch (_) {
      return null;
    }
  }

  /// EIP-137 namehash
  Uint8List _namehash(String name) {
    var node = Uint8List(32);

    if (name.isEmpty) return node;

    final labels = name.split('.').reversed.toList();
    for (final label in labels) {
      final labelHash = keccak256(Uint8List.fromList(utf8.encode(label)));
      node = keccak256(Uint8List.fromList([...node, ...labelHash]));
    }
    return node;
  }
}
