import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import 'stock_history_screen.dart';

class StockViewScreen extends StatefulWidget {
  const StockViewScreen({super.key});

  @override
  State<StockViewScreen> createState() => _StockViewScreenState();
}

class _StockViewScreenState extends State<StockViewScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Management'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const StockHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              context.read<ProductProvider>().syncWithServer();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (productProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          productProvider.error!,
                          style: TextStyle(color: Colors.red[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => productProvider.loadProducts(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final products = productProvider.filteredProducts;

                if (products.isEmpty) {
                  return const Center(child: Text('No products found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return _buildProductCard(product);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        context.read<ProductProvider>().searchProducts('');
                      },
                    )
                  : null,
            ),
            onChanged: (value) {
              context.read<ProductProvider>().searchProducts(value);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: context.read<ProductProvider>().categories.map((
                    category,
                  ) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                    context.read<ProductProvider>().filterByCategory(value!);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  decoration: const InputDecoration(
                    labelText: 'Sort by',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Name')),
                    DropdownMenuItem(value: 'stock', child: Text('Stock')),
                    DropdownMenuItem(
                      value: 'category',
                      child: Text('Category'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                    context.read<ProductProvider>().sortProducts(value!);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isLowStock = product.availableStock < 10;
    final isOutOfStock = product.availableStock == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.image, size: 30),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        product.category,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      Text(
                        product.formattedPrice,
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${product.availableStock} ${product.unit}',
                      style: TextStyle(
                        color: isOutOfStock
                            ? Colors.red[700]
                            : isLowStock
                            ? Colors.orange[700]
                            : Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),

                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: 28,
                          child: TextButton(
                            onPressed: () => _showStockHistory(product),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue[700],
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              side: BorderSide(color: Colors.blue[700]!),
                            ),
                            child: Text('History'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 28,
                          child: TextButton(
                            onPressed: () => _showUpdateStockDialog(product),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.green[700],
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              side: BorderSide(color: Colors.green[700]!),
                            ),
                            child: Text('Update'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStockDialog(Product product) {
    final TextEditingController stockController = TextEditingController(
      text: product.availableStock.toString(),
    );
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock - ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'New Stock (${product.unit})',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStock = int.tryParse(stockController.text);
              if (newStock == null || newStock < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid stock amount'),
                  ),
                );
                return;
              }

              final success = await context
                  .read<ProductProvider>()
                  .updateProductStock(
                    productId: product.id,
                    newStock: newStock,
                    updatedBy:
                        'Ops Manager', // In real app, get from user session of ops manager
                    notes: notesController.text.isNotEmpty
                        ? notesController.text
                        : null,
                  );

              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Stock updated successfully to $newStock ${product.unit}',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to update stock'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showStockHistory(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StockHistoryScreen(
          productId: product.id,
          productName: product.name,
        ),
      ),
    );
  }
}
