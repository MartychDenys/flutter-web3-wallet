import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/price/price_provider.dart';
import 'package:flutter_web3_wallet/core/theme/app_theme.dart';
import 'package:flutter_web3_wallet/features/tokens/domain/token.dart';
import 'package:flutter_web3_wallet/features/tokens/presentation/token_provider.dart';
import 'token_transfer_screen.dart';

class TokenListScreen extends ConsumerStatefulWidget {
  final String walletAddress;

  const TokenListScreen({super.key, required this.walletAddress});

  @override
  ConsumerState<TokenListScreen> createState() => _TokenListScreenState();
}

class _TokenListScreenState extends ConsumerState<TokenListScreen> {
  final _customContractController = TextEditingController();

  @override
  void dispose() {
    _customContractController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokensAsync = ref.watch(walletTokensProvider(widget.walletAddress));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tokens'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () {
              ref.invalidate(walletTokensProvider(widget.walletAddress));
              ref.invalidate(tokenPricesProvider(['ETH', 'USDC', 'LINK', 'WETH']));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _AddCustomToken(walletAddress: widget.walletAddress),
          Expanded(
            child: tokensAsync.when(
              data: (tokens) {
                if (tokens.isEmpty) return const _EmptyTokens();

                final symbols = tokens.map((t) => t.symbol.toUpperCase()).toList();
                final pricesAsync = ref.watch(tokenPricesProvider(symbols));
                final prices = pricesAsync.valueOrNull ?? {};

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: tokens.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _TokenTile(
                    token: tokens[i],
                    walletAddress: widget.walletAddress,
                    usdPrice: prices[tokens[i].symbol.toUpperCase()],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('$e', style: const TextStyle(color: AppColors.error), textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTokens extends StatelessWidget {
  const _EmptyTokens();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: const Icon(Icons.token_outlined, size: 36, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tokens found',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter a wallet address to see ERC20 tokens',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _TokenTile extends StatelessWidget {
  final Token token;
  final String walletAddress;
  final double? usdPrice;

  const _TokenTile({
    required this.token,
    required this.walletAddress,
    this.usdPrice,
  });

  @override
  Widget build(BuildContext context) {
    final usdValue = usdPrice != null ? token.balance * usdPrice! : null;
    final symbol = token.symbol.length > 4 ? token.symbol.substring(0, 4) : token.symbol;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TokenTransferScreen(token: token, walletAddress: walletAddress),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    token.symbol,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    usdPrice != null
                        ? '\$${usdPrice!.toStringAsFixed(2)} per token'
                        : token.name,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  token.balance.toStringAsFixed(4),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (usdValue != null)
                  Text(
                    '\$${usdValue.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                else
                  Text(
                    token.symbol,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCustomToken extends ConsumerStatefulWidget {
  final String walletAddress;

  const _AddCustomToken({required this.walletAddress});

  @override
  ConsumerState<_AddCustomToken> createState() => _AddCustomTokenState();
}

class _AddCustomTokenState extends ConsumerState<_AddCustomToken> {
  final _controller = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add, size: 18, color: AppColors.primary),
            ),
            title: const Text(
              'Add custom token',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            trailing: Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onTap: () => setState(() => _expanded = !_expanded),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Contract address (0x...)',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton(
                      onPressed: () {
                        final addr = _controller.text.trim();
                        if (addr.isEmpty) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _CustomTokenScreen(
                              contractAddress: addr,
                              walletAddress: widget.walletAddress,
                            ),
                          ),
                        );
                      },
                      child: const Text('Load', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CustomTokenScreen extends ConsumerWidget {
  final String contractAddress;
  final String walletAddress;

  const _CustomTokenScreen({
    required this.contractAddress,
    required this.walletAddress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenAsync = ref.watch(tokenInfoProvider(
      TokenInfoParams(
        contractAddress: contractAddress,
        walletAddress: walletAddress,
      ),
    ));

    return Scaffold(
      appBar: AppBar(title: const Text('Token Info'), centerTitle: true),
      body: tokenAsync.when(
        data: (Token token) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(label: 'Name', value: token.name),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'Symbol', value: token.symbol),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'Decimals', value: '${token.decimals}'),
                    const SizedBox(height: 12),
                    _InfoRow(label: 'Balance', value: '${token.balance.toStringAsFixed(6)} ${token.symbol}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TokenTransferScreen(
                          token: token,
                          walletAddress: walletAddress,
                        ),
                      ),
                    );
                  },
                  child: const Text('Transfer Token'),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error loading token: $e', style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
