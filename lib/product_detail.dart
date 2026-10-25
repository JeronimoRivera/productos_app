import 'package:flutter/material.dart';

import 'models/product.dart';
import 'models/product_note.dart';
import 'repositories/product_note_repository.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final ProductNoteRepository noteRepository;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.noteRepository,
  });

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final TextEditingController _noteController = TextEditingController();
  int _priority = 3;
  bool _saving = false;
  bool _fieldsInitialized = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _initializeFields(ProductNote note) {
    if (_fieldsInitialized) return;
    _fieldsInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _noteController.text = note.note;
        _priority = note.priority.clamp(1, 5);
      });
    });
  }

  Future<void> _saveNote() async {
    // La UI valida antes de llamar al repositorio; este vuelve a validar.
    if (_priority < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La prioridad debe ser 2 o mayor para guardar'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.noteRepository.saveNote(
        ProductNote(
          productId: widget.product.id,
          note: _noteController.text.trim(),
          priority: _priority,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardado en este dispositivo')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildSyncStatus(AsyncSnapshot<ProductNote?> snapshot) {
    if (snapshot.hasError) {
      return const Chip(label: Text('No se pudo leer el estado local'));
    }
    if (!snapshot.hasData || snapshot.data == null) {
      return const Chip(label: Text('No hay información guardada'));
    }
    final note = snapshot.data!;
    _initializeFields(note);
    return Chip(
      avatar: Icon(
        note.pendingSync
            ? Icons.cloud_upload_outlined
            : Icons.cloud_done_outlined,
        size: 18,
      ),
      label: Text(note.pendingSync ? 'Pendiente' : 'Sincronizado'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del producto')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 240,
                        width: double.infinity,
                        child: Image.network(
                          widget.product.image,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              ColoredBox(
                                color: colors.surfaceContainerHighest,
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 56,
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.product.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.category,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${widget.product.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  StreamBuilder<ProductNote?>(
                    stream: widget.noteRepository.watchNote(widget.product.id),
                    builder: (context, snapshot) => _buildSyncStatus(snapshot),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _noteController,
                    enabled: !_saving,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: 'Nota personal',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Prioridad: $_priority / 5'),
                  Slider(
                    value: _priority.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: '$_priority',
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _priority = value.round()),
                  ),
                  FilledButton.icon(
                    onPressed: _saving ? null : _saveNote,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Guardando…' : 'Guardar nota'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
