import 'package:flutter/material.dart';
import 'package:receipts_v2/model/building.dart';
import 'package:receipts_v2/model/enum/mode.dart';
import 'package:receipts_v2/model/service.dart';
import 'package:receipts_v2/view/appComponent/number_field.dart';
import 'package:uuid/uuid.dart';

class ServiceForm extends StatefulWidget {
  final Service? service;
  final Mode mode;

  const ServiceForm({
    super.key,
    this.service,
    this.mode = Mode.creating, required Building building,
  });

  @override
  State<ServiceForm> createState() => _ServiceFormState();
}

class _ServiceFormState extends State<ServiceForm> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late double price;

  bool get isEditing => widget.mode == Mode.editing;

  @override
  void initState() {
    super.initState();
    if (isEditing && widget.service != null) {
      final service = widget.service!;
      name = service.name;
      price = service.price;
    } else {
      name = '';
      price = 0.0;
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newService = Service(
        id: isEditing ? widget.service!.id : const Uuid().v4(),
        name: name,
        price: price,
      );

      Navigator.pop(context, newService);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Service' : 'Create New Service'),
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
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Service Name'),
                onSaved: (value) => name = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a service name' : null,
              ),
              NumberTextFormField(
                initialValue: price.toString(),
                label: 'Price',
                onSaved: (value) => price = double.parse(value!),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Save Service'),
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
