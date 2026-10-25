import 'dart:async';

import '../local/product_note_local_data_source.dart';
import '../models/product_note.dart';
import '../remote/product_note_remote_data_source.dart';

class InvalidPriorityException implements Exception {
  final int priority;

  const InvalidPriorityException(this.priority);

  @override
  String toString() =>
      'La prioridad debe estar entre 2 y 5 (recibida: $priority)';
}

class ProductNoteRepository {
  final ProductNoteLocalDataSource local;
  final ProductNoteRemoteDataSource? remote;
  final Duration syncTimeout;
  Future<void>? _syncInProgress;

  ProductNoteRepository({
    required this.local,
    this.remote,
    this.syncTimeout = const Duration(seconds: 10),
  });

  Future<ProductNote?> getNote(int productId) => local.getNote(productId);

  Stream<ProductNote?> watchNote(int productId) => local.watchNote(productId);

  Future<void> saveNote(ProductNote note) async {
    if (note.priority < 2 || note.priority > 5) {
      throw InvalidPriorityException(note.priority);
    }
    // La persistencia local termina antes de iniciar cualquier trabajo remoto.
    await local.saveNote(note);
    unawaited(_syncAfterSave());
  }

  Future<void> _syncAfterSave() async {
    try {
      final activeSync = _syncInProgress;
      if (activeSync != null) await activeSync;
      await syncPending();
    } catch (_) {
      // El dato local permanece guardado y puede reintentarse desde la lista.
    }
  }

  Future<void> syncPending() {
    return _syncInProgress ??= _syncPending().whenComplete(() {
      _syncInProgress = null;
    });
  }

  Future<void> _syncPending() async {
    final remoteSource = remote;
    if (remoteSource == null) return;

    final pendingNotes = await local.getPendingNotes();
    for (final note in pendingNotes) {
      try {
        await remoteSource.upsertNote(note).timeout(syncTimeout);
        await local.markSynced(note);
      } catch (_) {
        // Un fallo no cancela el envío de los demás pendientes.
      }
    }
  }

  Future<int> pendingCount() async => (await local.getPendingNotes()).length;
}
