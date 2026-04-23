import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/ens/ens_provider.dart';
import 'package:flutter_web3_wallet/core/price/price_provider.dart';
import 'package:flutter_web3_wallet/core/theme/app_theme.dart';
import 'package:flutter_web3_wallet/features/hd_wallet/presentation/hd_wallet_screen.dart';
import 'package:flutter_web3_wallet/features/my_contracts/presentation/my_contracts_screen.dart';
import 'package:flutter_web3_wallet/features/nft/presentation/nft_grid_screen.dart';
import 'package:flutter_web3_wallet/features/tokens/presentation/token_list_screen.dart';
import 'package:flutter_web3_wallet/features/transactions/presentation/transaction_list_screen.dart';
import 'package:flutter_web3_wallet/features/wallet/domain/gas_params.dart';
import 'package:flutter_web3_wallet/features/wallet/domain/send_tx_params.dart';
import 'package:flutter_web3_wallet/features/wallet/presentation/wallet_provider.dart';
import 'package:flutter_web3_wallet/features/toss/presentation/toss_mining_screen.dart';
import 'package:flutter_web3_wallet/features/toss/presentation/toss_orders_screen.dart';
import 'package:flutter_web3_wallet/features/toss/presentation/toss_provider.dart';
import 'package:flutter_web3_wallet/features/toss/presentation/toss_shop_screen.dart';
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
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
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
  // 0 = Mining, 1 = Wallet, 2 = Shop
  int _tab = 0;

  static const _titles = ['Mining', 'Wallet', 'Shop'];

  @override
  Widget build(BuildContext context) {
    final address = ref.watch(addressInputProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tab]),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: _tab == 1
            ? [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accent.withAlpha(60)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(radius: 4, backgroundColor: AppColors.accent),
                        SizedBox(width: 6),
                        Text('Sepolia', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ]
            : _tab == 2
                ? [_TossBalanceBadge()]
                : null,
      ),
      drawer: _AppDrawer(address: address),
      body: IndexedStack(
        index: _tab,
        children: [
          const TossMiningScreen(),
          const WalletScreen(),
          const TossShopScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.bolt_outlined), selectedIcon: Icon(Icons.bolt), label: 'Mining'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Shop'),
        ],
      ),
    );
  }
}

// ─── TOSS Balance Badge (для AppBar Shop) ─────────────────────────────────────

class _TossBalanceBadge extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(tossNotifierProvider).valueOrNull?.balance ?? 0.0;
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐸', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(balance.toStringAsFixed(2), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(width: 4),
            const Text('TOADS', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─── App Drawer ───────────────────────────────────────────────────────────────

class _AppDrawer extends StatelessWidget {
  final String address;
  const _AppDrawer({required this.address});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.primary.withAlpha(60)),
                    ),
                    child: const Center(child: Text('🐸', style: TextStyle(fontSize: 26))),
                  ),
                  const SizedBox(height: 12),
                  const Text('Battle Toads', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                  Text('Earn TOADS. Buy merch.', style: TextStyle(color: AppColors.primary.withAlpha(180), fontSize: 12)),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Divider(color: AppColors.cardBorder),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text('Shop', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            ),
            _DrawerItem(icon: Icons.receipt_long_outlined, label: 'My Orders', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const TossOrdersScreen()));
            }),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Wallet', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            ),
            _DrawerItem(icon: Icons.token_outlined, label: 'Tokens', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => TokenListScreen(walletAddress: address)));
            }),
            _DrawerItem(icon: Icons.grid_view_outlined, label: 'NFTs', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => NftGridScreen(walletAddress: address)));
            }),
            _DrawerItem(icon: Icons.receipt_long_outlined, label: 'History', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionListScreen(walletAddress: address)));
            }),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text('Advanced', style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
            ),
            _DrawerItem(icon: Icons.link_outlined, label: 'WalletConnect', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WcScreen()));
            }),
            _DrawerItem(icon: Icons.key_outlined, label: 'HD Wallet', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HdWalletScreen()));
            }),
            _DrawerItem(icon: Icons.code_outlined, label: 'Contracts', onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MyContractsScreen()));
            }),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Sepolia Testnet', style: TextStyle(color: AppColors.textSecondary.withAlpha(120), fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
      title: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

// ─── Wallet Screen ────────────────────────────────────────────────────────────

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

  bool _privateKeyVisible = false;

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

    final ensAsync = ref.watch(ensResolveProvider(_toAddressController.text.trim()));
    final resolvedToAddress = ensAsync.valueOrNull ?? _toAddressController.text.trim();

    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _BalanceCard(
              balanceAsync: balanceAsync,
              ethPrice: ethPrice,
              address: submittedAddress,
            ),

            const SizedBox(height: 20),

            _AddressInputSection(
              controller: _addressController,
              address: address,
              onChanged: (value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 600), () {
                  final ensService = ref.read(ensServiceProvider);
                  if (ensService.isEnsName(value)) {
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
              onGetBalance: address.isEmpty
                  ? null
                  : () => ref.read(submittedAddressProvider.notifier).state = address,
            ),

            const SizedBox(height: 20),

            _SendSection(
              privateKeyController: _privateKeyController,
              toAddressController: _toAddressController,
              amountController: _amountController,
              privateKeyVisible: _privateKeyVisible,
              onToggleVisibility: () => setState(() => _privateKeyVisible = !_privateKeyVisible),
              ensAsync: ensAsync,
              gasAsync: gasAsync,
              amount: _amount,
              canSend: _canSend,
              isLoading: txState.isLoading,
              onChanged: () => setState(() {}),
              onMax: () async {
                final addr = ref.read(submittedAddressProvider);
                if (addr == null || addr.isEmpty || _toAddress.isEmpty) return;
                final max = await ref
                    .read(sendTxNotifierProvider.notifier)
                    .getMaxSend(address: addr, to: _toAddress);
                _amountController.text = (max > 0 ? max : 0).toStringAsFixed(6);
                setState(() {});
              },
              onSend: _canSend && !txState.isLoading
                  ? () => ref.read(sendTxNotifierProvider.notifier).send(
                        SendTxParams(
                          privateKey: _privateKey,
                          toAddress: resolvedToAddress,
                          amount: _amount,
                        ),
                      )
                  : null,
              onSimulate: () async {
                if (!_canSend) return;
                final web3 = ref.read(web3ServiceProvider);
                await web3.simulateTransaction(
                  privateKey: _privateKey,
                  toAddress: _toAddress,
                  amountInEth: _amount,
                );
              },
            ),

            const SizedBox(height: 16),

            txState.when(
              data: (hash) => hash == null
                  ? const SizedBox()
                  : _TxResultCard(hash: hash, success: true),
              loading: () => const SizedBox(),
              error: (e, _) => _TxResultCard(message: '$e', success: false),
            ),
          ],
        ),
      );
  }
}

// ─── Balance Card ─────────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final AsyncValue<double>? balanceAsync;
  final double? ethPrice;
  final String? address;

  const _BalanceCard({this.balanceAsync, this.ethPrice, this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.balanceGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('Ξ', style: TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Ethereum',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (balanceAsync == null)
            const Text(
              '—',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 40, fontWeight: FontWeight.w700),
            )
          else
            balanceAsync!.when(
              data: (bal) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${bal.toStringAsFixed(6)} ETH',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (ethPrice != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '≈ \$${(bal * ethPrice!).toStringAsFixed(2)} USD',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                    ),
                  ],
                ],
              ),
              loading: () => const SizedBox(
                height: 40,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
              ),
              error: (e, _) => Text(
                'Error loading balance',
                style: TextStyle(color: AppColors.error, fontSize: 14),
              ),
            ),
          if (address != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_circle_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    _shortAddress(address!),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => Clipboard.setData(ClipboardData(text: address!)),
                    child: const Icon(Icons.copy_outlined, size: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _shortAddress(String addr) {
    if (addr.length < 12) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }
}

// ─── Address Input Section ────────────────────────────────────────────────────

class _AddressInputSection extends StatelessWidget {
  final TextEditingController controller;
  final String address;
  final ValueChanged<String> onChanged;
  final VoidCallback? onGetBalance;

  const _AddressInputSection({
    required this.controller,
    required this.address,
    required this.onChanged,
    required this.onGetBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Your Wallet',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: const InputDecoration(
            hintText: 'Address or ENS (e.g. vitalik.eth)',
            prefixIcon: Icon(Icons.account_circle_outlined, size: 20),
          ),
          onChanged: onChanged,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 46,
          child: ElevatedButton.icon(
            onPressed: onGetBalance,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Refresh Balance'),
          ),
        ),
      ],
    );
  }
}

// ─── Send Section ─────────────────────────────────────────────────────────────

class _SendSection extends StatelessWidget {
  final TextEditingController privateKeyController;
  final TextEditingController toAddressController;
  final TextEditingController amountController;
  final bool privateKeyVisible;
  final VoidCallback onToggleVisibility;
  final AsyncValue<String?> ensAsync;
  final AsyncValue<double>? gasAsync;
  final double amount;
  final bool canSend;
  final bool isLoading;
  final VoidCallback onChanged;
  final VoidCallback onMax;
  final VoidCallback? onSend;
  final VoidCallback onSimulate;

  const _SendSection({
    required this.privateKeyController,
    required this.toAddressController,
    required this.amountController,
    required this.privateKeyVisible,
    required this.onToggleVisibility,
    required this.ensAsync,
    required this.gasAsync,
    required this.amount,
    required this.canSend,
    required this.isLoading,
    required this.onChanged,
    required this.onMax,
    required this.onSend,
    required this.onSimulate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Send ETH',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: privateKeyController,
            obscureText: !privateKeyVisible,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Private key (0x...)',
              prefixIcon: const Icon(Icons.lock_outline, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  privateKeyVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onPressed: onToggleVisibility,
              ),
            ),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: toAddressController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'To address or ENS',
              prefixIcon: const Icon(Icons.send_outlined, size: 20),
              suffixIcon: ensAsync.isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                    )
                  : ensAsync.valueOrNull != null
                      ? const Icon(Icons.check_circle_outline, color: AppColors.accent, size: 20)
                      : null,
              helperText: ensAsync.valueOrNull != null ? 'Resolved: ${ensAsync.valueOrNull}' : null,
              helperStyle: const TextStyle(color: AppColors.accent, fontSize: 11),
            ),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                  ],
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Amount (ETH)',
                    prefixIcon: Icon(Icons.monetization_on_outlined, size: 20),
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 50,
                child: OutlinedButton(
                  onPressed: onMax,
                  child: const Text('MAX', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),

          if (gasAsync != null) ...[
            const SizedBox(height: 10),
            gasAsync!.when(
              data: (fee) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Network fee', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    Text(
                      '${fee.toStringAsFixed(8)} ETH',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              loading: () => const Text(
                'Estimating fee...',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              error: (_, __) => const SizedBox(),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: onSend,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(isLoading ? 'Sending...' : 'Send ETH'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 46,
            child: OutlinedButton.icon(
              onPressed: canSend ? onSimulate : null,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Simulate'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TX Result Card ───────────────────────────────────────────────────────────

class _TxResultCard extends StatelessWidget {
  final String? hash;
  final String? message;
  final bool success;

  const _TxResultCard({this.hash, this.message, required this.success});

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.accent : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            success ? Icons.check_circle_outline : Icons.error_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  success ? 'Transaction sent!' : 'Transaction failed',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  hash ?? message ?? '',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
