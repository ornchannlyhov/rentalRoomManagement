// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipts_v2/data/models/building.dart';
import 'package:receipts_v2/data/models/enum/mode.dart';
import 'package:receipts_v2/presentation/providers/building_provider.dart';
import 'package:receipts_v2/presentation/providers/service_provider.dart';
import 'package:receipts_v2/presentation/view/screen/building/widgets/building_card.dart';
import 'package:receipts_v2/presentation/view/screen/building/widgets/building_detail.dart';
import 'package:receipts_v2/presentation/view/screen/building/widgets/building_form.dart';

/// Search bar widget for filtering buildings
class BuildingSearchBar extends StatelessWidget {
  const BuildingSearchBar({
    super.key,
    required this.isSearching,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchQueryChanged,
    required this.onClearSearch,
  });

  final bool isSearching;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchQueryChanged;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isSearching ? 56 : 0,
      child: isSearching
          ? Container(
              margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'ស្វែងរកអគារ...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: onClearSearch,
                        )
                      : null,
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                onChanged: onSearchQueryChanged,
              ))
          : const SizedBox.shrink(),
    );
  }
}

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

  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

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
    _searchController.dispose();
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

  /// Filters buildings based on search query
  List<Building> _filterBuildings(List<Building> buildings) {
    if (_searchQuery.isNotEmpty) {
      return buildings.where((building) {
        final nameLower = building.name.toLowerCase();
        final queryLower = _searchQuery.toLowerCase();
        return nameLower.contains(queryLower);
      }).toList();
    }
    return buildings;
  }

  Future<void> _addBuilding(BuildContext context) async {
    final buildingProvider = context.read<BuildingProvider>();
    final buildings = buildingProvider.buildingsState.when(
      success: (data) => data,
      loading: () => <Building>[],
      error: (_) => <Building>[],
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
    }
  }

  Future<void> _editBuilding(BuildContext context, Building building) async {
    final buildingProvider = context.read<BuildingProvider>();
    final buildings = buildingProvider.buildingsState.when(
      loading: () => <Building>[],
      error: (_) => <Building>[],
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
    serviceProvider.servicesState.when(
      loading: () => [],
      error: (_) => [],
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

  Future<void> _deleteBuilding(BuildContext context, Building building) async {
    final buildingProvider = context.read<BuildingProvider>();

    // Show confirmation dialog
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
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
            'តើអ្នកពិតជាចង់លុបអគារ "${building.name}" មែនទេ?', // "Are you sure you want to delete building?"
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

    if (shouldDelete == true) {
      try {
        await buildingProvider.deleteBuilding(building.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('អគារ "${building.name}" ត្រូវបានលុបជោគជ័យ'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('បរាជ័យក្នុងការលុបអគារ: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    }
  }

  void _onBuildingTap(BuildContext context, Building building) {
    // Default tap action - navigate to building details
    _viewBuilding(context, building);
  }

  void _onBuildingLongPress(BuildContext context, Building building) {
    // Long press action - show edit form
    _editBuilding(context, building);
  }

  void _dismissibleDeleteBuilding(
      BuildContext context, int index, Building building) {
    final buildingProvider = context.read<BuildingProvider>();

    buildingProvider.deleteBuilding(building.id);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
                _searchQuery.isNotEmpty
                    ? 'រកមិនឃើញអគារ'
                    : 'មិនមានអគារ', // "No buildings found" or "No buildings available"
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? 'សូមព្យាយាមស្វែងរកជាមួយពាក្យគន្លឹះផ្សេង'
                    : 'សូមចុចប៊ូតុង + ដើម្បីបន្ថែមអគារថ្មី',
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

            // Calculate staggered animation intervals with proper clamping
            final double begin = (index * 0.05).clamp(0.0, 0.4);
            final double end = ((index * 0.05) + 0.6).clamp(0.0, 1.0);

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    begin,
                    end,
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
                          'តើអ្នកពិតជាចង់លុបអគារ "${building.name}" មែនទេ?', // "Are you sure you want to delete building?"
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
                onDismissed: (_) =>
                    _dismissibleDeleteBuilding(context, index, building),
                child: BuildingCard(
                  building: building,
                  onTap: () => _onBuildingTap(context, building),
                  onLongPress: () => _onBuildingLongPress(context, building),
                  onEdit: () => _editBuilding(context, building),
                  onDelete: () => _deleteBuilding(context, building),
                  onViewDetails: () => _viewBuilding(context, building),
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
      appBar: AppBar(
        title: Text(
          'អគារ',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () => _addBuilding(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          BuildingSearchBar(
            isSearching: _isSearching,
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearchQueryChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            onClearSearch: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
          ),
          Expanded(
            // OPTIMIZED: Use Selector instead of Consumer
            child: Selector<BuildingProvider, dynamic>(
              selector: (_, provider) => provider.buildingsState,
              builder: (context, buildingsState, _) {
                // FIX: Use buildingsState directly instead of buildings
                return buildingsState.when(
                  loading: () => _buildLoadingState(theme),
                  error: (error) => _buildErrorState(theme, error),
                  success: (allBuildings) {
                    final filteredBuildings = _filterBuildings(allBuildings);

                    if (filteredBuildings.isEmpty) {
                      return _buildEmptyState(theme);
                    }
                    return _buildBuildingsList(theme, filteredBuildings);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
