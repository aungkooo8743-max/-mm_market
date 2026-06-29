import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_providers.dart';

class SearchFilterSheet extends ConsumerWidget {
  const SearchFilterSheet({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(searchFilterProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Search Filters', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SwitchListTile(
              value: filter.newestFirst,
              contentPadding: EdgeInsets.zero,
              title: const Text('Newest first'),
              onChanged: (value) {
                ref.read(searchFilterProvider.notifier).state = filter.copyWith(newestFirst: value);
                ref.invalidate(searchResultsProvider);
              },
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}
