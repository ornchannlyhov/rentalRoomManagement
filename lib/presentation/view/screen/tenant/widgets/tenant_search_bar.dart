import 'package:flutter/material.dart';
import 'package:joul_v2/l10n/app_localizations.dart';

class TenantSearchBar extends StatelessWidget {
  const TenantSearchBar({
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
    final localizations = AppLocalizations.of(context)!;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isSearching ? 56 : 0,
      child: isSearching
          ? Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
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
                  hintText: localizations.searchTenantHint,
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