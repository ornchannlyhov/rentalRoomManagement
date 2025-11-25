import 'package:flutter/material.dart';
import 'package:joul_v2/data/models/report.dart';
import 'package:joul_v2/data/models/enum/report_status.dart';
import 'package:joul_v2/data/models/enum/report_priority.dart';

enum ReportMenuOption { changeStatus, delete }

class ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback? onTap;
  final Function(ReportMenuOption)? onMenuSelected;

  const ReportCard({
    super.key,
    required this.report,
    this.onTap,
    this.onMenuSelected,
  });

  Color _getPriorityColor(BuildContext context, ReportPriority priority) {
    switch (priority) {
      case ReportPriority.urgent:
        return Colors.red.shade700;
      case ReportPriority.high:
        return Colors.orange.shade700;
      case ReportPriority.medium:
        return Colors.amber.shade700;
      case ReportPriority.low:
        return Colors.green.shade700;
    }
  }

  Color _getStatusColor(BuildContext context, ReportStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case ReportStatus.pending:
        return Colors.orange;
      case ReportStatus.inProgress:
        return Colors.blue;
      case ReportStatus.resolved:
        return Colors.green;
      case ReportStatus.closed:
        return colorScheme.outline;
    }
  }

  IconData _getStatusIcon(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return Icons.pending_outlined;
      case ReportStatus.inProgress:
        return Icons.autorenew_rounded;
      case ReportStatus.resolved:
        return Icons.check_circle_outline_rounded;
      case ReportStatus.closed:
        return Icons.cancel_outlined;
    }
  }

  String _getStatusLabel(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.inProgress:
        return 'In Progress';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.closed:
        return 'Closed';
    }
  }

  String _getPriorityLabel(ReportPriority priority) {
    switch (priority) {
      case ReportPriority.urgent:
        return 'Urgent';
      case ReportPriority.high:
        return 'High';
      case ReportPriority.medium:
        return 'Medium';
      case ReportPriority.low:
        return 'Low';
    }
  }

  void _showOptionsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.report_problem_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.tenant?.name ?? 'Unknown Tenant',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (report.room != null)
                            Text(
                              'Room ${report.room!.roomNumber}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Menu options
              if (onMenuSelected != null) ...[
                ListTile(
                  leading: Icon(
                    Icons.edit_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Change Status'),
                  onTap: () {
                    Navigator.pop(context);
                    onMenuSelected?.call(ReportMenuOption.changeStatus);
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.delete_rounded,
                    color: Colors.red,
                  ),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.pop(context);
                    onMenuSelected?.call(ReportMenuOption.delete);
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Tenant info and menu
              Row(
                children: [
                  // Tenant avatar with gradient
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _getPriorityColor(context, report.priority).withOpacity(0.8),
                          _getPriorityColor(context, report.priority),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.tenant?.name ?? 'Unknown Tenant',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (report.room != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Room ${report.room!.roomNumber}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onMenuSelected != null)
                    Material(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showOptionsBottomSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.more_vert_rounded,
                            color: colorScheme.onSurface.withOpacity(0.6),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Problem description
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Text(
                  report.problemDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 10),

              // Status and Priority badges
              Row(
                children: [
                  // Status badge
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(context, report.status)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _getStatusColor(context, report.status)
                              .withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(report.status),
                            size: 14,
                            color: _getStatusColor(context, report.status),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _getStatusLabel(report.status),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _getStatusColor(context, report.status),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Priority badge
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(context, report.priority)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _getPriorityColor(context, report.priority)
                              .withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            size: 14,
                            color: _getPriorityColor(context, report.priority),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _getPriorityLabel(report.priority),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: _getPriorityColor(context, report.priority),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Notes (if present)
              if (report.notes != null && report.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.note_outlined,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          report.notes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}