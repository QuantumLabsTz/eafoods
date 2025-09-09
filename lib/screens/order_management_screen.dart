import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../models/order.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Order Management'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Confirmed'),
            Tab(text: 'Offline'),
            Tab(text: 'All Orders'),
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
          _buildOrdersList(_getPendingOrders()),
          _buildOrdersList(_getConfirmedOrders()),
          _buildOrdersList(_getOfflineOrders()),
          _buildOrdersList(_getAllOrders()),
        ],
      ),
    );
  }

  List<Order> _getPendingOrders() {
    return context
        .read<OrderProvider>()
        .orders
        .where((order) => order.status == OrderStatus.pending)
        .toList();
  }

  List<Order> _getConfirmedOrders() {
    return context
        .read<OrderProvider>()
        .orders
        .where((order) => order.status == OrderStatus.confirmed)
        .toList();
  }

  List<Order> _getOfflineOrders() {
    return context
        .read<OrderProvider>()
        .orders
        .where((order) => order.isOffline)
        .toList();
  }

  List<Order> _getAllOrders() {
    return context.read<OrderProvider>().orders;
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No orders found'),
                const SizedBox(height: 8),
                const Text('Orders will appear here based on their status'),
                const SizedBox(height: 16),
                // Debug info
                Text(
                  'Total orders: ${orderProvider.orders.length}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  'Pending: ${orderProvider.orders.where((o) => o.status == OrderStatus.pending).length}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  'Offline: ${orderProvider.orders.where((o) => o.isOffline).length}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
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
            // Debug info
            Text(
              'Status: ${order.status.name} | Sync: ${order.syncStatus.name}',
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.shopping_cart, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${order.items.length} items',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Spacer(),
                Text(
                  order.formattedTotalAmount,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (order.isOffline) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 14, color: Colors.orange[700]),
                    const SizedBox(width: 4),
                    Text(
                      'Offline - ${order.syncStatus.name}',
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
            const SizedBox(height: 12),
            _buildActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Order order) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showOrderDetails(order),
            icon: const Icon(Icons.visibility, size: 16),
            label: const Text('View'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[700],
              side: BorderSide(color: Colors.blue[700]!),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (order.status == OrderStatus.pending) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _confirmOrder(order),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Confirm'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
        if (order.status == OrderStatus.confirmed) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _markAsDelivered(order),
              icon: const Icon(Icons.local_shipping, size: 16),
              label: const Text('Delivered'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
        if (order.canBeCancelled) ...[
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _cancelOrder(order),
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
              _buildDetailRow('Sync Status', order.syncStatus.name),
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

  void _confirmOrder(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Order'),
        content: Text(
          'Are you sure you want to confirm order #${order.id.substring(0, 8)}? This will mark it as ready for delivery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _updateOrderStatus(
                order.id,
                OrderStatus.confirmed,
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order confirmed successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to confirm order'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _markAsDelivered(Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Delivered'),
        content: Text(
          'Are you sure you want to mark order #${order.id.substring(0, 8)} as delivered?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _updateOrderStatus(
                order.id,
                OrderStatus.delivered,
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order marked as delivered'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to update order status'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Mark Delivered'),
          ),
        ],
      ),
    );
  }

  void _cancelOrder(Order order) {
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

  Future<bool> _updateOrderStatus(String orderId, OrderStatus newStatus) async {
    return await context.read<OrderProvider>().updateOrderStatus(
      orderId,
      newStatus,
    );
  }
}
