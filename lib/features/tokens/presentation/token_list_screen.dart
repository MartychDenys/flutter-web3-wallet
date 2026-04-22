import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web3_wallet/core/price/price_provider.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
                final symbols = tokens.map((t) => t.symbol.toUpperCase()).toList();
                final pricesAsync = ref.watch(tokenPricesProvider(symbols));
                final prices = pricesAsync.valueOrNull ?? {};

                return tokens.isEmpty
                    ? const Center(child: Text('No tokens found'))
                    : ListView.builder(
                        itemCount: tokens.length,
                        itemBuilder: (context, i) => _TokenTile(
                          token: tokens[i],
                          walletAddress: widget.walletAddress,
                          usdPrice: prices[tokens[i].symbol.toUpperCase()],
                        ),
                      );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
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

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.indigo.shade100,
        child: Text(
          token.symbol.length > 2 ? token.symbol.substring(0, 2) : token.symbol,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
      title: Text(token.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: usdPrice != null
          ? Text('\$${usdPrice!.toStringAsFixed(2)} per token',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
          : Text(token.name),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            token.balance.toStringAsFixed(4),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          if (usdValue != null)
            Text(
              '\$${usdValue.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w500),
            )
          else
            Text(
              token.symbol,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TokenTransferScreen(
              token: token,
              walletAddress: walletAddress,
            ),
          ),
        );
      },
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
    return Card(
      margin: const EdgeInsets.all(12),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add custom token'),
            trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
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
                      decoration: const InputDecoration(
                        labelText: 'Contract address (0x...)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
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
                    child: const Text('Load'),
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
      appBar: AppBar(title: const Text('Token Info')),
      body: tokenAsync.when(
        data: (Token token) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${token.name}', style: const TextStyle(fontSize: 18)),
              Text('Symbol: ${token.symbol}'),
              Text('Decimals: ${token.decimals}'),
              Text('Balance: ${token.balance.toStringAsFixed(6)} ${token.symbol}'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
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
                  child: const Text('Transfer'),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading token: $e')),
      ),
    );
  }
}
