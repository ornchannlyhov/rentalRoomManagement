import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:joul_v2/data/models/building.dart';
import 'package:joul_v2/data/models/report.dart';
import 'package:joul_v2/data/models/enum/report_status.dart';
import 'package:joul_v2/presentation/providers/report_provider.dart';
import 'package:joul_v2/presentation/view/app_widgets/global_snackbar.dart';
import 'package:joul_v2/presentation/view/screen/building/widgets/report/report_card.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

class ReportListTab extends StatefulWidget {
  final Building building;
  final VoidCallback onRefresh;

  const ReportListTab({
    super.key,
    required this.building,
    required this.onRefresh,
  });

  @override
  State<ReportListTab> createState() => _ReportListTabState();
}

class _ReportListTabState extends State<ReportListTab> {
  ReportStatus? _statusFilter;

  Future<void> _deleteReport(BuildContext context, int index, Report report,
      {bool confirm = true}) async {
    final l10n = AppLocalizations.of(context)!;

    // Show confirmation dialog if requested
    bool confirmed = true;
    if (confirm) {
      confirmed = await _showConfirmDialog(
        context,
        title: l10n.deleteReport,
        content: l10n.deleteReportConfirmFrom(
          report.tenant?.name ?? l10n.unknownTenant,
        ),
      );
    }

    if (confirmed && context.mounted) {
      await context.read<ReportProvider>().deleteReport(report.id);

      if (context.mounted) {
        GlobalSnackBar.show(
          context: context,
          message: l10n.reportDeletedSuccess,
        );
      }
    }
  }

  Future<void> _changeReportStatus(BuildContext context, Report report) async {
    final l10n = AppLocalizations.of(context)!;
    final newStatus = await showDialog<ReportStatus>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          l10n.changeStatus,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ReportStatus.values.map((status) {
              return ListTile(
                title: Text(_getStatusLabel(context, status)),
                leading: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(context, status),
                ),
                selected: report.status == status,
                selectedTileColor:
                    _getStatusColor(context, status).withOpacity(0.1),
                onTap: () => Navigator.pop(context, status),
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (newStatus != null && newStatus != report.status && context.mounted) {
      try {
        await context.read<ReportProvider>().updateReportStatus(
              report.id,
              newStatus.toApiString(),
            );
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          GlobalSnackBar.show(
            context: context,
            message:
                l10n.reportStatusUpdated(_getStatusLabel(context, newStatus)),
          );
        }
      } catch (e) {
        if (context.mounted) {
          final l10n = AppLocalizations.of(context)!;
          GlobalSnackBar.show(
            context: context,
            message: l10n.reportStatusUpdateFailed,
          );
        }
      }
    }
  }

  Color _getStatusColor(BuildContext context, ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.resolved:
        return Colors.green;
    }
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Icons.pending_outlined;
      case ReportStatus.resolved:
        return Icons.check_circle_outline;
    }
  }

  String _getStatusLabel(BuildContext context, ReportStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case ReportStatus.pending:
        return l10n.reportStatusPending;
      case ReportStatus.resolved:
        return l10n.reportStatusResolved;
    }
  }

  Future<bool> _showConfirmDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              content,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  l10n.cancel,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(
                  l10n.delete,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildResolveBackground() {
    return Container(
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.only(left: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 4),
          const Text(
            "Resolve",
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissBackground(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            color: Theme.of(context).colorScheme.onError,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.delete,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onError,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateWithRefresh(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAction,
            icon: Icon(_statusFilter != null ? Icons.clear : Icons.refresh),
            label: Text(actionText),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.errorOccurred,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.tryAgain),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Header with title and filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.reports,
                style: theme.textTheme.titleLarge,
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ReportStatus?>(
                    value: _statusFilter,
                    icon: const Icon(
                      Icons.filter_alt,
                      size: 20,
                    ),
                    dropdownColor: theme.colorScheme.surface,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                    ),
                    elevation: 8,
                    borderRadius: BorderRadius.circular(12),
                    isDense: true,
                    hint: Text(
                      l10n.allReports,
                      style: TextStyle(
                        color: _statusFilter == null
                            ? theme.colorScheme.onSurfaceVariant
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    selectedItemBuilder: (BuildContext context) {
                      return [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.clear_all,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 8),
                            Text(l10n.allReports),
                          ],
                        ),
                        ...ReportStatus.values.map((status) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(status),
                                size: 18,
                                color: _getStatusColor(context, status),
                              ),
                              const SizedBox(width: 8),
                              Text(_getStatusLabel(context, status)),
                            ],
                          );
                        }),
                      ];
                    },
                    items: [
                      DropdownMenuItem<ReportStatus?>(
                        value: null,
                        child: Row(
                          children: [
                            const Icon(Icons.clear_all, size: 18),
                            const SizedBox(width: 8),
                            Text(l10n.allReports),
                          ],
                        ),
                      ),
                      ...ReportStatus.values.map((status) => DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Icon(
                                  _getStatusIcon(status),
                                  size: 18,
                                  color: _getStatusColor(context, status),
                                ),
                                const SizedBox(width: 8),
                                Text(_getStatusLabel(context, status)),
                              ],
                            ),
                          )),
                    ],
                    onChanged: (ReportStatus? newValue) {
                      setState(() {
                        _statusFilter = newValue;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Content area
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Selector<ReportProvider, dynamic>(
              selector: (_, provider) => provider.reportsState,
              builder: (context, reportsState, _) {
                return reportsState.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error) => RefreshIndicator(
                    onRefresh: () async => widget.onRefresh(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: _buildErrorState(context, error),
                      ),
                    ),
                  ),
                  success: (reports) {
                    // Filter by building
                    var buildingReports = reports
                        .where(
                            (r) => r.room?.building?.id == widget.building.id)
                        .toList();

                    // Apply status filter
                    if (_statusFilter != null) {
                      buildingReports = buildingReports
                          .where((r) => r.status == _statusFilter)
                          .toList();
                    }

                    if (buildingReports.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () async => widget.onRefresh(),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: _buildEmptyStateWithRefresh(
                              context,
                              icon: Icons.report_outlined,
                              title: _statusFilter != null
                                  ? l10n.noFilteredReports(
                                      _getStatusLabel(context, _statusFilter!))
                                  : l10n.noReports,
                              subtitle: _statusFilter != null
                                  ? l10n.noFilteredReportsSubtitle
                                  : l10n.noReportsSubtitle,
                              actionText: _statusFilter != null
                                  ? l10n.clearFilter
                                  : l10n.refresh,
                              onAction: _statusFilter != null
                                  ? () => setState(() => _statusFilter = null)
                                  : widget.onRefresh,
                            ),
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => widget.onRefresh(),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        itemCount: buildingReports.length,
                        itemBuilder: (context, index) {
                          final report = buildingReports[index];
                          return Dismissible(
                            key: Key(report.id),
                            background: _buildResolveBackground(),
                            secondaryBackground:
                                _buildDismissBackground(context),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                if (report.status == ReportStatus.resolved) {
                                  GlobalSnackBar.show(
                                    context: context,
                                    message: "Report is already resolved",
                                  );
                                  return false;
                                }

                                try {
                                  await context
                                      .read<ReportProvider>()
                                      .updateReportStatus(
                                        report.id,
                                        ReportStatus.resolved.toApiString(),
                                      );
                                  if (context.mounted) {
                                    GlobalSnackBar.show(
                                      context: context,
                                      message: "Report marked as resolved",
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    GlobalSnackBar.show(
                                      context: context,
                                      message: l10n.reportStatusUpdateFailed,
                                    );
                                  }
                                }
                                return false;
                              } else {
                                return await _showConfirmDialog(
                                  context,
                                  title: l10n.deleteReport,
                                  content: l10n.deleteReportConfirmFrom(
                                    report.tenant?.name ?? l10n.unknownTenant,
                                  ),
                                );
                              }
                            },
                            onDismissed: (direction) {
                              if (direction == DismissDirection.endToStart) {
                                _deleteReport(context, index, report,
                                    confirm: false);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: ReportCard(
                                report: report,
                                onMenuSelected: (option) {
                                  if (option == ReportMenuOption.changeStatus) {
                                    _changeReportStatus(context, report);
                                  } else if (option ==
                                      ReportMenuOption.delete) {
                                    _deleteReport(context, index, report);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
