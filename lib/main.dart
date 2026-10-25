import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'local/app_database.dart';
import 'local/product_note_local_data_source.dart';
import 'product_screen.dart';
import 'remote/product_note_remote_data_source.dart';
import 'repositories/product_note_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ProductNoteRemoteDataSource? remote;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    remote = ProductNoteRemoteDataSource(FirebaseFirestore.instance);
  } catch (error) {
    debugPrint('Firebase no disponible; se usarán notas locales: $error');
  }

  final database = AppDatabase();
  final repository = ProductNoteRepository(
    local: ProductNoteLocalDataSource(database),
    remote: remote,
  );
  runApp(ProductosApp(noteRepository: repository));
}

class ProductosApp extends StatelessWidget {
  final ProductNoteRepository noteRepository;

  const ProductosApp({super.key, required this.noteRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Productos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: ProductScreen(noteRepository: noteRepository),
    );
  }
}
