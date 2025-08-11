import 'package:flutter/material.dart';
import 'package:receipts_v2/data/models/enum/gender.dart';
import 'package:receipts_v2/data/models/room.dart';
import 'package:receipts_v2/data/models/tenant.dart';
import 'package:receipts_v2/data/models/enum/mode.dart';
import 'package:receipts_v2/data/repositories/room_repository.dart';

class TenantForm extends StatefulWidget {
  final Mode mode;
  final Tenant? tenant;

  const TenantForm({
    super.key,
    this.mode = Mode.creating,
    this.tenant,
  });

  @override
  State<TenantForm> createState() => _TenantFormState();
}

class _TenantFormState extends State<TenantForm> {
  final _formKey = GlobalKey<FormState>();
  final roomRepository = RoomRepository();

  List<Room> availableRooms = [];
  List<Room> rooms = [];

  late String id;
  late String name;
  late String phoneNumber;
  Room? selectedRoom;
  late Gender gender;

  bool get isEditing => widget.mode == Mode.editing;

  @override
  void initState() {
    super.initState();
    _loadRoom();
    if (isEditing && widget.tenant != null) {
      final tenant = widget.tenant!;
      id = tenant.id;
      name = tenant.name;
      phoneNumber = tenant.phoneNumber;
      selectedRoom = tenant.room;
      gender = tenant.gender;
    } else {
      id = '';
      name = '';
      phoneNumber = '';
      selectedRoom = null;
      gender = Gender.male;
    }
  }

  Future<void> _loadRoom() async {
    try {
      await roomRepository.load();
      setState(() {
        availableRooms = roomRepository.getAvailableRooms();
        rooms = roomRepository.getAllRooms();
        selectedRoom = isEditing && widget.tenant?.room != null
            ? rooms.firstWhere(
                (room) => room.id == widget.tenant!.room!.id,
                orElse: () => rooms.first,
              )
            : null;
        if (selectedRoom != null &&
            !availableRooms.any((room) => room.id == selectedRoom!.id)) {
          availableRooms.add(selectedRoom!);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('បរាជ័យក្នុងការផ្ទុកបន្ទប់: $e')),
        );
      }
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newTenant = Tenant(
        id: isEditing ? widget.tenant!.id : DateTime.now().toString(),
        name: name,
        phoneNumber: phoneNumber,
        room: selectedRoom,
        gender: gender,
      );
      Navigator.pop(context, newTenant);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const fieldSpacing = SizedBox(height: 12);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'កែប្រែអ្នកជួល' : 'បង្កើតអ្នកជួលថ្មី'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: name,
                decoration: InputDecoration(
                  labelText: 'ឈ្មោះអ្នកជួល',
                  labelStyle: theme.textTheme.bodyMedium,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'សូមបញ្ចូលឈ្មោះអ្នកជួល';
                  }
                  return null;
                },
                onSaved: (value) => name = value!,
              ),
              fieldSpacing,
              TextFormField(
                initialValue: phoneNumber,
                decoration: InputDecoration(
                  labelText: 'លេខទូរស័ព្ទ',
                  labelStyle: theme.textTheme.bodyMedium,
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'សូមបញ្ចូលលេខទូរស័ព្ទ';
                  }
                  return null;
                },
                onSaved: (value) => phoneNumber = value!,
              ),
              fieldSpacing,
              DropdownButtonFormField<Room>(
                value: selectedRoom,
                items: availableRooms.map((room) {
                  return DropdownMenuItem(
                    value: room,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('បន្ទប់: ${room.roomNumber}'),
                        Text('- ${room.building!.name}'),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedRoom = value;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'បន្ទប់',
                  labelStyle: theme.textTheme.bodyMedium,
                ),
                validator: (value) =>
                    value == null ? 'សូមជ្រើសរើសបន្ទប់' : null,
              ),
              fieldSpacing,
              DropdownButtonFormField<Gender>(
                value: gender,
                decoration: InputDecoration(
                  labelText: 'ភេទ',
                  labelStyle: theme.textTheme.bodyMedium,
                ),
                items: Gender.values
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(
                          {
                            Gender.male: 'បុរស',
                            Gender.female: 'នារី',
                            Gender.other: 'ផ្សេងៗ',
                          }[g]!,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => gender = value!),
                onSaved: (value) => gender = value!,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: Text(isEditing ? 'កែប្រអ្នកជួល' : 'បង្កើតអ្នកជួល',
                        style: theme.textTheme.labelSmall),
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
