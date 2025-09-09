import 'package:flutter/material.dart';
import '../models/stock_update.dart';
import '../services/database_service.dart';

class StockHistoryScreen extends StatefulWidget {
  final String? productId;
  final String? productName;

  const StockHistoryScreen({super.key, this.productId, this.productName});

  @override
  State<StockHistoryScreen> createState() => _StockHistoryScreenState();
}

class _StockHistoryScreenState extends State<StockHistoryScreen> {
  List<StockUpdate> _stockUpdates = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStockUpdates();
  }

  Future<void> _loadStockUpdates() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final allUpdates = await DatabaseService.getAllStockUpdates();

      if (widget.productId != null) {
        // Filter by specific product
        _stockUpdates = allUpdates
            .where((update) => update.productId == widget.productId)
            .toList();
      } else {
        // Show all updates
        _stockUpdates = allUpdates;
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load stock history: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productName != null
              ? 'Stock History - ${widget.productName}'
              : 'All Stock Updates',
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStockUpdates,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStockUpdates,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_stockUpdates.isEmpty) {
      return const Center(
        child: Text(
          'No stock updates found',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _stockUpdates.length,
      itemBuilder: (context, index) {
        final update = _stockUpdates[index];
        return _buildStockUpdateCard(update);
      },
    );
  }

  Widget _buildStockUpdateCard(StockUpdate update) {
    final isIncrease = update.stockDifference > 0;
    final isDecrease = update.stockDifference < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        update.productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        update.formattedUpdateType,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      update.formattedTime,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${update.createdAt.day}/${update.createdAt.month}/${update.createdAt.year}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStockChange(
                    'From',
                    '${update.oldQuantity}',
                    Colors.grey[600]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStockChange(
                    'To',
                    '${update.newQuantity}',
                    Colors.green[700]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStockChange(
                    'Change',
                    '${isIncrease ? '+' : ''}${update.stockDifference}',
                    isIncrease
                        ? Colors.green[700]!
                        : isDecrease
                        ? Colors.red[700]!
                        : Colors.grey[600]!,
                  ),
                ),
              ],
            ),
            if (update.reason != null && update.reason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reason:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      update.reason!,
                      style: TextStyle(color: Colors.grey[800], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStockChange(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
