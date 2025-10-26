// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/enum/mode.dart';
import 'package:receipts_v2/data/models/enum/payment_status.dart';
import 'package:receipts_v2/data/models/enum/room_status.dart';
import 'package:receipts_v2/data/models/receipt.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/data/models/service.dart';
import 'package:receipts_v2/presentation/providers/building_provider.dart';
import 'package:receipts_v2/presentation/providers/receipt_provider.dart';
import 'package:receipts_v2/presentation/providers/room_provider.dart';
import 'package:receipts_v2/presentation/providers/service_provider.dart';
import 'package:receipts_v2/presentation/view/app_widgets/number_field.dart';
import 'package:receipts_v2/presentation/view/screen/building/widgets/building_form.dart';
import 'package:uuid/uuid.dart';

class ReceiptForm extends StatefulWidget {
  final Mode mode;
  final Receipt? receipt;
  final List<Receipt> receipts;
  final String? selectedBuildingId;

  const ReceiptForm({
    super.key,
    this.mode = Mode.creating,
    this.receipt,
    this.receipts = const [],
    this.selectedBuildingId,
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
  String? selectedBuildingId;
  List<Service> selectedServices = [];

  late TextEditingController lastWaterUsedController;
  late TextEditingController lastElectricUsedController;
  late TextEditingController thisWaterUsedController;
  late TextEditingController thisElectricUsedController;

  bool get isEditing => widget.mode == Mode.editing;

  @override
  void initState() {
    super.initState();
    lastWaterUsedController = TextEditingController();
    lastElectricUsedController = TextEditingController();
    thisWaterUsedController = TextEditingController();
    thisElectricUsedController = TextEditingController();

    selectedBuildingId = widget.selectedBuildingId;

    if (isEditing && widget.receipt != null) {
      final receipt = widget.receipt!;
      id = receipt.id;
      date = receipt.date;
      dueDate = receipt.dueDate;
      lastWaterUsed = receipt.lastWaterUsed;
      lastElectricUsed = receipt.lastElectricUsed;
      thisWaterUsed = receipt.thisWaterUsed;
      thisElectricUsed = receipt.thisElectricUsed;
      paymentStatus = receipt.paymentStatus;
      selectedRoom = receipt.room;
      selectedServices = receipt.services.toList();

      if (selectedRoom?.building != null) {
        selectedBuildingId = selectedRoom!.building!.id;
      }

      lastWaterUsedController.text = lastWaterUsed.toString();
      lastElectricUsedController.text = lastElectricUsed.toString();
      thisWaterUsedController.text = thisWaterUsed.toString();
      thisElectricUsedController.text = thisElectricUsed.toString();
    } else {
      id = const Uuid().v4();
      date = DateTime.now();
      dueDate = DateTime.now().add(const Duration(days: 7));
      lastWaterUsed = 0;
      lastElectricUsed = 0;
      thisWaterUsed = 0;
      thisElectricUsed = 0;
      paymentStatus = PaymentStatus.pending;
      selectedRoom = null;
      selectedServices = [];

      lastWaterUsedController.text = lastWaterUsed.toString();
      lastElectricUsedController.text = lastElectricUsed.toString();
      thisWaterUsedController.text = thisWaterUsed.toString();
      thisElectricUsedController.text = thisElectricUsed.toString();
    }
  }

  @override
  void dispose() {
    lastWaterUsedController.dispose();
    lastElectricUsedController.dispose();
    thisWaterUsedController.dispose();
    thisElectricUsedController.dispose();
    super.dispose();
  }

  Future<void> _loadLastMonthData() async {
    if (selectedRoom == null) return;

    final currentReceiptDate = date;
    final previousReceiptsForRoom = widget.receipts
        .where((r) =>
            r.room?.id == selectedRoom!.id &&
            r.date.isBefore(currentReceiptDate))
        .toList();

    previousReceiptsForRoom.sort((a, b) => b.date.compareTo(a.date));

    Receipt? mostRecentPreviousReceipt;
    if (previousReceiptsForRoom.isNotEmpty) {
      mostRecentPreviousReceipt = previousReceiptsForRoom.first;
    }

    setState(() {
      if (mostRecentPreviousReceipt != null) {
        lastWaterUsed = mostRecentPreviousReceipt.thisWaterUsed;
        lastElectricUsed = mostRecentPreviousReceipt.thisElectricUsed;
        selectedServices = List.from(mostRecentPreviousReceipt.services);
      } else {
        lastWaterUsed = 0;
        lastElectricUsed = 0;
        selectedServices = [];
      }
      lastWaterUsedController.text = lastWaterUsed.toString();
      lastElectricUsedController.text = lastElectricUsed.toString();
    });
  }

  void _save(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newReceipt = Receipt(
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

  // FIXED: Added serviceProvider.load()
  Future<void> _addBuilding(BuildContext context) async {
    final buildingProvider = context.read<BuildingProvider>();
    final roomProvider = context.read<RoomProvider>();
    final serviceProvider = context.read<ServiceProvider>();

    List<Building> buildings = buildingProvider.buildingsState.when(
      success: (data) => data,
      loading: () => [],
      error: (Object error) => [],
    );

    final newBuilding = await Navigator.of(context).push<Building>(
      MaterialPageRoute(
        builder: (ctx) => BuildingForm(
          buildings: buildings,
        ),
      ),
    );

    if (newBuilding != null) {
      await buildingProvider.createBuilding(newBuilding);
      await Future.wait([
        buildingProvider.load(),
        roomProvider.load(),
        serviceProvider.load(),
      ]);
      setState(() {
        selectedBuildingId = newBuilding.id;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final roomProvider = context.watch<RoomProvider>();
    final serviceProvider = context.watch<ServiceProvider>();
    final buildingProvider = context.watch<BuildingProvider>();

    Room? correctedSelectedRoom;
    List<Room> filteredRooms = [];
    List<Service> filteredServices = [];
    String? validatedBuildingId = selectedBuildingId;

    roomProvider.roomsState.when(
      success: (rooms) {
        // Filter by building and only show occupied rooms
        if (selectedBuildingId != null) {
          filteredRooms = rooms
              .where((room) =>
                  room.building?.id == selectedBuildingId &&
                  room.roomStatus == RoomStatus.occupied)
              .toList();
        } else {
          filteredRooms = rooms
              .where((room) => room.roomStatus == RoomStatus.occupied)
              .toList();
        }

        if (selectedRoom != null) {
          try {
            correctedSelectedRoom =
                rooms.firstWhere((r) => r.id == selectedRoom!.id);
            if (selectedBuildingId != null &&
                correctedSelectedRoom?.building?.id != selectedBuildingId) {
              correctedSelectedRoom = null;
              selectedRoom = null;
            }
          } catch (e) {
            correctedSelectedRoom = null;
            selectedRoom = null;
          }
        }
      },
      loading: () {},
      error: (_) {},
    );

    // Filter services based on selected building
    serviceProvider.servicesState.when(
      success: (services) {
        if (selectedBuildingId != null) {
          filteredServices = services
              .where((service) => service.buildingId == selectedBuildingId)
              .toList();
        } else {
          filteredServices = [];
        }
      },
      loading: () {},
      error: (_) {},
    );

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: Text(isEditing ? 'កែប្រែវិក្កយបត្រ' : 'បង្កើតវិក្កយបត្រថ្មី'),
        backgroundColor: theme.colorScheme.background,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.cancel, color: theme.colorScheme.onSurface),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: buildingProvider.buildingsState.when(
          success: (buildings) {
            // FIXED: Validate that selectedBuildingId exists in buildings list
            if (validatedBuildingId != null &&
                !buildings.any((b) => b.id == validatedBuildingId)) {
              // Building ID doesn't exist, reset it
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    selectedBuildingId = null;
                    selectedRoom = null;
                    selectedServices.clear();
                  });
                }
              });
              validatedBuildingId = null;
            }

            if (buildings.isEmpty) {
              return Center(
                heightFactor: 4.5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'មិនមានអាគារទេ។ សូមបង្កើតអគារមុននឹងបង្កើតវិក្កយបត្រ។',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _addBuilding(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 24),
                      ),
                      child: Text(
                        'បង្កើតអគារថ្មី',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Due Date Section
                  Text('កាលបរិច្ឆេទផុតកំណត់',
                      style: theme.textTheme.titleMedium),
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

                  // Building Filter Bar - FIXED: Use validatedBuildingId
                  DropdownButtonFormField<String?>(
                    value: validatedBuildingId,
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text(
                          'ទាំងអស់',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      ...buildings.map((building) => DropdownMenuItem(
                            value: building.id,
                            child: Text(
                              building.name,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )),
                    ],
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedBuildingId = newValue;
                        if (selectedRoom?.building?.id != newValue) {
                          selectedRoom = null;
                        }
                        // Clear selected services when building changes
                        selectedServices.clear();
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'ជ្រើសរើសអគារ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                          width: 0.1,
                        ),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    dropdownColor: theme.colorScheme.surface,
                    icon: Icon(
                      Icons.filter_list,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    validator: (value) => null,
                  ),
                  const SizedBox(height: 16),

                  // Room Selection - Only occupied rooms
                  DropdownButtonFormField<Room>(
                    value: correctedSelectedRoom,
                    items: filteredRooms.map((room) {
                      return DropdownMenuItem(
                        value: room,
                        child: Text(
                          selectedBuildingId != null
                              ? 'បន្ទប់ ${room.roomNumber}'
                              : 'បន្ទប់ ${room.roomNumber} - ${room.building?.name}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      setState(() => selectedRoom = value);
                      await _loadLastMonthData();
                    },
                    decoration: InputDecoration(
                      labelText: 'ជ្រើសរើសបន្ទប់',
                      hintText: filteredRooms.isEmpty
                          ? 'មិនមានបន្ទប់ដែលមានអ្នកជួលទេ'
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                          width: 0.1,
                        ),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceVariant,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                    dropdownColor: theme.colorScheme.surface,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    validator: (value) =>
                        value == null ? 'សូមជ្រើសរើសបន្ទប់' : null,
                  ),
                  const SizedBox(height: 16),

                  // Water and Electricity Usage
                  Text('ការប្រើប្រាស់ខែមុន',
                      style: theme.textTheme.titleMedium),
                  NumberTextFormField(
                    controller: lastWaterUsedController,
                    label: 'ទឹក (m³)',
                    onSaved: (value) => lastWaterUsed = int.parse(value!),
                  ),
                  NumberTextFormField(
                    controller: lastElectricUsedController,
                    label: 'ភ្លើង (kWh)',
                    onSaved: (value) => lastElectricUsed = int.parse(value!),
                  ),

                  const SizedBox(height: 8),

                  Text('ការប្រើប្រាស់ខែនេះ',
                      style: theme.textTheme.titleMedium),
                  NumberTextFormField(
                    controller: thisWaterUsedController,
                    label: 'ទឹក (m³)',
                    onSaved: (value) => thisWaterUsed = int.parse(value!),
                  ),
                  NumberTextFormField(
                    controller: thisElectricUsedController,
                    label: 'ភ្លើង (kWh)',
                    onSaved: (value) => thisElectricUsed = int.parse(value!),
                  ),
                  const SizedBox(height: 16),

                  // Services Selection - Now filtered by building
                  Text('សេវាកម្ម', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  serviceProvider.servicesState.when(
                    success: (services) {
                      if (selectedBuildingId == null) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'សូមជ្រើសរើសអគារមុនសិន',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      if (filteredServices.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'មិនមានសេវាកម្មសម្រាប់អគារនេះទេ',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return Column(
                        children: filteredServices.map((service) {
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
                      );
                    },
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
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error) => Center(
            child: Text(
              'មានបញ្ហាក្នុងការផ្ទុកអគារ: $error',
              style: theme.textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}
