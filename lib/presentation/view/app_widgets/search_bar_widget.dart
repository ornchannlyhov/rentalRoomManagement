import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({
    super.key,
    required this.isSearching,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchQueryChanged,
    required this.onClearSearch,
    required this.hintText,
  });

  final bool isSearching;
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchQueryChanged;
  final VoidCallback onClearSearch;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isSearching ? 56 : 0,
      child: isSearching
          ? Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: hintText,
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
