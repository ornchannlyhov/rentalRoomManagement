import 'package:flutter/material.dart';
import 'package:joul_v2/data/models/building.dart';
import 'package:joul_v2/data/models/enum/mode.dart';
import 'package:joul_v2/data/models/service.dart';
import 'package:joul_v2/presentation/view/app_widgets/number_field.dart';
import 'package:uuid/uuid.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

class ServiceForm extends StatefulWidget {
  final Service? service;
  final Mode mode;
  final Building building;

  const ServiceForm({
    super.key,
    this.service,
    this.mode = Mode.creating,
    required this.building,
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
        buildingId: widget.building.id,
      );

      Navigator.pop(context, newService);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        iconTheme: theme.iconTheme.copyWith(
          color: theme.iconTheme.color ?? theme.colorScheme.onPrimary,
        ),
        title: Text(
          isEditing ? l10n.editService : l10n.createNewService,
          style: theme.appBarTheme.titleTextStyle ??
              theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
        ),
        elevation: theme.appBarTheme.elevation ?? 0,
        shadowColor: theme.appBarTheme.shadowColor,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.cancel, color: theme.colorScheme.onSurface),
            tooltip: l10n.cancel,
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
                decoration: InputDecoration(
                  labelText: l10n.serviceName,
                  labelStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                    ),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                onSaved: (value) => name = value!,
                validator: (value) =>
                    value!.isEmpty ? l10n.serviceNameRequired : null,
              ),
              const SizedBox(height: 16),
              NumberTextFormField(
                initialValue: price.toString(),
                label: l10n.servicePriceLabel,
                onSaved: (value) {
                  if (value != null && value.isNotEmpty) {
                    price = double.tryParse(value) ?? 0.0;
                  }
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(
                      Icons.save,
                      color: Colors.white,
                    ),
                    label: Text(
                      l10n.save,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                    ),
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
