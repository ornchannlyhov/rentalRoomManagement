import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/enum/mode.dart';
import 'package:receipts_v2/presentation/providers/building_provider.dart';
import 'package:receipts_v2/presentation/providers/service_provider.dart';
import 'package:receipts_v2/presentation/view/app_widgets/app_bar.dart';
import 'package:receipts_v2/presentation/view/screen/building/widgets/building_card.dart';
import 'package:receipts_v2/presentation/view/screen/building/widgets/building_detail.dart';
import 'package:receipts_v2/presentation/view/screen/building/widgets/building_form.dart';

class BuildingScreen extends StatefulWidget {
  const BuildingScreen({super.key});

  @override
  State<BuildingScreen> createState() => _BuildingScreenState();
}

class _BuildingScreenState extends State<BuildingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final buildingProvider = context.read<BuildingProvider>();
    final serviceProvider = context.read<ServiceProvider>();

    await Future.wait([
      buildingProvider.load(),
      serviceProvider.load(),
    ]);

    _animationController.forward();
  }

  Future<void> _addBuilding(BuildContext context) async {
    final buildingProvider = context.read<BuildingProvider>();
    final buildings = buildingProvider.buildings.when(
      success: (data) => data,
      loading: () {},
      error: (Object error) {},
    );

    final newBuilding = await Navigator.of(context).push<Building>(
      MaterialPageRoute(
        builder: (ctx) => BuildingForm(
          buildings: buildings!,
        ),
      ),
    );

    if (newBuilding != null) {
      await buildingProvider.createBuilding(newBuilding);
    }
  }

  Future<void> _editBuilding(BuildContext context, Building building) async {
    final buildingProvider = context.read<BuildingProvider>();
    final buildings = buildingProvider.buildings.when(
      loading: () => <Building>[],
      error: (err) => <Building>[],
      success: (data) => data,
    );

    final updatedBuilding = await Navigator.of(context).push<Building>(
      MaterialPageRoute(
        builder: (ctx) => BuildingForm(
          mode: Mode.editing,
          building: building,
          buildings: buildings,
        ),
      ),
    );

    if (updatedBuilding != null) {
      await buildingProvider.updateBuilding(updatedBuilding);
    }
  }

  Future<void> _viewBuilding(BuildContext context, Building building) async {
    final serviceProvider = context.read<ServiceProvider>();
    serviceProvider.services.when(
      loading: () => [],
      error: (err) => [],
      success: (data) => data,
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => BuildingDetail(
          building: building,
        ),
      ),
    );
  }

  void _deleteBuilding(BuildContext context, int index, Building building) {
    final buildingProvider = context.read<BuildingProvider>();
    final theme = Theme.of(context);

    buildingProvider.deleteBuilding(building.id);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        content: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: theme.colorScheme.onError,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'អាគារ "${building.name}" ត្រូវបានលុប', // "Building deleted"
                style: TextStyle(
                  color: theme.colorScheme.onError,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'មិនលុប', // "Undo"
          textColor: theme.colorScheme.onError,
          onPressed: () async {
            await buildingProvider.restoreBuilding(index, building);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.apartment_outlined,
                  size: 80,
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'មិនមានអាគារ', // "No buildings available"
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'សូមចុចប៊ូតុង + ដើម្បីបន្ថែមអាគារថ្មី', // "Tap + to add a new building"
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'កំពុងដំណើការ...', // "Loading..."
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'មានបញ្ហាក្នុងការផ្ទុកទិន្នន័យ', // "Error loading data"
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('ព្យាយាមម្តងទៀត'), // "Try again"
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingsList(ThemeData theme, List<Building> buildings) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadData,
        backgroundColor: theme.colorScheme.surfaceVariant,
        color: theme.colorScheme.primary,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: buildings.length,
          separatorBuilder: (context, index) => const SizedBox(height: 2),
          itemBuilder: (ctx, index) {
            final building = buildings[index];
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    index * 0.1,
                    (index * 0.1) + 0.6,
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
              child: Dismissible(
                key: Key(building.id),
                background: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.onError,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'លុប', // "Delete"
                        style: TextStyle(
                          color: theme.colorScheme.onError,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        backgroundColor: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        title: Text(
                          'បញ្ជាក់ការលុប', // "Confirm Delete"
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: Text(
                          'តើអ្នកពិតជាចង់លុបអាគារ "${building.name}" មែនទេ?', // "Are you sure you want to delete building?"
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              'បោះបង់', // "Cancel"
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.error,
                            ),
                            child: Text(
                              'លុប', // "Delete"
                              style: TextStyle(
                                color: theme.colorScheme.onError,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (_) => _deleteBuilding(context, index, building),
                child: BuildingCard(
                  building: building,
                  onTap: () => _viewBuilding(context, building),
                  onLongPress: () => _editBuilding(context, building),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppbarCustom(
        header: 'អាគារ', // "Buildings"
        onAddPressed: () => _addBuilding(context),
      ),
      body: Consumer<BuildingProvider>(
        builder: (context, buildingProvider, child) {
          return buildingProvider.buildings.when(
            loading: () => _buildLoadingState(theme),
            error: (error) => _buildErrorState(theme, error),
            success: (buildings) {
              if (buildings.isEmpty) {
                return _buildEmptyState(theme);
              }
              return _buildBuildingsList(theme, buildings);
            },
          );
        },
      ),
    );
  }
}
