import 'package:flutter/material.dart';
import 'package:receipts_v2/model/building.dart';
import 'package:receipts_v2/model/enum/mode.dart';
import 'package:receipts_v2/view/appComponent/number_field.dart';

class BuildingForm extends StatefulWidget {
  final Mode mode;
  final Building? building;
  final List<Building> buildings;

  const BuildingForm({
    super.key,
    this.mode = Mode.creating,
    this.building,
    this.buildings = const [],
  });

  @override
  State<BuildingForm> createState() => _BuildingFormState();
}

class _BuildingFormState extends State<BuildingForm> {
  final _formKey = GlobalKey<FormState>();

  late String id;
  late String name;
  late double rentPrice;
  late double electricPrice;
  late double waterPrice;

  bool get isEditing => widget.mode == Mode.editing;

  @override
  void initState() {
    super.initState();

    if (isEditing && widget.building != null) {
      final building = widget.building!;
      id = building.id;
      name = building.name;
      rentPrice = building.rentPrice;
      electricPrice = building.electricPrice;
      waterPrice = building.waterPrice;
    } else {
      id = '';
      name = '';
      rentPrice = 0.0;
      electricPrice = 0.0;
      waterPrice = 0.0;
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newBuilding = Building(
        id: isEditing ? widget.building!.id : DateTime.now().toString(),
        name: name,
        rentPrice: rentPrice,
        electricPrice: electricPrice,
        waterPrice: waterPrice,
      );

      Navigator.pop(context, newBuilding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Building' : 'Create New Building'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.cancel),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Building Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a building name.';
                  }
                  return null;
                },
                onSaved: (value) => name = value!,
              ),
              NumberTextFormField(
                initialValue: rentPrice.toString(),
                label: 'Rent Price',
                onSaved: (value) => rentPrice = double.parse(value!),
              ),
              NumberTextFormField(
                initialValue: electricPrice.toString(),
                label: 'Electric Price',
                onSaved: (value) => electricPrice = double.parse(value!),
              ),
              NumberTextFormField(
                initialValue: waterPrice.toString(),
                label: 'Water Price',
                onSaved: (value) => waterPrice = double.parse(value!),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save Building'),
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
