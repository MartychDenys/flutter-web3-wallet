import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/ens/ens_provider.dart';
import 'package:flutter_web3_wallet/core/price/price_provider.dart';
import 'package:flutter_web3_wallet/features/hd_wallet/presentation/hd_wallet_screen.dart';
import 'package:flutter_web3_wallet/features/my_contracts/presentation/my_contracts_screen.dart';
import 'package:flutter_web3_wallet/features/nft/presentation/nft_grid_screen.dart';
import 'package:flutter_web3_wallet/features/tokens/presentation/token_list_screen.dart';
import 'package:flutter_web3_wallet/features/transactions/presentation/transaction_list_screen.dart';
import 'package:flutter_web3_wallet/features/wallet/domain/gas_params.dart';
import 'package:flutter_web3_wallet/features/wallet/domain/send_tx_params.dart';
import 'package:flutter_web3_wallet/features/wallet/presentation/wallet_provider.dart';
import 'package:flutter_web3_wallet/features/walletconnect/presentation/wc_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web3 Wallet',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final address = ref.watch(addressInputProvider);

    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: [
          const WalletScreen(),
          TokenListScreen(walletAddress: address),
          NftGridScreen(walletAddress: address),
          TransactionListScreen(walletAddress: address),
          const WcScreen(),
          const HdWalletScreen(),
          const MyContractsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.token), label: 'Tokens'),
          NavigationDestination(icon: Icon(Icons.image_outlined), label: 'NFTs'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'History'),
          NavigationDestination(icon: Icon(Icons.link), label: 'Connect'),
          NavigationDestination(icon: Icon(Icons.key), label: 'HD Wallet'),
          NavigationDestination(icon: Icon(Icons.code), label: 'Contracts'),
        ],
      ),
    );
  }
}

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  Timer? _debounce;

  final _addressController = TextEditingController();
  final _privateKeyController = TextEditingController();
  final _toAddressController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
    _addressController.dispose();
    _privateKeyController.dispose();
    _toAddressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String get _privateKey => _privateKeyController.text;
  String get _toAddress => _toAddressController.text;
  double get _amount => double.tryParse(_amountController.text) ?? 0;
  bool get _canSend =>
      _privateKey.isNotEmpty && _toAddress.isNotEmpty && _amount > 0;

  @override
  Widget build(BuildContext context) {
    final address = ref.watch(addressInputProvider);
    final submittedAddress = ref.watch(submittedAddressProvider);
    final balanceAsync = submittedAddress == null ? null : ref.watch(balanceProvider);
    final txState = ref.watch(sendTxNotifierProvider);

    final gasAsync = (address.isEmpty || _toAddress.isEmpty || _amount <= 0)
        ? null
        : ref.watch(gasFeeProvider(GasParams(from: address, to: _toAddress, amount: _amount)));

    final ethPriceAsync = ref.watch(tokenPricesProvider(['ETH']));
    final ethPrice = ethPriceAsync.valueOrNull?['ETH'];

    // ENS resolution for the "To Address" field
    final ensAsync = ref.watch(ensResolveProvider(_toAddressController.text.trim()));
    final resolvedToAddress = ensAsync.valueOrNull ?? _toAddressController.text.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('ETH Wallet')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            /// Balance card
            if (balanceAsync != null)
              Card(
                color: Colors.indigo.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: balanceAsync.when(
                    data: (bal) => Column(
                      children: [
                        const Text('Balance', style: TextStyle(color: Colors.grey)),
                        Text(
                          '${bal.toStringAsFixed(6)} ETH',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        if (ethPrice != null)
                          Text(
                            '≈ \$${(bal * ethPrice).toStringAsFixed(2)} USD',
                            style: TextStyle(fontSize: 15, color: Colors.green.shade700),
                          ),
                      ],
                    ),
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            /// Wallet address input
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Your Wallet Address or ENS (e.g. vitalik.eth)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_circle_outlined),
              ),
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 600), () {
                  final ensService = ref.read(ensServiceProvider);
                  if (ensService.isEnsName(value)) {
                    // resolve ENS then update address
                    ensService.resolve(value).then((resolved) {
                      if (resolved != null) {
                        ref.read(addressInputProvider.notifier).state = resolved;
                      }
                    });
                  } else {
                    ref.read(addressInputProvider.notifier).state = value;
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: address.isEmpty
                  ? null
                  : () => ref.read(submittedAddressProvider.notifier).state = address,
              icon: const Icon(Icons.refresh),
              label: const Text('Get Balance'),
            ),

            const Divider(height: 32),

            /// Send section
            const Text('Send ETH', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            TextField(
              controller: _privateKeyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Private Key',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _toAddressController,
              decoration: InputDecoration(
                labelText: 'To Address or ENS (e.g. vitalik.eth)',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.send_outlined),
                suffixIcon: ensAsync.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : ensAsync.valueOrNull != null
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                helperText: ensAsync.valueOrNull != null
                    ? 'Resolved: ${ensAsync.valueOrNull}'
                    : null,
                helperStyle: const TextStyle(color: Colors.green, fontSize: 11),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Amount (ETH)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () async {
                    final addr = ref.read(submittedAddressProvider);
                    if (addr == null || addr.isEmpty || _toAddress.isEmpty) return;
                    final max = await ref
                        .read(sendTxNotifierProvider.notifier)
                        .getMaxSend(address: addr, to: _toAddress);
                    _amountController.text = (max > 0 ? max : 0).toStringAsFixed(6);
                    setState(() {});
                  },
                  child: const Text('MAX'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            if (gasAsync != null)
              gasAsync.when(
                data: (fee) => Text(
                  'Fee: ${fee.toStringAsFixed(8)} ETH  |  Total: ${(_amount + fee).toStringAsFixed(8)} ETH',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                loading: () => const Text('Estimating gas...', style: TextStyle(fontSize: 13)),
                error: (e, _) => const SizedBox(),
              ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _canSend && !txState.isLoading
                  ? () => ref.read(sendTxNotifierProvider.notifier).send(
                        SendTxParams(
                          privateKey: _privateKey,
                          toAddress: resolvedToAddress,
                          amount: _amount,
                        ),
                      )
                  : null,
              icon: txState.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send),
              label: Text(txState.isLoading ? 'Sending...' : 'Send ETH'),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: () async {
                if (!_canSend) return;
                final web3 = ref.read(web3ServiceProvider);
                await web3.simulateTransaction(
                  privateKey: _privateKey,
                  toAddress: _toAddress,
                  amountInEth: _amount,
                );
              },
              icon: const Icon(Icons.preview),
              label: const Text('Simulate'),
            ),

            const SizedBox(height: 16),

            txState.when(
              data: (hash) => hash == null
                  ? const SizedBox()
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: const [
                            Icon(Icons.check_circle, color: Colors.green, size: 18),
                            SizedBox(width: 6),
                            Text('Sent!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ]),
                          const SizedBox(height: 4),
                          SelectableText(hash, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
              loading: () => const SizedBox(),
              error: (e, _) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$e', style: const TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
