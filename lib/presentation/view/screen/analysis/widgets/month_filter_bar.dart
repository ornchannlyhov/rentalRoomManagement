import 'package:flutter/material.dart';
import 'package:joul_v2/l10n/app_localizations.dart';
import 'package:joul_v2/core/theme/app_theme.dart';

class MonthFilterBar extends StatelessWidget {
  const MonthFilterBar({
    super.key,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.monthNames,
  });

  final DateTime selectedMonth;
  final ValueChanged<DateTime> onMonthChanged;
  final List<String> monthNames;

  void _previousMonth() {
    onMonthChanged(DateTime(selectedMonth.year, selectedMonth.month - 1));
  }

  void _nextMonth() {
    onMonthChanged(DateTime(selectedMonth.year, selectedMonth.month + 1));
  }

  Future<void> _selectMonth(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;
    DateTime tempSelectedMonth = selectedMonth;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(localizations.selectMonth),
              content: SizedBox(
                width: double.minPositive,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(localizations.year,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(
                          child: DropdownButton<int>(
                            value: tempSelectedMonth.year,
                            isExpanded: true,
                            items: List.generate(10, (index) {
                              final year = DateTime.now().year - 5 + index;
                              return DropdownMenuItem(
                                value: year,
                                child: Text(year.toString()),
                              );
                            }),
                            onChanged: (year) {
                              if (year != null) {
                                setDialogState(() {
                                  tempSelectedMonth =
                                      DateTime(year, tempSelectedMonth.month);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(localizations.month,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final isSelected =
                            tempSelectedMonth.month == (index + 1);

                        return InkWell(
                          onTap: () {
                            onMonthChanged(
                                DateTime(tempSelectedMonth.year, index + 1));
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                monthNames[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(localizations.cancel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Card(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.cardColorDark
          : null,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            IconButton(
              onPressed: _previousMonth,
              icon: const Icon(Icons.chevron_left),
              tooltip: localizations.previousMonth,
            ),
            Expanded(
              child: InkWell(
                onTap: () => _selectMonth(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${monthNames[selectedMonth.month - 1]} ${selectedMonth.year}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: _nextMonth,
              icon: const Icon(Icons.chevron_right),
              tooltip: localizations.nextMonth,
            ),
          ],
        ),
      ),
    );
  }
}
