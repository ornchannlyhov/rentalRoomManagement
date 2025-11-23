import 'package:flutter/material.dart';
import 'package:joul_v2/data/models/report.dart';
import 'package:joul_v2/data/models/enum/report_status.dart';
import 'package:joul_v2/data/models/enum/report_priority.dart';
import 'package:joul_v2/core/theme/app_theme.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    switch (priority) {
      case ReportPriority.urgent:
        return colorScheme.error;
      case ReportPriority.high:
        return Colors.red;
      case ReportPriority.medium:
        return Colors.orange;
      case ReportPriority.low:
        return Colors.green;
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
        return Icons.autorenew;
      case ReportStatus.resolved:
        return Icons.check_circle_outline;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: theme.brightness == Brightness.dark
          ? AppTheme.cardColorDark
          : colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Tenant info and menu
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      color: colorScheme.onPrimaryContainer,
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
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (report.room != null)
                          Text(
                            'Room ${report.room!.roomNumber}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (onMenuSelected != null)
                    PopupMenuButton<ReportMenuOption>(
                      icon: Icon(
                        Icons.more_vert,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onSelected: onMenuSelected,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: ReportMenuOption.changeStatus,
                          child: Row(
                            children: [
                              Icon(Icons.edit,
                                  size: 20, color: colorScheme.primary),
                              const SizedBox(width: 12),
                              const Text('Change Status'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: ReportMenuOption.delete,
                          child: Row(
                            children: [
                              Icon(Icons.delete,
                                  size: 20, color: colorScheme.error),
                              const SizedBox(width: 12),
                              const Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Problem description
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
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
              const SizedBox(height: 12),

              // Status and Priority badges
              Row(
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(context, report.status)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getStatusColor(context, report.status),
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
                        Text(
                          _getStatusLabel(report.status),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getStatusColor(context, report.status),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Priority badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(context, report.priority)
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getPriorityColor(context, report.priority),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.flag,
                          size: 14,
                          color: _getPriorityColor(context, report.priority),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getPriorityLabel(report.priority),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getPriorityColor(context, report.priority),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Notes (if present)
              if (report.notes != null && report.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
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
