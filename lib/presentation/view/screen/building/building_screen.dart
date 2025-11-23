import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/data/models/building.dart';
import 'package:joul_v2/data/models/enum/mode.dart';
import 'package:joul_v2/presentation/providers/building_provider.dart';
import 'package:joul_v2/presentation/providers/service_provider.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';
import 'package:joul_v2/presentation/view/app_widgets/search_bar_widget.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/building_card.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/building_detail.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/building_form.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'widgets/skeleton_building.dart';

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
  bool _isRefreshing = false;
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
    if (!mounted) return;

    final buildingProvider = context.read<BuildingProvider>();
    final serviceProvider = context.read<ServiceProvider>();

    try {
      await Future.wait([
        buildingProvider.syncBuildings(),
        serviceProvider.syncServices(),
      ]);
    } catch (e) {
      if (mounted) {
        await Future.wait([
          buildingProvider.load(),
          serviceProvider.load(),
        ]);
      }
    }

    if (mounted) {
      _animationController.forward();
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Add minimum delay to show skeleton
    await Future.wait([
      _loadData(),
      Future.delayed(const Duration(milliseconds: 500)),
    ]);

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

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

  Future<void> _deleteBuilding(
      BuildContext context, int index, Building building) async {
    final l10n = AppLocalizations.of(context)!;
    final buildingProvider = context.read<BuildingProvider>();

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
            l10n.confirmDelete,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Text(
            l10n.deleteBuildingConfirmMsg(building.name),
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n.cancel,
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
                l10n.delete,
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
          GlobalSnackBar.show(
            context: context,
            message: l10n.buildingDeletedSuccess(building.name),
          );
        }
      } catch (error) {
        if (mounted) {
          GlobalSnackBar.show(
            context: context,
            message: l10n.buildingDeleteFailed(error.toString()),
            isError: true,
          );
        }
      }
    }
  }

  void _onBuildingTap(BuildContext context, Building building) {
    _viewBuilding(context, building);
  }

  void _onBuildingLongPress(BuildContext context, Building building) {
    _editBuilding(context, building);
  }

  void _dismissibleDeleteBuilding(
      BuildContext context, int index, Building building) {
    final l10n = AppLocalizations.of(context)!;
    final buildingProvider = context.read<BuildingProvider>();

    buildingProvider.deleteBuilding(building.id);

    GlobalSnackBar.show(
      context: context,
      message: l10n.buildingDeleted(building.name, building.id),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
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
                  color: theme.colorScheme.surfaceContainerHighest
                      .withOpacity(0.3),
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
                    ? l10n.noBuildingsFound
                    : l10n.noBuildingsAvailable,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty
                    ? l10n.tryDifferentKeywords
                    : l10n.tapPlusToAddBuilding,
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 2),
      itemBuilder: (context, index) => const BuildingCardSkeleton(),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    final l10n = AppLocalizations.of(context)!;
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
            l10n.errorLoadingData,
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
            label: Text(l10n.tryAgain),
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
    final l10n = AppLocalizations.of(context)!;

    // If refreshing, show skeleton INSTEAD of the list
    if (_isRefreshing) {
      return _buildLoadingState(theme);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _handleRefresh,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        color: theme.colorScheme.primary,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: buildings.length,
          separatorBuilder: (context, index) => const SizedBox(height: 2),
          itemBuilder: (ctx, index) {
            final building = buildings[index];

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
                        l10n.delete,
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
                          l10n.confirmDelete,
                          style: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: Text(
                          l10n.deleteBuildingConfirmMsg(building.name),
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(
                              l10n.cancel,
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
                              l10n.delete,
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
                  onDelete: () => _deleteBuilding(context, index, building),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          l10n.buildings,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchBarWidget(
              isSearching: _isSearching,
              searchController: _searchController,
              searchQuery: _searchQuery,
              hintText: l10n.searchBuildings,
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
          ),
          Expanded(
            child: Selector<BuildingProvider, dynamic>(
              selector: (_, provider) => provider.buildingsState,
              builder: (context, buildingsState, _) {
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
