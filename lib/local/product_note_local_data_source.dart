import 'package:drift/drift.dart';

import '../models/product_note.dart';
import 'app_database.dart';

class ProductNoteLocalDataSource {
  final AppDatabase db;

  ProductNoteLocalDataSource(this.db);

  ProductNote _toDomain(ProductNoteRow row) => ProductNote(
    productId: row.productId,
    note: row.note,
    priority: row.priority,
    updatedAt: row.updatedAt,
    pendingSync: row.pendingSync,
  );

  Future<ProductNote?> getNote(int productId) async {
    final row = await (db.select(
      db.productNotes,
    )..where((table) => table.productId.equals(productId))).getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  Stream<ProductNote?> watchNote(int productId) {
    return (db.select(db.productNotes)
          ..where((table) => table.productId.equals(productId)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _toDomain(row));
  }

  Future<void> saveNote(ProductNote note) async {
    await db
        .into(db.productNotes)
        .insertOnConflictUpdate(
          ProductNotesCompanion.insert(
            productId: Value(note.productId),
            note: Value(note.note),
            priority: note.priority,
            updatedAt: note.updatedAt,
            pendingSync: const Value(true),
          ),
        );
  }

  Future<List<ProductNote>> getPendingNotes() async {
    final rows = await (db.select(
      db.productNotes,
    )..where((table) => table.pendingSync.equals(true))).get();
    return rows.map(_toDomain).toList();
  }

  Future<void> markSynced(ProductNote sent) async {
    await (db.update(db.productNotes)..where(
          (table) =>
              table.productId.equals(sent.productId) &
              table.updatedAt.equals(sent.updatedAt) &
              table.note.equals(sent.note) &
              table.priority.equals(sent.priority),
        ))
        .write(const ProductNotesCompanion(pendingSync: Value(false)));
  }
}
