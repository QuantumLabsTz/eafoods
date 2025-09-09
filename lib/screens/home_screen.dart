import 'package:eafoods/constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';
import 'stock_view_screen.dart';
import 'preorder_form_screen.dart';
import 'my_orders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const StockViewScreen(),
    const PreOrderFormScreen(),
    const MyOrdersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: kbgcolor,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stock'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Pre-Order',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'My Orders',
          ),
        ],
        selectedItemColor: kprimarycolor,
        unselectedItemColor: Colors.grey[500],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pre-Order System'),

        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              context.read<ProductProvider>().syncWithServer();
              context.read<OrderProvider>().syncPendingOrders();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildQuickStats(context),
            const SizedBox(height: 24),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            _buildRecentActivity(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, size: 32, color: Colors.blue[700]),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Welcome to EA Foods',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Pre-Order System for East Africa\'s leading food distribution company. Place your orders in advance for next-day delivery.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Orders placed after 6:00 PM will be delivered in 2 days',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Consumer2<ProductProvider, OrderProvider>(
      builder: (context, productProvider, orderProvider, child) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Products',
                '${productProvider.products.length}',
                Icons.inventory,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Low Stock',
                '${productProvider.lowStockProducts.length}',
                Icons.warning,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Pending Orders',
                '${orderProvider.pendingOrders.length}',
                Icons.pending,
                Colors.purple,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Update Stock',
                'Manage inventory levels',
                Icons.inventory_2,
                Colors.green,
                () {
                  // Navigate to stock view
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StockViewScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Place Order',
                'Create new pre-order',
                Icons.shopping_cart,
                Colors.blue,
                () {
                  // Navigate to pre-order form
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PreOrderFormScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'View Orders',
                'Check order status',
                Icons.list_alt,
                Colors.purple,
                () {
                  // Navigate to my orders
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyOrdersScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Sync Data',
                'Update from server',
                Icons.sync,
                Colors.orange,
                () {
                  // Sync data
                  context.read<ProductProvider>().syncWithServer();
                  context.read<OrderProvider>().syncPendingOrders();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Syncing data...'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildActivityItem(
                  Icons.shopping_cart,
                  'New order placed',
                  'Order #12345 for delivery tomorrow',
                  '2 hours ago',
                  Colors.green,
                ),
                const Divider(),
                _buildActivityItem(
                  Icons.inventory,
                  'Stock updated',
                  'Tomatoes stock updated to 50 kg',
                  '4 hours ago',
                  Colors.blue,
                ),
                const Divider(),
                _buildActivityItem(
                  Icons.warning,
                  'Low stock alert',
                  'Onions running low (5 kg remaining)',
                  '6 hours ago',
                  Colors.orange,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    IconData icon,
    String title,
    String subtitle,
    String time,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}
