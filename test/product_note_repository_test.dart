import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:productos_app/local/app_database.dart';
import 'package:productos_app/local/product_note_local_data_source.dart';
import 'package:productos_app/models/product_note.dart';
import 'package:productos_app/remote/product_note_remote_data_source.dart';
import 'package:productos_app/repositories/product_note_repository.dart';

class FakeRemote implements ProductNoteRemoteDataSource {
  bool fails = false;
  Completer<void>? gate;
  final List<ProductNote> sent = [];

  @override
  Future<void> upsertNote(ProductNote note) async {
    if (fails) throw StateError('Fallo remoto');
    await gate?.future;
    sent.add(note);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProductNote note(int productId, {String text = '', int priority = 3}) {
  return ProductNote(
    productId: productId,
    note: text,
    priority: priority,
    updatedAt: DateTime.utc(2026, 10, 24),
  );
}

void main() {
  late AppDatabase database;
  late ProductNoteLocalDataSource local;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    local = ProductNoteLocalDataSource(database);
  });

  tearDown(() => database.close());

  test('guardar el mismo producto actualiza una única fila', () async {
    final repository = ProductNoteRepository(local: local);
    await repository.saveNote(note(1, text: 'Primera'));
    await repository.saveNote(note(1, text: 'Editada'));

    final saved = await repository.getNote(1);
    expect(saved?.note, 'Editada');
    expect(await database.select(database.productNotes).get(), hasLength(1));
  });

  test(
    'guarda local y confirma pendingSync cuando el remoto funciona',
    () async {
      final remote = FakeRemote()..gate = Completer<void>();
      final repository = ProductNoteRepository(local: local, remote: remote);
      await repository.saveNote(note(2, text: 'Local primero'));

      expect((await repository.getNote(2))?.pendingSync, isTrue);
      remote.gate!.complete();
      await repository.syncPending();

      expect(remote.sent.map((item) => item.productId), contains(2));
      expect((await repository.getNote(2))?.pendingSync, isFalse);
    },
  );

  test('un fallo remoto conserva la nota local pendiente', () async {
    final remote = FakeRemote()..fails = true;
    final repository = ProductNoteRepository(local: local, remote: remote);
    await repository.saveNote(note(3, text: 'Sin conexión'));
    await repository.syncPending();

    expect((await repository.getNote(3))?.note, 'Sin conexión');
    expect((await repository.getNote(3))?.pendingSync, isTrue);
  });

  test('syncPending solo envía las notas pendientes', () async {
    final first = note(4, text: 'Ya sincronizada');
    await local.saveNote(first);
    await local.markSynced(first);
    await local.saveNote(note(5, text: 'Pendiente'));

    final remote = FakeRemote();
    final repository = ProductNoteRepository(local: local, remote: remote);
    await repository.syncPending();

    expect(remote.sent.map((item) => item.productId), [5]);
    expect(await repository.pendingCount(), 0);
  });

  test('prioridad inferior a dos no se guarda', () async {
    final repository = ProductNoteRepository(local: local);

    await expectLater(
      repository.saveNote(note(6, priority: 1)),
      throwsA(isA<InvalidPriorityException>()),
    );
    expect(await repository.getNote(6), isNull);
  });
}
