import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/contracts/deployed_contracts.dart';
import 'package:flutter_web3_wallet/features/my_contracts/presentation/my_contracts_notifier.dart';
import 'package:flutter_web3_wallet/features/my_contracts/presentation/my_contracts_provider.dart';
import 'package:flutter_web3_wallet/features/wallet/presentation/wallet_provider.dart';

class MyContractsScreen extends ConsumerStatefulWidget {
  const MyContractsScreen({super.key});

  @override
  ConsumerState<MyContractsScreen> createState() => _MyContractsScreenState();
}

class _MyContractsScreenState extends ConsumerState<MyContractsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final address = ref.read(addressInputProvider);
      ref.read(myContractsNotifierProvider.notifier).loadData(address);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myContractsNotifierProvider);
    final walletAddress = ref.watch(addressInputProvider);

    ref.listen(myContractsNotifierProvider, (_, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () => ref.read(myContractsNotifierProvider.notifier).clearError(),
          ),
        ));
      }
      if (next.lastTxHash != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Transaction sent!', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(next.lastTxHash!, style: const TextStyle(fontSize: 11)),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Contracts'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref
                .read(myContractsNotifierProvider.notifier)
                .loadData(walletAddress),
          ),
        ],
      ),
      body: walletAddress.isEmpty
          ? const _NoAddressPlaceholder()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DeployedBadge(),
                  const SizedBox(height: 16),
                  _DevTokenCard(state: state, walletAddress: walletAddress),
                  const SizedBox(height: 16),
                  _DevNftCard(state: state, walletAddress: walletAddress),
                ],
              ),
            ),
    );
  }
}

// ─── Header badge ─────────────────────────────────────────

class _DeployedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade700, Colors.indigo.shade400],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified, color: Colors.white),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deployed on Sepolia Testnet',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Written from scratch · Verified on Etherscan',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DEV Token Card ───────────────────────────────────────

class _DevTokenCard extends ConsumerStatefulWidget {
  final MyContractsState state;
  final String walletAddress;

  const _DevTokenCard({required this.state, required this.walletAddress});

  @override
  ConsumerState<_DevTokenCard> createState() => _DevTokenCardState();
}

class _DevTokenCardState extends ConsumerState<_DevTokenCard> {
  bool _showTransfer = false;
  final _pkController = TextEditingController();
  final _toController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _pkController.dispose();
    _toController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Text('DEV',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DevToken',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('ERC20 · Written from scratch',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                _ContractLink(address: DeployedContracts.devTokenAddress),
              ],
            ),

            const SizedBox(height: 12),

            if (s.isLoadingBalance)
              const LinearProgressIndicator()
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('Your balance:',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const Spacer(),
                    Text(
                      s.devTokenBalance != null
                          ? '${s.devTokenBalance!.toStringAsFixed(2)} DEV'
                          : '—',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () => setState(() => _showTransfer = !_showTransfer),
              icon: Icon(_showTransfer ? Icons.expand_less : Icons.send_outlined),
              label: Text(_showTransfer ? 'Cancel' : 'Transfer DEV'),
            ),

            if (_showTransfer) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _pkController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Private Key',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _toController,
                decoration: const InputDecoration(
                  labelText: 'To Address (0x...)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*'))],
                decoration: const InputDecoration(
                  labelText: 'Amount (DEV)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: s.isTransferring ? null : _transfer,
                  icon: s.isTransferring
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send),
                  label: Text(s.isTransferring ? 'Sending...' : 'Send DEV'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _transfer() {
    final amount = double.tryParse(_amountController.text) ?? 0;
    if (_pkController.text.isEmpty || _toController.text.isEmpty || amount <= 0) return;
    ref.read(myContractsNotifierProvider.notifier).transferDevToken(
          privateKey: _pkController.text,
          toAddress: _toController.text,
          amount: amount,
          walletAddress: widget.walletAddress,
        );
  }
}

// ─── DevNFT Card ──────────────────────────────────────────

class _DevNftCard extends ConsumerStatefulWidget {
  final MyContractsState state;
  final String walletAddress;

  const _DevNftCard({required this.state, required this.walletAddress});

  @override
  ConsumerState<_DevNftCard> createState() => _DevNftCardState();
}

class _DevNftCardState extends ConsumerState<_DevNftCard> {
  bool _showMint = false;
  final _pkController = TextEditingController();
  final _toController = TextEditingController();
  final _uriController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill "to" with wallet address
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _toController.text = widget.walletAddress;
    });
  }

  @override
  void dispose() {
    _pkController.dispose();
    _toController.dispose();
    _uriController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    final supply = s.devNftTotalSupply;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.purple.shade100,
                  child: const Text('NFT',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple)),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('DevNFT',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('ERC721 · Written from scratch',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                _ContractLink(address: DeployedContracts.devNftAddress),
              ],
            ),

            const SizedBox(height: 12),

            if (s.isLoadingBalance)
              const LinearProgressIndicator()
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('Total minted:',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                    const Spacer(),
                    Text(
                      supply != null ? '${supply.toString()} DNFT' : '—',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () => setState(() => _showMint = !_showMint),
              icon: Icon(_showMint ? Icons.expand_less : Icons.add_circle_outline),
              label: Text(_showMint ? 'Cancel' : 'Mint DevNFT'),
            ),

            if (_showMint) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.amber, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Only contract owner can mint. Use the deployer private key.',
                        style: TextStyle(fontSize: 12, color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _pkController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Owner Private Key',
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _toController,
                decoration: const InputDecoration(
                  labelText: 'Mint to Address',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _uriController,
                decoration: const InputDecoration(
                  labelText: 'Custom URI (optional, e.g. ipfs://...)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  onPressed: s.isMinting ? null : _mint,
                  icon: s.isMinting
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.add, color: Colors.white),
                  label: Text(
                    s.isMinting ? 'Minting...' : 'Mint NFT',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _mint() {
    if (_pkController.text.isEmpty || _toController.text.isEmpty) return;
    ref.read(myContractsNotifierProvider.notifier).mintNft(
          privateKey: _pkController.text,
          toAddress: _toController.text,
          customUri: _uriController.text,
        );
  }
}

// ─── Shared widgets ───────────────────────────────────────

class _ContractLink extends StatelessWidget {
  final String address;
  const _ContractLink({required this.address});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: address));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address copied'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified, color: Colors.green, size: 14),
            const SizedBox(width: 4),
            Text(
              '${address.substring(0, 6)}...${address.substring(address.length - 4)}',
              style: const TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: Colors.green,
                  fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoAddressPlaceholder extends StatelessWidget {
  const _NoAddressPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_circle_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('Enter wallet address in the Wallet tab',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
