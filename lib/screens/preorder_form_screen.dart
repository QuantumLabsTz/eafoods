import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';
import '../models/product.dart';
import '../services/order_service.dart';

class PreOrderFormScreen extends StatefulWidget {
  const PreOrderFormScreen({super.key});

  @override
  State<PreOrderFormScreen> createState() => _PreOrderFormScreenState();
}

class _PreOrderFormScreenState extends State<PreOrderFormScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _customerPhoneController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final PageController _pageController = PageController();
  int _currentPage = 0;

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
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Place Pre-Order'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          Consumer<OrderProvider>(
            builder: (context, orderProvider, child) {
              if (orderProvider.cartItems.isNotEmpty) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () => _pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${orderProvider.cartItems.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildProductSelectionPage(),
                _buildOrderSummaryPage(),
                _buildCustomerDetailsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildProgressStep(0, 'Products', Icons.shopping_basket),
          Expanded(child: _buildProgressLine(0)),
          _buildProgressStep(1, 'Cart', Icons.shopping_cart),
          Expanded(child: _buildProgressLine(1)),
          _buildProgressStep(2, 'Details', Icons.person),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String title, IconData icon) {
    final isActive = _currentPage >= step;
    final isCompleted = _currentPage > step;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue[700] : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isActive ? Colors.white : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue[700] : Colors.grey[600],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(int step) {
    final isActive = _currentPage > step;
    return Container(
      height: 2,
      color: isActive ? Colors.blue[700] : Colors.grey[300],
    );
  }

  Widget _buildProductSelectionPage() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              if (productProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (productProvider.error != null) {
                return Center(
                  child: Text(
                    productProvider.error!,
                    style: TextStyle(color: Colors.red[600]),
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
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
    );
  }

  Widget _buildProductCard(Product product) {
    final isOutOfStock = product.availableStock == 0;
    final isLowStock = product.availableStock < 10;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
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
                  if (isOutOfStock)
                    Text(
                      'Out of Stock',
                      style: TextStyle(
                        color: Colors.red[600],
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else if (isLowStock)
                    Text(
                      'Low Stock: ${product.availableStock} ${product.unit}',
                      style: TextStyle(
                        color: Colors.orange[600],
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Text(
                      'In Stock: ${product.availableStock} ${product.unit}',
                      style: TextStyle(
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            if (!isOutOfStock)
              ElevatedButton(
                onPressed: () => _showQuantityDialog(product),
                child: const Text('Add'),
              ),
          ],
        ),
      ),
    );
  }

  void _showQuantityDialog(Product product) {
    final TextEditingController quantityController = TextEditingController(
      text: '1',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Available: ${product.availableStock} ${product.unit}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text);
              if (quantity != null &&
                  quantity > 0 &&
                  quantity <= product.availableStock) {
                context.read<OrderProvider>().addToCart(product, quantity);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Added $quantity ${product.unit} of ${product.name} to cart',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid quantity'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryPage() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.cartItems.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text('Your cart is empty'),
                SizedBox(height: 8),
                Text('Add some products to continue'),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orderProvider.cartItems.length,
                itemBuilder: (context, index) {
                  final item = orderProvider.cartItems[index];
                  return _buildCartItemCard(item);
                },
              ),
            ),
            _buildCartSummary(),
          ],
        );
      },
    );
  }

  Widget _buildCartItemCard(item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${item.price.toStringAsFixed(2)} TZS per ${item.unit}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    context.read<OrderProvider>().updateCartItemQuantity(
                      item.productId,
                      item.quantity - 1,
                    );
                  },
                  icon: const Icon(Icons.remove),
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    context.read<OrderProvider>().updateCartItemQuantity(
                      item.productId,
                      item.quantity + 1,
                    );
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Text(
              '${item.totalPrice.toStringAsFixed(2)} TZS',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            IconButton(
              onPressed: () {
                context.read<OrderProvider>().removeFromCart(item.productId);
              },
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSummary() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    orderProvider.formattedCartTotal,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _pageController.animateToPage(
                      2,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: const Text('Continue to Details'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCustomerDetailsPage() {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customer Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _customerNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  orderProvider.setCustomerName(value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _customerPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                onChanged: (value) {
                  orderProvider.setCustomerPhone(value);
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Delivery Slot',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (orderProvider.selectedDeliverySlot != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Selected: ${orderProvider.selectedDeliverySlot!.name} (${orderProvider.selectedDeliverySlot!.timeRange})',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              ...orderProvider.availableDeliverySlots.map((slot) {
                final isSelected =
                    orderProvider.selectedDeliverySlot?.id == slot.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isSelected ? Colors.blue[50] : null,
                  child: RadioListTile<String>(
                    title: Text(
                      slot.name,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.blue[700] : null,
                      ),
                    ),
                    subtitle: Text(slot.timeRange),
                    value: slot.id,
                    groupValue: orderProvider.selectedDeliverySlot?.id,
                    onChanged: (value) {
                      if (value != null) {
                        final selectedSlot = orderProvider
                            .availableDeliverySlots
                            .firstWhere((s) => s.id == value);
                        orderProvider.setDeliverySlot(selectedSlot);
                      }
                    },
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),
              const Text(
                'Additional Notes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) {
                  orderProvider.setNotes(value);
                },
              ),
              const SizedBox(height: 24),
              _buildCutoffWarning(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: orderProvider.canPlaceOrder
                      ? () => _placeOrder()
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: orderProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Place Order',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCutoffWarning() {
    final isAfterCutoff = OrderService.isAfterCutoff();

    if (isAfterCutoff) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          border: Border.all(color: Colors.orange[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Orders placed after 6:00 PM will be delivered in 2 days instead of next day.',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _placeOrder() async {
    final orderProvider = context.read<OrderProvider>();
    final result = await orderProvider.placeOrder();

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Order placed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset the form to step 1 for next order
      _currentPage = 0;
      _searchController.clear();
      _customerNameController.clear();
      _customerPhoneController.clear();
      _notesController.clear();
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errors.join(', ')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
