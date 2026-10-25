import 'package:flutter/material.dart';

import 'models/product.dart';
import 'product_card.dart';
import 'product_detail.dart';
import 'repositories/product_note_repository.dart';
import 'services/product_service.dart';
import 'widgets/empty_view.dart';
import 'widgets/error_view.dart';
import 'widgets/loading_view.dart';

class ProductScreen extends StatefulWidget {
  final ProductNoteRepository noteRepository;

  const ProductScreen({super.key, required this.noteRepository});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final ProductService _service = ProductService();
  late Future<List<Product>> _productsFuture;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _productsFuture = _service.getProducts();
  }

  void _retryCatalog() {
    setState(() => _productsFuture = _service.getProducts());
  }

  Future<void> _syncPending() async {
    setState(() => _syncing = true);
    try {
      await widget.noteRepository.syncPending();
      final pending = await widget.noteRepository.pendingCount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pending == 0
                ? 'Todo sincronizado'
                : '$pending pendientes; reintenta con conexión',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudieron sincronizar los cambios: $error'),
        ),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _openProduct(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailPage(
          product: product,
          noteRepository: widget.noteRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de productos'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.tonalIcon(
              onPressed: _syncing ? null : _syncPending,
              icon: _syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: const Text('Sincronizar pendientes'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Product>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
            if (snapshot.hasError) {
              return ErrorView(
                message: snapshot.error.toString(),
                onRetry: _retryCatalog,
              );
            }

            final products = snapshot.data ?? const <Product>[];
            if (products.isEmpty) return const EmptyView();

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap: () => _openProduct(product),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
