import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/app_logger.dart';
import '../models/product.dart';

class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}

class ProductService {
  static const String _catalogUrl = 'https://dummyjson.com/products?limit=30';
  final String baseUrl;

  ProductService({this.baseUrl = _catalogUrl});

  Future<List<Product>> getProducts() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        if (response.statusCode == 404) {
          throw const ApiException('No se encontró el catálogo de productos');
        }
        if (response.statusCode == 500) {
          throw const ApiException(
            'El servidor de productos no está disponible',
          );
        }
        throw ApiException('Error HTTP ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['products'] is! List) {
        throw const FormatException(
          'La respuesta no contiene una lista products',
        );
      }
      final products = (decoded['products'] as List)
          .map(
            (item) => Product.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();

      AppLogger.debug('Productos cargados: ${products.length}');
      return products;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder');
    } on SocketException {
      throw const ApiException('Sin conexión a Internet');
    } on http.ClientException {
      throw const ApiException('Falló la petición al catálogo de productos');
    } on FormatException {
      throw const ApiException('El servidor devolvió JSON inválido');
    } on TypeError {
      throw const ApiException(
        'El catálogo contiene datos con formato inválido',
      );
    } catch (error) {
      throw ApiException('No se pudo cargar el catálogo: $error');
    }
  }
}
