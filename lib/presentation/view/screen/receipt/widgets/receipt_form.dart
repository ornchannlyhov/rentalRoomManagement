import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/enum/mode.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/data/models/service.dart';
import 'package:receipts_v2/presentation/providers/receipt_provider.dart';
import 'package:receipts_v2/presentation/providers/room_provider.dart';
import 'package:receipts_v2/presentation/providers/service_provider.dart';
import 'package:receipts_v2/presentation/view/app_widgets/number_field.dart';
import 'package:uuid/uuid.dart';

class ReceiptForm extends StatefulWidget {
  final Mode mode;
  final Receipt? receipt;
  final List<Receipt> receipts;

  const ReceiptForm({
    super.key,
    this.mode = Mode.creating,
    this.receipt,
    this.receipts = const [],
  });

  @override
  State<ReceiptForm> createState() => _ReceiptFormState();
}

class _ReceiptFormState extends State<ReceiptForm> {
  final _formKey = GlobalKey<FormState>();

  late String id;
  late DateTime date;
  late DateTime dueDate;
  late int lastWaterUsed;
  late int lastElectricUsed;
  late int thisWaterUsed;
  late int thisElectricUsed;
  late PaymentStatus paymentStatus;
  Room? selectedRoom;
  List<Service> selectedServices = [];

  late TextEditingController lastWaterUsedController;
  late TextEditingController lastElectricUsedController;

  bool get isEditing => widget.mode == Mode.editing;
  Receipt? previousReceipt;

  @override
  void initState() {
    super.initState();
    lastWaterUsedController = TextEditingController();
    lastElectricUsedController = TextEditingController();

    if (isEditing && widget.receipt != null) {
      final receipt = widget.receipt!;
      id = receipt.id;
      date = receipt.date;
      dueDate = receipt.dueDate;
      lastWaterUsed = receipt.lastWaterUsed;
      lastElectricUsed = receipt.lastElectricUsed;
      lastWaterUsedController.text = lastWaterUsed.toString();
      lastElectricUsedController.text = lastElectricUsed.toString();
      thisWaterUsed = receipt.thisWaterUsed;
      thisElectricUsed = receipt.thisElectricUsed;
      paymentStatus = receipt.paymentStatus;
      selectedRoom = receipt.room;
      selectedServices = receipt.services.toList();
    } else {
      id = const Uuid().v4();
      date = DateTime.now();
      dueDate = DateTime.now().add(const Duration(days: 7));
      lastWaterUsed = 0;
      lastElectricUsed = 0;
      lastWaterUsedController.text = lastWaterUsed.toString();
      lastElectricUsedController.text = lastElectricUsed.toString();
      thisWaterUsed = 0;
      thisElectricUsed = 0;
      paymentStatus = PaymentStatus.pending;
      selectedRoom = null;
      selectedServices = [];
    }
  }

  @override
  void dispose() {
    lastWaterUsedController.dispose();
    lastElectricUsedController.dispose();
    super.dispose();
  }

  Future<void> _loadLastMonthData(BuildContext context) async {
    if (selectedRoom == null) return;

    final now = DateTime.now();
    final startOfPreviousMonth = DateTime(now.year, now.month - 1, 1);
    final endOfPreviousMonth = DateTime(now.year, now.month, 0);

    previousReceipt = widget.receipts.firstWhere(
      (receipt) =>
          receipt.room!.roomNumber == selectedRoom!.roomNumber &&
          receipt.date.isAfter(
              startOfPreviousMonth.subtract(const Duration(days: 1))) &&
          receipt.date
              .isBefore(endOfPreviousMonth.add(const Duration(days: 1))),
      orElse: () => Receipt(
        id: id,
        date: date,
        dueDate: dueDate,
        lastWaterUsed: lastWaterUsed,
        lastElectricUsed: lastElectricUsed,
        thisWaterUsed: thisWaterUsed,
        thisElectricUsed: thisElectricUsed,
        paymentStatus: paymentStatus,
        room: selectedRoom,
        services: selectedServices,
      ),
    );

    if (previousReceipt != null) {
      setState(() {
        lastWaterUsed = previousReceipt!.thisWaterUsed;
        lastElectricUsed = previousReceipt!.thisElectricUsed;
        lastWaterUsedController.text = lastWaterUsed.toString();
        lastElectricUsedController.text = lastElectricUsed.toString();
        selectedServices = previousReceipt!.services;
      });
    }
  }

  void _save(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newReceipt = Receipt(
        id: isEditing ? widget.receipt!.id : id,
        date: isEditing ? widget.receipt!.date : DateTime.now(),
        dueDate: dueDate,
        lastWaterUsed: lastWaterUsed,
        lastElectricUsed: lastElectricUsed,
        thisWaterUsed: thisWaterUsed,
        thisElectricUsed: thisElectricUsed,
        paymentStatus: paymentStatus,
        room: selectedRoom,
        services: selectedServices,
      );

      if (isEditing) {
        context.read<ReceiptProvider>().updateReceipt(newReceipt);
      } else {
        context.read<ReceiptProvider>().createReceipt(newReceipt);
      }
      Navigator.pop(context);
    }
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != dueDate) {
      setState(() => dueDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roomProvider = context.watch<RoomProvider>();
    final serviceProvider = context.watch<ServiceProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'កែប្រែវិក្កយបត្រ' : 'បង្កើតវិក្កយបត្រថ្មី'),
        backgroundColor: theme.colorScheme.background,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Due Date Section
              Text('កាលបរិច្ឆេទផុតកំណត់', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDueDate(context),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: theme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy').format(dueDate),
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Room Selection
              DropdownButtonFormField<Room>(
                value: selectedRoom,
                items: roomProvider.rooms.when(
                  success: (rooms) => rooms.map((room) {
                    return DropdownMenuItem(
                      value: room,
                      child: Text(
                        'បន្ទប់ ${room.roomNumber} - ${room.building!.name}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }).toList(),
                  loading: () => [],
                  error: (_) => [],
                ),
                onChanged: (value) async {
                  setState(() => selectedRoom = value);
                  await _loadLastMonthData(context);
                },
                decoration: const InputDecoration(
                  labelText: 'ជ្រើសរើសបន្ទប់',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? 'សូមជ្រើសរើសបន្ទប់' : null,
              ),
              const SizedBox(height: 16),

              // Water and Electricity Usage
              Text('ការប្រើប្រាស់ទឹក', style: theme.textTheme.titleMedium),
              NumberTextFormField(
                controller: lastWaterUsedController,
                label: 'ខែមុន (m³)',
                onSaved: (value) => lastWaterUsed = int.parse(value!),
              ),
              NumberTextFormField(
                initialValue: thisWaterUsed.toString(),
                label: 'ខែនេះ (m³)',
                onSaved: (value) => thisWaterUsed = int.parse(value!),
              ),
              const SizedBox(height: 8),

              Text('ការប្រើប្រាស់ភ្លើង', style: theme.textTheme.titleMedium),
              NumberTextFormField(
                controller: lastElectricUsedController,
                label: 'ខែមុន (kWh)',
                onSaved: (value) => lastElectricUsed = int.parse(value!),
              ),
              NumberTextFormField(
                initialValue: thisElectricUsed.toString(),
                label: 'ខែនេះ (kWh)',
                onSaved: (value) => thisElectricUsed = int.parse(value!),
              ),
              const SizedBox(height: 16),

              // Services Selection
              Text('សេវាកម្ម', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              serviceProvider.services.when(
                success: (services) => Column(
                  children: services.map((service) {
                    final isSelected =
                        selectedServices.any((s) => s.id == service.id);
                    return CheckboxListTile(
                      title: Text(service.name),
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            selectedServices.add(service);
                          } else {
                            selectedServices
                                .removeWhere((s) => s.id == service.id);
                          }
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_) => const Text('មានបញ្ហាក្នុងការផ្ទុកសេវាកម្ម'),
              ),
              const SizedBox(height: 24),

              // Save Button
              ElevatedButton(
                onPressed: () => _save(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'រក្សាទុក',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
