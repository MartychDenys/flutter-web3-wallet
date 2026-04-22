import 'dart:math';

import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:web3dart/crypto.dart';
import 'erc20_abi.dart';
import 'erc721_abi.dart';

class Web3Service {
  final Web3Client client;

  Web3Service(String rpcUrl)
      : client = Web3Client(rpcUrl, Client());

  Future<double> getBalance(String address) async {
    final ethAddress = EthereumAddress.fromHex(address);
    final balance = await client.getBalance(ethAddress);
    return balance.getValueInUnit(EtherUnit.ether);
  }

  Future<String> sendTransaction({
    required String privateKey,
    required String toAddress,
    required double amountInEth,
  }) async {
    final credentials = EthPrivateKey.fromHex(privateKey);

    final to = EthereumAddress.fromHex(toAddress);

    final txHash = await client.sendTransaction(
      credentials,
      Transaction(
        to: to,
        value: EtherAmount.fromBase10String(
          EtherUnit.ether,
          amountInEth.toString(),
        ),
      ),
      chainId: 11155111, // Sepolia
    );

    return txHash;
  }

  Future<String> signTransaction({
    required String privateKey,
    required String toAddress,
    required double amountInEth,
  }) async {
    final credentials = EthPrivateKey.fromHex(privateKey);
    final to = EthereumAddress.fromHex(toAddress);

    final tx = Transaction(
      to: to,
      value: EtherAmount.fromBase10String(
        EtherUnit.ether,
        amountInEth.toString(),
      ),
    );

    final signed = await client.signTransaction(
      credentials,
      tx,
      chainId: 11155111,
    );

    return bytesToHex(signed, include0x: true);
  }

  Future<void> simulateTransaction({
    required String privateKey,
    required String toAddress,
    required double amountInEth,
  }) async {
    final credentials = EthPrivateKey.fromHex(privateKey);
    final sender = credentials.address;
    final to = EthereumAddress.fromHex(toAddress);

    final nonce = await client.getTransactionCount(sender);
    final gasPrice = await client.getGasPrice();

    final tx = Transaction(
      from: sender,
      to: to,
      value: EtherAmount.fromBigInt(
        EtherUnit.wei,
        BigInt.from(amountInEth * 1e18),
      ),
      gasPrice: gasPrice,
      maxGas: 21000,
      nonce: nonce,
    );

    try {
      final signed = await client.signTransaction(
        credentials,
        tx,
        chainId: 11155111,
      );

      print("SIGNED: ${bytesToHex(signed, include0x: true)}");

      final hash = await client.sendRawTransaction(signed);

      print("HASH: $hash");
    } catch (e) {
      print("ERROR: $e");
    }
  }

  Future<BigInt>
  estimateGasFee({
    required String from,
    required String to,
    required double amountInEth,
  }) async {
    final gasPrice = await client.getGasPrice();

    const gasLimit = 21000;

    return gasPrice.getInWei * BigInt.from(gasLimit.toInt());
  }

  double weiToEth(BigInt wei) {
    return wei.toDouble() / 1e18;
  }

  DeployedContract _erc20Contract(String contractAddress) {
    final contract = ContractAbi.fromJson(erc20Abi, 'ERC20');
    return DeployedContract(contract, EthereumAddress.fromHex(contractAddress));
  }

  Future<double> getTokenBalance(
    String contractAddress,
    String walletAddress,
  ) async {
    final contract = _erc20Contract(contractAddress);
    final balanceOf = contract.function('balanceOf');
    final decimals = contract.function('decimals');

    final balanceResult = await client.call(
      contract: contract,
      function: balanceOf,
      params: [EthereumAddress.fromHex(walletAddress)],
    );

    final decimalsResult = await client.call(
      contract: contract,
      function: decimals,
      params: [],
    );

    final rawBalance = balanceResult.first as BigInt;
    final tokenDecimals = (decimalsResult.first as BigInt).toInt();

    return rawBalance / BigInt.from(10).pow(tokenDecimals);
  }

  Future<Map<String, dynamic>> getTokenInfo(
    String contractAddress,
    String walletAddress,
  ) async {
    final contract = _erc20Contract(contractAddress);

    final results = await Future.wait([
      client.call(contract: contract, function: contract.function('name'), params: []),
      client.call(contract: contract, function: contract.function('symbol'), params: []),
      client.call(contract: contract, function: contract.function('decimals'), params: []),
      client.call(
        contract: contract,
        function: contract.function('balanceOf'),
        params: [EthereumAddress.fromHex(walletAddress)],
      ),
    ]);

    final tokenDecimals = (results[2].first as BigInt).toInt();
    final rawBalance = results[3].first as BigInt;

    return {
      'name': results[0].first as String,
      'symbol': results[1].first as String,
      'decimals': tokenDecimals,
      'balance': rawBalance / BigInt.from(10).pow(tokenDecimals),
    };
  }

  Future<String> transferToken({
    required String privateKey,
    required String contractAddress,
    required String toAddress,
    required double amount,
  }) async {
    final credentials = EthPrivateKey.fromHex(privateKey);
    final contract = _erc20Contract(contractAddress);
    final transfer = contract.function('transfer');

    final decimalsResult = await client.call(
      contract: contract,
      function: contract.function('decimals'),
      params: [],
    );
    final decimals = (decimalsResult.first as BigInt).toInt();
    final rawAmount = BigInt.from(amount * pow(10, decimals));

    final txHash = await client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: transfer,
        parameters: [EthereumAddress.fromHex(toAddress), rawAmount],
      ),
      chainId: 11155111,
    );

    return txHash;
  }

  Future<String> approveToken({
    required String privateKey,
    required String contractAddress,
    required String spenderAddress,
    required double amount,
  }) async {
    final credentials = EthPrivateKey.fromHex(privateKey);
    final contract = _erc20Contract(contractAddress);
    final approve = contract.function('approve');

    final decimalsResult = await client.call(
      contract: contract,
      function: contract.function('decimals'),
      params: [],
    );
    final decimals = (decimalsResult.first as BigInt).toInt();
    final rawAmount = BigInt.from(amount * pow(10, decimals));

    final txHash = await client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: approve,
        parameters: [EthereumAddress.fromHex(spenderAddress), rawAmount],
      ),
      chainId: 11155111,
    );

    return txHash;
  }

  Future<double> getAllowance({
    required String contractAddress,
    required String ownerAddress,
    required String spenderAddress,
  }) async {
    final contract = _erc20Contract(contractAddress);
    final allowance = contract.function('allowance');
    final decimalsResult = await client.call(
      contract: contract,
      function: contract.function('decimals'),
      params: [],
    );
    final decimals = (decimalsResult.first as BigInt).toInt();

    final result = await client.call(
      contract: contract,
      function: allowance,
      params: [
        EthereumAddress.fromHex(ownerAddress),
        EthereumAddress.fromHex(spenderAddress),
      ],
    );

    final rawAllowance = result.first as BigInt;
    return rawAllowance / BigInt.from(10).pow(decimals);
  }

  // ─── ERC721 ───────────────────────────────────────────────

  DeployedContract _erc721Contract(String contractAddress) {
    final abi = ContractAbi.fromJson(erc721Abi, 'ERC721');
    return DeployedContract(abi, EthereumAddress.fromHex(contractAddress));
  }

  Future<String> getNftTokenUri(String contractAddress, BigInt tokenId) async {
    final contract = _erc721Contract(contractAddress);
    final result = await client.call(
      contract: contract,
      function: contract.function('tokenURI'),
      params: [tokenId],
    );
    return result.first as String;
  }

  Future<Map<String, String>> getNftCollectionInfo(String contractAddress) async {
    final contract = _erc721Contract(contractAddress);
    final results = await Future.wait([
      client.call(contract: contract, function: contract.function('name'), params: []),
      client.call(contract: contract, function: contract.function('symbol'), params: []),
    ]);
    return {
      'name': results[0].first as String,
      'symbol': results[1].first as String,
    };
  }

  Future<String> transferNft({
    required String privateKey,
    required String contractAddress,
    required BigInt tokenId,
    required String toAddress,
  }) async {
    final credentials = EthPrivateKey.fromHex(privateKey);
    final contract = _erc721Contract(contractAddress);
    final safeTransfer = contract.function('safeTransferFrom');

    final txHash = await client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: safeTransfer,
        parameters: [
          credentials.address,
          EthereumAddress.fromHex(toAddress),
          tokenId,
        ],
      ),
      chainId: 11155111,
    );
    return txHash;
  }

  /// Mint a DevNFT — calls mint(address to, string customURI)
  Future<String> mintNft({
    required String privateKey,
    required String contractAddress,
    required String toAddress,
    String customUri = '',
  }) async {
    final credentials = EthPrivateKey.fromHex(privateKey);
    final contract = _erc721Contract(contractAddress);
    final mintFn = contract.function('mint');

    final txHash = await client.sendTransaction(
      credentials,
      Transaction.callContract(
        contract: contract,
        function: mintFn,
        parameters: [EthereumAddress.fromHex(toAddress), customUri],
      ),
      chainId: 11155111,
    );
    return txHash;
  }

  /// Read totalSupply from DevNFT
  Future<BigInt> getNftTotalSupply(String contractAddress) async {
    final contract = _erc721Contract(contractAddress);
    final result = await client.call(
      contract: contract,
      function: contract.function('totalSupply'),
      params: [],
    );
    return result.first as BigInt;
  }
}
