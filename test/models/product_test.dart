import 'package:flutter_test/flutter_test.dart';
import 'package:eafoods/models/product.dart';

void main() {
  group('Product Model Tests', () {
    late Product testProduct;

    setUp(() {
      testProduct = Product(
        id: '1',
        name: 'Test Product',
        description: 'A test product',
        price: 10.50,
        stockQuantity: 100,
        category: 'Test Category',
        imageUrl: 'https://example.com/image.jpg',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
    });

    test('should create product with correct properties', () {
      expect(testProduct.id, '1');
      expect(testProduct.name, 'Test Product');
      expect(testProduct.description, 'A test product');
      expect(testProduct.price, 10.50);
      expect(testProduct.stockQuantity, 100);
      expect(testProduct.category, 'Test Category');
      expect(testProduct.imageUrl, 'https://example.com/image.jpg');
    });

    test('should calculate available stock correctly', () {
      expect(testProduct.availableStock, 100);
    });

    test('should format price correctly', () {
      expect(testProduct.formattedPrice, 'TZS 10.50');
    });

    test('should return correct unit', () {
      expect(testProduct.unit, 'pieces');
    });

    test('should create copy with updated values', () {
      final updatedProduct = testProduct.copyWith(
        name: 'Updated Product',
        price: 15.75,
        stockQuantity: 50,
      );

      expect(updatedProduct.name, 'Updated Product');
      expect(updatedProduct.price, 15.75);
      expect(updatedProduct.stockQuantity, 50);
      expect(updatedProduct.id, '1'); // Should remain unchanged
      expect(updatedProduct.description, 'A test product'); // Should remain unchanged
    });

    test('should convert to JSON correctly', () {
      final json = testProduct.toJson();
      
      expect(json['id'], '1');
      expect(json['name'], 'Test Product');
      expect(json['price'], 10.50);
      expect(json['stockQuantity'], 100);
      expect(json['createdAt'], testProduct.createdAt.toIso8601String());
    });

    test('should create from JSON correctly', () {
      final json = {
        'id': '2',
        'name': 'JSON Product',
        'description': 'Product from JSON',
        'price': 25.00,
        'stockQuantity': 75,
        'category': 'JSON Category',
        'imageUrl': 'https://example.com/json.jpg',
        'createdAt': DateTime(2024, 2, 1).toIso8601String(),
        'updatedAt': DateTime(2024, 2, 1).toIso8601String(),
      };

      final product = Product.fromJson(json);

      expect(product.id, '2');
      expect(product.name, 'JSON Product');
      expect(product.price, 25.00);
      expect(product.stockQuantity, 75);
      expect(product.category, 'JSON Category');
    });

    test('should handle null imageUrl', () {
      final productWithoutImage = testProduct.copyWith(imageUrl: null);
      expect(productWithoutImage.imageUrl, 'https://example.com/image.jpg'); // copyWith doesn't override with null
    });

    test('should handle empty stock', () {
      final outOfStockProduct = testProduct.copyWith(stockQuantity: 0);
      expect(outOfStockProduct.availableStock, 0);
    });
  });
}
