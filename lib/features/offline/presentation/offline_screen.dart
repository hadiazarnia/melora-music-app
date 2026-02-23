// lib/features/offline/presentation/offline_screen.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/duration_extensions.dart';
import '../../../core/services/file_import_service.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/melora_search_bar.dart';
import '../../../shared/widgets/song_tile.dart';
import '../../../shared/widgets/album_art_widget.dart';
import '../../../shared/models/song_model.dart';

class OfflineScreen extends ConsumerStatefulWidget {
  const OfflineScreen({super.key});

  @override
  ConsumerState<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends ConsumerState<OfflineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';
  String _sortBy = 'date';
  String _filterBy = 'all'; // all, recent, most_played
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearchAndUnfocus() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    setState(() => _searchQuery = '');
  }

  void _showSortMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SortBottomSheet(
        currentSort: _sortBy,
        onSortChanged: (sort) {
          setState(() => _sortBy = sort);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterBottomSheet(
        currentFilter: _filterBy,
        onFilterChanged: (filter) {
          setState(() => _filterBy = filter);
          Navigator.pop(ctx);
        },
      ),
    );
  }

  Future<void> _importFiles() async {
    if (_isImporting) return;

    setState(() => _isImporting = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
        withData: false, // Don't load file data into memory
        withReadStream: false,
      );

      if (result != null && result.files.isNotEmpty) {
        int importedCount = 0;

        for (final file in result.files) {
          if (file.path != null) {
            final sourceFile = File(file.path!);
            if (await sourceFile.exists()) {
              try {
                // Copy to import directory
                final importDir = await FileImportService.getImportDirectory();
                final destPath = '${importDir.path}/${file.name}';

                // Check if file already exists
                final destFile = File(destPath);
                if (!await destFile.exists()) {
                  await sourceFile.copy(destPath);
                  importedCount++;
                } else {
                  // File already exists, skip or rename
                  importedCount++;
                }
              } catch (e) {
                debugPrint('Error copying file: $e');
              }
            }
          }
        }

        if (importedCount > 0 && mounted) {
          // Refresh library
          await ref.read(musicCacheServiceProvider).clearCache();
          ref.read(musicRefreshProvider.notifier).state++;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported $importedCount song(s)'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: MeloraColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } on PlatformException catch (e) {
      // Handle platform exceptions gracefully
      if (e.code != 'multiple_request') {
        debugPrint('FilePicker error: ${e.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import failed: ${e.message}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: MeloraColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Import error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: MeloraColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider);
    final hasSong = currentSong.valueOrNull != null;

    final bottomPadding = hasSong
        ? MeloraDimens.miniPlayerHeight + MeloraDimens.tabBarHeight + 30
        : MeloraDimens.tabBarHeight + 20;

    return GestureDetector(
      onTap: () => _searchFocusNode.unfocus(),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MeloraDimens.pagePadding,
                MeloraDimens.lg,
                MeloraDimens.pagePadding,
                MeloraDimens.md,
              ),
              child: Row(
                children: [
                  Text(
                    'My Music',
                    style: context.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  // iOS Import button
                  if (Platform.isIOS)
                    _isImporting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: MeloraColors.primary,
                            ),
                          )
                        : IconButton(
                            onPressed: _importFiles,
                            icon: Icon(
                              Iconsax.import_1,
                              color: context.textSecondary,
                              size: 22,
                            ),
                            tooltip: 'Import Files',
                          ),
                  // Filter
                  IconButton(
                    onPressed: _showFilterMenu,
                    icon: Icon(
                      Iconsax.filter,
                      color: _filterBy != 'all'
                          ? MeloraColors.primary
                          : context.textSecondary,
                      size: 22,
                    ),
                    tooltip: 'Filter',
                  ),
                  // Sort
                  IconButton(
                    onPressed: _showSortMenu,
                    icon: Icon(
                      Iconsax.sort,
                      color: context.textSecondary,
                      size: 22,
                    ),
                    tooltip: 'Sort',
                  ),
                  // Refresh
                  IconButton(
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      final refresh = ref.read(refreshMusicLibraryProvider);
                      await refresh();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Music library refreshed'),
                            backgroundColor: MeloraColors.primary,
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.only(
                              bottom: bottomPadding,
                              left: 16,
                              right: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      Iconsax.refresh,
                      color: context.textSecondary,
                      size: 22,
                    ),
                    tooltip: 'Refresh',
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MeloraDimens.pagePadding,
              ),
              child: MeloraSearchBar(
                controller: _searchController,
                focusNode: _searchFocusNode,
                hintText: 'Search songs, artists...',
                onChanged: (val) => setState(() => _searchQuery = val),
                trailing: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: _clearSearchAndUnfocus,
                        icon: Icon(
                          Icons.close,
                          size: 20,
                          color: context.textTertiary,
                        ),
                      )
                    : null,
              ),
            ),

            const SizedBox(height: MeloraDimens.lg),

            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MeloraDimens.pagePadding,
              ),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: context.isDark
                      ? MeloraColors.darkSurfaceLight
                      : MeloraColors.lightSurfaceLight,
                  borderRadius: BorderRadius.circular(MeloraDimens.radiusFull),
                  border: Border.all(
                    color: context.borderColor.withAlpha(128),
                    width: 0.5,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelPadding: EdgeInsets.zero,
                  padding: const EdgeInsets.all(4),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(
                      MeloraDimens.radiusFull,
                    ),
                    gradient: MeloraColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: MeloraColors.primary.withAlpha(77),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: context.textSecondary,
                  labelStyle: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  splashFactory: NoSplash.splashFactory,
                  tabs: const [
                    Tab(text: 'Songs'),
                    Tab(text: 'Recent'),
                    Tab(text: 'Folders'),
                    Tab(text: 'Favorites'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: MeloraDimens.md),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SongsTab(
                    searchQuery: _searchQuery,
                    sortBy: _sortBy,
                    filterBy: _filterBy,
                    bottomPadding: bottomPadding,
                    onSongTap: _clearSearchAndUnfocus,
                  ),
                  _RecentlyPlayedTab(
                    searchQuery: _searchQuery,
                    bottomPadding: bottomPadding,
                    onSongTap: _clearSearchAndUnfocus,
                  ),
                  _FoldersTab(
                    searchQuery: _searchQuery,
                    bottomPadding: bottomPadding,
                  ),
                  _FavoritesTab(
                    searchQuery: _searchQuery,
                    bottomPadding: bottomPadding,
                    onSongTap: _clearSearchAndUnfocus,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  FILTER BOTTOM SHEET
// ═══════════════════════════════════════════════════════════

class _FilterBottomSheet extends StatelessWidget {
  final String currentFilter;
  final ValueChanged<String> onFilterChanged;

  const _FilterBottomSheet({
    required this.currentFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? MeloraColors.darkSurface
            : MeloraColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(MeloraDimens.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.textTertiary.withAlpha(77),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: MeloraDimens.lg),
          Text(
            'Filter by',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MeloraDimens.md),
          _FilterTile(
            title: 'All Songs',
            subtitle: 'Show all songs',
            icon: Iconsax.music,
            isSelected: currentFilter == 'all',
            onTap: () => onFilterChanged('all'),
          ),
          _FilterTile(
            title: 'Recently Played',
            subtitle: 'Songs you played recently',
            icon: Iconsax.clock,
            isSelected: currentFilter == 'recent',
            onTap: () => onFilterChanged('recent'),
          ),
          _FilterTile(
            title: 'Most Played',
            subtitle: 'Your top played songs',
            icon: Iconsax.chart,
            isSelected: currentFilter == 'most_played',
            onTap: () => onFilterChanged('most_played'),
          ),
          SizedBox(height: context.bottomPadding),
        ],
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? MeloraColors.primary : context.textSecondary,
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: TextStyle(color: context.textTertiary)),
      trailing: isSelected
          ? const Icon(Icons.check, color: MeloraColors.primary)
          : null,
      onTap: onTap,
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SORT BOTTOM SHEET
// ═══════════════════════════════════════════════════════════

class _SortBottomSheet extends StatelessWidget {
  final String currentSort;
  final ValueChanged<String> onSortChanged;

  const _SortBottomSheet({
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? MeloraColors.darkSurface
            : MeloraColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(MeloraDimens.pagePadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.textTertiary.withAlpha(77),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: MeloraDimens.lg),
          Text(
            'Sort by',
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MeloraDimens.md),
          ...[
            ('date', 'Date Added', Iconsax.calendar),
            ('title', 'Title', Iconsax.text),
            ('artist', 'Artist', Iconsax.microphone),
            ('duration', 'Duration', Iconsax.timer_1),
            ('play_count', 'Play Count', Iconsax.chart),
            ('size', 'File Size', Iconsax.document),
          ].map(
            (item) => ListTile(
              leading: Icon(
                item.$3,
                color: currentSort == item.$1
                    ? MeloraColors.primary
                    : context.textSecondary,
              ),
              title: Text(item.$2),
              trailing: currentSort == item.$1
                  ? const Icon(Icons.check, color: MeloraColors.primary)
                  : null,
              onTap: () => onSortChanged(item.$1),
            ),
          ),
          SizedBox(height: context.bottomPadding),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SONGS TAB
// ═══════════════════════════════════════════════════════════

class _SongsTab extends ConsumerWidget {
  final String searchQuery;
  final String sortBy;
  final String filterBy;
  final double bottomPadding;
  final VoidCallback onSongTap;

  const _SongsTab({
    required this.searchQuery,
    required this.sortBy,
    required this.filterBy,
    required this.bottomPadding,
    required this.onSongTap,
  });

  List<SongModel> _sortSongs(List<SongModel> songs, String sortBy) {
    final sorted = List<SongModel>.from(songs);
    switch (sortBy) {
      case 'title':
        sorted.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
        break;
      case 'artist':
        sorted.sort(
          (a, b) => a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
        );
        break;
      case 'duration':
        sorted.sort((a, b) => b.duration.compareTo(a.duration));
        break;
      case 'play_count':
        sorted.sort((a, b) => b.playCount.compareTo(a.playCount));
        break;
      case 'size':
        sorted.sort((a, b) => (b.size ?? 0).compareTo(a.size ?? 0));
        break;
      default: // date
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Choose provider based on filter
    final songsAsync = filterBy == 'recent'
        ? ref.watch(recentlyPlayedProvider)
        : filterBy == 'most_played'
        ? ref.watch(mostPlayedProvider)
        : ref.watch(allSongsProvider);

    return songsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: MeloraColors.primary),
      ),
      error: (e, _) => _EmptyState(
        icon: Iconsax.music,
        title: 'No songs found',
        subtitle: Platform.isIOS
            ? 'Tap + to import music files'
            : 'Grant storage permission to scan music',
        action: TextButton.icon(
          onPressed: () => ref.refresh(allSongsProvider),
          icon: const Icon(Iconsax.refresh),
          label: const Text('Retry'),
        ),
      ),
      data: (songs) {
        var filtered = searchQuery.isEmpty
            ? songs
            : songs
                  .where(
                    (s) =>
                        s.title.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                        s.artist.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                        s.album.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                  )
                  .toList();

        filtered = _sortSongs(filtered, sortBy);

        if (filtered.isEmpty) {
          return _EmptyState(
            icon: Iconsax.music_dashboard,
            title: 'No songs found',
            subtitle: searchQuery.isNotEmpty ? 'Try a different search' : null,
          );
        }

        return Column(
          children: [
            // Stats & Shuffle
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MeloraDimens.pagePadding,
              ),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} songs',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onSongTap();
                      final handler = ref.read(audioHandlerProvider);
                      final shuffled = List.of(filtered)..shuffle();
                      handler.loadPlaylist(shuffled);
                    },
                    icon: const Icon(Iconsax.shuffle, size: 18),
                    label: const Text('Shuffle'),
                    style: TextButton.styleFrom(
                      foregroundColor: MeloraColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Song List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: bottomPadding),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final song = filtered[i];
                  return SongTile(
                    song: song,
                    index: i,
                    showPlayCount: sortBy == 'play_count',
                    showSize: sortBy == 'size',
                    onTap: () {
                      onSongTap();
                      ref
                          .read(audioHandlerProvider)
                          .playSong(song, queue: filtered);
                    },
                    onOptionsTap: () => _showSongOptions(context, ref, song),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  RECENTLY PLAYED TAB
// ═══════════════════════════════════════════════════════════

class _RecentlyPlayedTab extends ConsumerWidget {
  final String searchQuery;
  final double bottomPadding;
  final VoidCallback onSongTap;

  const _RecentlyPlayedTab({
    required this.searchQuery,
    required this.bottomPadding,
    required this.onSongTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentlyPlayedProvider);

    return recentAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: MeloraColors.primary),
      ),
      error: (e, _) =>
          const _EmptyState(icon: Iconsax.clock, title: 'No recent plays'),
      data: (songs) {
        final filtered = searchQuery.isEmpty
            ? songs
            : songs
                  .where(
                    (s) =>
                        s.title.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                        s.artist.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                  )
                  .toList();

        if (filtered.isEmpty) {
          return const _EmptyState(
            icon: Iconsax.clock,
            title: 'No recently played songs',
            subtitle: 'Start playing music to see your history',
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MeloraDimens.pagePadding,
              ),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} songs',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Clear History?'),
                          content: const Text(
                            'This will clear your play history but keep play counts.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Clear'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ref
                            .read(playHistoryServiceProvider)
                            .clearHistory();
                        ref.invalidate(recentlyPlayedProvider);
                      }
                    },
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: bottomPadding),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final song = filtered[i];
                  return SongTile(
                    song: song,
                    index: i,
                    showPlayCount: true,
                    onTap: () {
                      onSongTap();
                      ref
                          .read(audioHandlerProvider)
                          .playSong(song, queue: filtered);
                    },
                    onOptionsTap: () => _showSongOptions(context, ref, song),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  FOLDERS TAB (keep existing)
// ═══════════════════════════════════════════════════════════

class _FoldersTab extends ConsumerWidget {
  final String searchQuery;
  final double bottomPadding;

  const _FoldersTab({required this.searchQuery, required this.bottomPadding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);

    return foldersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: MeloraColors.primary),
      ),
      error: (e, _) => const _EmptyState(
        icon: Iconsax.folder_cross,
        title: 'No folders found',
      ),
      data: (folders) {
        final filtered = searchQuery.isEmpty
            ? folders
            : folders
                  .where(
                    (f) => f.name.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ),
                  )
                  .toList();

        if (filtered.isEmpty) {
          return const _EmptyState(
            icon: Iconsax.folder_2,
            title: 'No music folders found',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(bottom: bottomPadding),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final folder = filtered[i];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: MeloraDimens.pagePadding,
                vertical: MeloraDimens.xs,
              ),
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(MeloraDimens.radiusMd),
                  gradient: LinearGradient(
                    colors: [
                      MeloraColors.primary.withAlpha(51),
                      MeloraColors.secondary.withAlpha(26),
                    ],
                  ),
                ),
                child: const Icon(
                  Iconsax.folder,
                  color: MeloraColors.primary,
                  size: 26,
                ),
              ),
              title: Text(
                folder.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${folder.songCount} songs',
                style: TextStyle(color: context.textSecondary, fontSize: 13),
              ),
              trailing: Icon(
                Iconsax.arrow_right_3,
                size: 20,
                color: context.textTertiary,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _FolderSongsScreen(
                      folderName: folder.name,
                      folderPath: folder.path,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  FAVORITES TAB
// ═══════════════════════════════════════════════════════════

class _FavoritesTab extends ConsumerWidget {
  final String searchQuery;
  final double bottomPadding;
  final VoidCallback onSongTap;

  const _FavoritesTab({
    required this.searchQuery,
    required this.bottomPadding,
    required this.onSongTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(favoriteSongsProvider);

    return favAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: MeloraColors.primary),
      ),
      error: (e, _) => const _EmptyState(
        icon: Iconsax.heart,
        title: 'Error loading favorites',
      ),
      data: (songs) {
        final filtered = searchQuery.isEmpty
            ? songs
            : songs
                  .where(
                    (s) =>
                        s.title.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ||
                        s.artist.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ),
                  )
                  .toList();

        if (filtered.isEmpty) {
          return const _EmptyState(
            icon: Iconsax.heart,
            title: 'No favorites yet',
            subtitle: 'Tap the heart icon on any song',
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MeloraDimens.pagePadding,
              ),
              child: Row(
                children: [
                  Text(
                    '${filtered.length} favorites',
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      onSongTap();
                      final handler = ref.read(audioHandlerProvider);
                      final shuffled = List.of(filtered)..shuffle();
                      handler.loadPlaylist(shuffled);
                    },
                    icon: const Icon(Iconsax.shuffle, size: 18),
                    label: const Text('Shuffle'),
                    style: TextButton.styleFrom(
                      foregroundColor: MeloraColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(bottom: bottomPadding),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final song = filtered[i];
                  return SongTile(
                    song: song,
                    index: i,
                    onTap: () {
                      onSongTap();
                      ref
                          .read(audioHandlerProvider)
                          .playSong(song, queue: filtered);
                    },
                    onOptionsTap: () => _showSongOptions(context, ref, song),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  FOLDER SONGS SCREEN
// ═══════════════════════════════════════════════════════════

class _FolderSongsScreen extends ConsumerWidget {
  final String folderName;
  final String folderPath;

  const _FolderSongsScreen({
    required this.folderName,
    required this.folderPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(folderSongsProvider(folderPath));
    final currentSong = ref.watch(currentSongProvider);
    final hasSong = currentSong.valueOrNull != null;

    final bottomPadding = hasSong
        ? MeloraDimens.miniPlayerHeight + MeloraDimens.tabBarHeight + 30
        : 20.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(folderName),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
        actions: [
          IconButton(
            onPressed: () {
              songsAsync.whenData((songs) {
                if (songs.isNotEmpty) {
                  HapticFeedback.mediumImpact();
                  final shuffled = List.of(songs)..shuffle();
                  ref.read(audioHandlerProvider).loadPlaylist(shuffled);
                }
              });
            },
            icon: const Icon(Iconsax.shuffle),
            tooltip: 'Shuffle',
          ),
        ],
      ),
      body: songsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: MeloraColors.primary),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (songs) {
          if (songs.isEmpty) {
            return const Center(child: Text('No songs in this folder'));
          }
          return ListView.builder(
            padding: EdgeInsets.only(bottom: bottomPadding),
            itemCount: songs.length,
            itemBuilder: (ctx, i) {
              final song = songs[i];
              return SongTile(
                song: song,
                index: i,
                showSize: true,
                onTap: () {
                  ref.read(audioHandlerProvider).playSong(song, queue: songs);
                },
                onOptionsTap: () => _showSongOptions(context, ref, song),
              );
            },
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  EMPTY STATE
// ═══════════════════════════════════════════════════════════

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const _EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MeloraDimens.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.isDark
                    ? MeloraColors.darkSurfaceLight
                    : MeloraColors.lightSurfaceLight,
              ),
              child: Icon(icon, size: 36, color: context.textTertiary),
            ),
            const SizedBox(height: MeloraDimens.lg),
            Text(
              title,
              style: context.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: MeloraDimens.xs),
              Text(
                subtitle!,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.textTertiary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: MeloraDimens.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SONG OPTIONS (existing, add play count display)
// ═══════════════════════════════════════════════════════════

void _showSongOptions(BuildContext context, WidgetRef ref, SongModel song) {
  final favService = ref.read(favoritesServiceProvider);
  final historyService = ref.read(playHistoryServiceProvider);
  final isFav = favService.isFavorite(song.id);
  final playCount = historyService.getPlayCount(song.id);

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => Container(
      decoration: BoxDecoration(
        color: context.isDark
            ? MeloraColors.darkSurface
            : MeloraColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.textTertiary.withAlpha(77),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: MeloraDimens.lg),

            // Song info header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MeloraDimens.pagePadding,
              ),
              child: Row(
                children: [
                  AlbumArtWidget(songId: song.id, size: 56),
                  const SizedBox(width: MeloraDimens.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.displayTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          song.displayArtist,
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        if (playCount > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$playCount plays',
                            style: const TextStyle(
                              color: MeloraColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: MeloraDimens.md),
            const Divider(),

            // Options
            _OptionTile(
              icon: isFav ? Icons.favorite : Icons.favorite_border,
              iconColor: isFav ? MeloraColors.secondary : null,
              title: isFav ? 'Remove from Favorites' : 'Add to Favorites',
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(toggleFavoriteProvider)(song.id);
                HapticFeedback.lightImpact();
              },
            ),
            _OptionTile(
              icon: Iconsax.music_playlist,
              title: 'Play Next',
              onTap: () {
                Navigator.pop(ctx);
                ref.read(audioHandlerProvider).playAfterCurrent(song);
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Playing "${song.displayTitle}" next'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _OptionTile(
              icon: Iconsax.add_circle,
              title: 'Add to Queue',
              onTap: () {
                Navigator.pop(ctx);
                ref.read(audioHandlerProvider).addToQueue(song);
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added "${song.displayTitle}" to queue'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            _OptionTile(
              icon: Iconsax.info_circle,
              title: 'Song Info',
              onTap: () {
                Navigator.pop(ctx);
                _showSongInfo(context, song, playCount);
              },
            ),

            const SizedBox(height: MeloraDimens.lg),
          ],
        ),
      ),
    ),
  );
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? context.textSecondary),
      title: Text(title),
      onTap: onTap,
    );
  }
}

void _showSongInfo(BuildContext context, SongModel song, int playCount) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Song Info'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('Title', song.displayTitle),
            _InfoRow('Artist', song.displayArtist),
            _InfoRow('Album', song.displayAlbum),
            _InfoRow('Duration', song.duration.formatted),
            _InfoRow('Play Count', '$playCount plays'),
            if (song.size != null) _InfoRow('Size', song.size!.fileSize),
            if (song.path != null) _InfoRow('Path', song.path!, maxLines: 4),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final int maxLines;

  const _InfoRow(this.label, this.value, {this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 14),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
