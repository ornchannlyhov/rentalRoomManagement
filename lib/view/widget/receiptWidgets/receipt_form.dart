import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:receipts_v2/model/enum/mode.dart';
import 'package:receipts_v2/model/enum/payment_status.dart';
import 'package:receipts_v2/model/receipt.dart';
import 'package:receipts_v2/model/room.dart';
import 'package:receipts_v2/model/service.dart';
import 'package:receipts_v2/repository/receipt_repository.dart';
import 'package:receipts_v2/repository/room_repository.dart';
import 'package:receipts_v2/repository/service_repository.dart';
import 'package:receipts_v2/view/appComponent/number_field.dart';
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
  List<Room> availableRooms = [];
  List<Service> availableServices = [];

  final RoomRepository _roomRepository = RoomRepository();
  final ServiceRepository _serviceRepository = ServiceRepository();
  final ReceiptRepository receiptRepository = ReceiptRepository();

  Receipt? previousReceipt;
  late TextEditingController lastWaterUsedController;
  late TextEditingController lastElectricUsedController;

  bool get isEditing => widget.mode == Mode.editing;

  @override
  void initState() {
    super.initState();
    _loadRoomsAndServices();
    _loadLastMonthData();
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
      id=  const Uuid().v4();
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
    }
  }

  Future<void> _loadRoomsAndServices() async {
    try {
      await Future.wait([_roomRepository.load(), _serviceRepository.load()]);
      setState(() {
        availableRooms = _roomRepository.getAllRooms();
        availableServices = _serviceRepository.getAllServices();
        selectedRoom = isEditing && widget.receipt != null
            ? availableRooms.firstWhere(
                (room) => room.id == widget.receipt!.room!.id,
                orElse: () => availableRooms.first,
              )
            : availableRooms.first;
      });
    } catch (e) {
      throw Exception('Error loading rooms or services: $e');
    }
  }

  Future<void> _loadLastMonthData() async {
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
          paymentStatus: paymentStatus),
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

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newReceipt = Receipt(
        id: isEditing ? widget.receipt!.id :id,
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
      Navigator.pop(context, newReceipt);
    }
  }

  Future<void> setDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dueDate,
      firstDate: DateTime(2015, 8),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != dueDate) {
      setState(() {
        dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Receipt' : 'Create New Receipt'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel),
          ),
        ],
        backgroundColor: const Color.fromARGB(255, 18, 13, 29),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Due Date'),
              Row(
                children: [
                  Text(DateFormat.yMd().format(dueDate)),
                  const SizedBox(height: 20.0),
                  IconButton(
                    onPressed: () => setDueDate(context),
                    icon: const Icon(Icons.calendar_month_rounded),
                  ),
                ],
              ),
              DropdownButtonFormField<Room>(
                value: selectedRoom,
                items: availableRooms.map((room) {
                  return DropdownMenuItem(
                    value: room,
                    child: Text('Room: ${room.roomNumber}'),
                  );
                }).toList(),
                onChanged: (value) async {
                  setState(() => selectedRoom = value);
                  await _loadLastMonthData();
                },
                decoration: const InputDecoration(labelText: 'Room'),
                validator: (value) =>
                    value == null ? 'Please select a room' : null,
              ),
              NumberTextFormField(
                controller: lastWaterUsedController,
                label: 'Last Month Water',
                onSaved: (value) => lastWaterUsed = int.parse(value!),
              ),
              NumberTextFormField(
                controller: lastElectricUsedController,
                label: 'Last Month Electric',
                onSaved: (value) => lastElectricUsed = int.parse(value!),
              ),
              NumberTextFormField(
                  initialValue: thisWaterUsed.toString(),
                  label: 'This Month Water',
                  onSaved: (value) => thisWaterUsed = int.parse(value!)),
              NumberTextFormField(
                initialValue: thisElectricUsed.toString(),
                label: 'This Month Electric',
                onSaved: (value) => thisElectricUsed = int.parse(value!),
              ),
              const Text('Services'),
              Wrap(
                children: availableServices.map((service) {
                  final isSelected = selectedServices
                      .any((selected) => selected.id == service.id);
                  return CheckboxListTile(
                    title: Text(service.name),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          selectedServices.add(service);
                        } else {
                          selectedServices.removeWhere(
                              (selected) => selected.id == service.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save Bill'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
