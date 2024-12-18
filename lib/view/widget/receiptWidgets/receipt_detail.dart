import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:receipts_v2/model/receipt.dart';

class ReceiptDetailScreen extends StatelessWidget {
  final Receipt receipt;

  const ReceiptDetailScreen({required this.receipt, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Room ${receipt.room?.roomNumber ?? "N/A"}'),
        backgroundColor:const Color.fromARGB(255, 18, 13, 29),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Receipt Information'),
              _buildInfoRow('Room number', receipt.room!.roomNumber),
              _buildInfoRow('Room Owner', receipt.room!.client!.name),
              _buildInfoRow('Date', DateFormat.yMd().format(receipt.date)),
              _buildInfoRow(
                  'Due Date', DateFormat.yMd().format(receipt.dueDate)),
              const SizedBox(height: 8),
              _buildSectionHeader('Utility Usage'),
              _buildInfoRow('Last Water Used', '${receipt.lastWaterUsed} m³'),
              _buildInfoRow('This Water Used', '${receipt.thisWaterUsed} m³'),
              _buildInfoRow(
                  'Last Electric Used', '${receipt.lastElectricUsed} kWh'),
              _buildInfoRow(
                  'This Electric Used', '${receipt.thisElectricUsed} kWh'),
              const SizedBox(height: 8),
              _buildSectionHeader('Services'),
              receipt.services.isEmpty
                  ? const Text(
                      'No additional services.',
                      style: TextStyle(color: Colors.grey),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: receipt.services
                          .map(
                            (service) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    service.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    '\$${service.price.toStringAsFixed(2)}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
              const SizedBox(height: 8),
              _buildSectionHeader('Total Price'),
              _buildInfoRow('Total Water Price',
                  '\$${receipt.calculateWaterPrice().toStringAsFixed(2)}'),
              _buildInfoRow('Total Electric Price',
                  '\$${receipt.calculateElectricPrice().toStringAsFixed(2)}'),
              _buildInfoRow('Total Service Price',
                  '\$${receipt.calculateTotalServicePrice().toStringAsFixed(2)}'),
              _buildInfoRow('Room Rent',
                  '\$${receipt.room?.building?.rentPrice.toStringAsFixed(2) ?? "N/A"}'),
              const Divider(color: Colors.grey),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Grand Total',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${receipt.calculateTotalPrice().toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
