import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Orders'),
            Tab(text: 'Pending'),
            Tab(text: 'Offline'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              context.read<OrderProvider>().syncPendingOrders();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOrdersList(context.read<OrderProvider>().orders),
          _buildOrdersList(context.read<OrderProvider>().pendingOrders),
          _buildOrdersList(context.read<OrderProvider>().offlineOrders),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    return Consumer<OrderProvider>(
      builder: (context, orderProvider, child) {
        if (orderProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (orderProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  orderProvider.error!,
                  style: TextStyle(color: Colors.red[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => orderProvider.loadOrders(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (orders.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No orders found'),
                SizedBox(height: 8),
                Text('Your orders will appear here'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => orderProvider.loadOrders(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return _buildOrderCard(order);
            },
          ),
        );
      },
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  order.customerName,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  order.customerPhone,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Delivery: ${_formatDate(order.deliveryDate)}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  order.deliverySlot.timeRange,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Items:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.productName} (${item.quantity} ${item.unit})',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            '${item.totalPrice.toStringAsFixed(2)} TZS',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${order.formattedTotalAmount}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (order.isOffline)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 14,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Offline',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (order.notes != null && order.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.notes!,
                        style: TextStyle(color: Colors.blue[700], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showOrderDetails(order),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[700],
                      side: BorderSide(color: Colors.blue[700]!),
                    ),
                  ),
                ),
                if (order.canBeCancelled) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(order),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        side: BorderSide(color: Colors.red[700]!),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    String text;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        text = 'Confirmed';
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
      case OrderStatus.delivered:
        color = Colors.green;
        text = 'Delivered';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Details #${order.id.substring(0, 8)}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Customer', order.customerName),
              _buildDetailRow('Phone', order.customerPhone),
              _buildDetailRow('Order Date', _formatDate(order.orderDate)),
              _buildDetailRow('Delivery Date', _formatDate(order.deliveryDate)),
              _buildDetailRow('Delivery Slot', order.deliverySlot.timeRange),
              _buildDetailRow('Status', _getStatusText(order.status)),
              _buildDetailRow('Total', order.formattedTotalAmount),
              if (order.notes != null && order.notes!.isNotEmpty)
                _buildDetailRow('Notes', order.notes!),
              const SizedBox(height: 16),
              const Text(
                'Items:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...order.items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${item.productName} - ${item.quantity} ${item.unit} - ${item.totalPrice.toStringAsFixed(2)} TZS',
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.delivered:
        return 'Delivered';
    }
  }

  void _showCancelDialog(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text(
          'Are you sure you want to cancel order #${order.id.substring(0, 8)}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await context.read<OrderProvider>().cancelOrder(
                order.id,
              );

              if (result.success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.message ?? 'Order cancelled successfully',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.errors.join(', ')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
