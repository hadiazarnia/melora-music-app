import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/melora_search_bar.dart';
import '../../../shared/widgets/song_tile.dart';
import '../../../shared/widgets/melora_bottom_sheet.dart';
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
  String _searchQuery = '';
  String _sortBy = 'date'; // date, title, artist, size

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          // ─── Header ─────────────────────────────────────
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
                // Sort button
                PopupMenuButton<String>(
                  onSelected: (val) => setState(() => _sortBy = val),
                  icon: Icon(
                    Iconsax.sort,
                    color: context.textSecondary,
                    size: 22,
                  ),
                  itemBuilder: (_) => [
                    _sortItem('date', 'Date Added'),
                    _sortItem('title', 'Title'),
                    _sortItem('artist', 'Artist'),
                    _sortItem('size', 'Size'),
                  ],
                ),
                // Filter button
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Iconsax.filter,
                    color: context.textSecondary,
                    size: 22,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          // ─── Search ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MeloraDimens.pagePadding,
            ),
            child: MeloraSearchBar(
              controller: _searchController,
              hintText: 'Search offline music...',
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms),

          const SizedBox(height: MeloraDimens.lg),

          // ─── Tab Bar ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MeloraDimens.pagePadding,
            ),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: context.isDark
                    ? MeloraColors.darkSurfaceLight
                    : MeloraColors.lightSurfaceLight,
                borderRadius: BorderRadius.circular(MeloraDimens.radiusFull),
                border: Border.all(color: context.borderColor, width: 0.5),
              ),
              child: TabBar(
                controller: _tabController,
                labelPadding: EdgeInsets.zero,
                padding: const EdgeInsets.all(3),
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(MeloraDimens.radiusFull),
                  color: MeloraColors.primary,
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
                tabs: const [
                  Tab(text: 'Folders'),
                  Tab(text: 'Songs'),
                  Tab(text: 'Albums'),
                  Tab(text: 'Favorites'),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 300.ms),

          const SizedBox(height: MeloraDimens.md),

          // ─── Tab Content ────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _FoldersTab(searchQuery: _searchQuery),
                _SongsTab(searchQuery: _searchQuery, sortBy: _sortBy),
                _AlbumsTab(searchQuery: _searchQuery),
                _FavoritesTab(searchQuery: _searchQuery),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _sortItem(String value, String label) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          if (_sortBy == value)
            const Icon(Icons.check, size: 18, color: MeloraColors.primary)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  FOLDERS TAB
// ═══════════════════════════════════════════════════════════
class _FoldersTab extends ConsumerWidget {
  final String searchQuery;
  const _FoldersTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersProvider);

    return foldersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: MeloraColors.primary),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.folder_cross, size: 48, color: context.textTertiary),
            const SizedBox(height: MeloraDimens.md),
            Text('No folders found', style: context.textTheme.bodyMedium),
          ],
        ),
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
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.folder_2, size: 48, color: context.textTertiary),
                const SizedBox(height: MeloraDimens.md),
                Text(
                  'No music folders found',
                  style: context.textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 180),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final folder = filtered[i];
            return ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(MeloraDimens.radiusSm),
                  color: MeloraColors.primary.withOpacity(0.1),
                ),
                child: const Icon(
                  Iconsax.folder,
                  color: MeloraColors.primary,
                  size: 24,
                ),
              ),
              title: Text(folder.name),
              subtitle: Text(
                '${folder.songCount} songs • ${folder.path}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(
                Iconsax.arrow_right_3,
                size: 18,
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
            ).animate().fadeIn(
              delay: Duration(milliseconds: 40 * i),
              duration: 300.ms,
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  SONGS TAB
// ═══════════════════════════════════════════════════════════
class _SongsTab extends ConsumerWidget {
  final String searchQuery;
  final String sortBy;
  const _SongsTab({required this.searchQuery, required this.sortBy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(allSongsProvider);

    return songsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: MeloraColors.primary),
      ),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.music, size: 48, color: context.textTertiary),
            const SizedBox(height: MeloraDimens.md),
            Text('No songs found', style: context.textTheme.bodyMedium),
            const SizedBox(height: MeloraDimens.sm),
            Text(
              'Grant storage permission to scan music',
              style: context.textTheme.bodySmall,
            ),
          ],
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
                        ),
                  )
                  .toList();

        // Sort
        switch (sortBy) {
          case 'title':
            filtered.sort(
              (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
            );
            break;
          case 'artist':
            filtered.sort(
              (a, b) =>
                  a.artist.toLowerCase().compareTo(b.artist.toLowerCase()),
            );
            break;
          case 'size':
            filtered.sort((a, b) => (b.size ?? 0).compareTo(a.size ?? 0));
            break;
          default:
            break;
        }

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.music_dashboard,
                  size: 48,
                  color: context.textTertiary,
                ),
                const SizedBox(height: MeloraDimens.md),
                Text('No songs found', style: context.textTheme.bodyMedium),
              ],
            ),
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
                    style: context.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  // Shuffle all
                  TextButton.icon(
                    onPressed: () {
                      final handler = ref.read(audioHandlerProvider);
                      handler.loadPlaylist(filtered);
                      handler.toggleShuffle();
                    },
                    icon: const Icon(Iconsax.shuffle, size: 16),
                    label: const Text('Shuffle All'),
                    style: TextButton.styleFrom(
                      foregroundColor: MeloraColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 180),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final song = filtered[i];
                  return SongTile(
                    song: song,
                    index: i,
                    showSize: true,
                    onTap: () {
                      ref
                          .read(audioHandlerProvider)
                          .playSong(song, queue: filtered);
                    },
                    onLongPress: () {
                      MeloraBottomSheet.showSongMenu(
                        context: context,
                        songTitle: song.displayTitle,
                        artist: song.displayArtist,
                        isFavorite: song.isFavorite,
                      );
                    },
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
//  ALBUMS TAB
// ═══════════════════════════════════════════════════════════
class _AlbumsTab extends ConsumerWidget {
  final String searchQuery;
  const _AlbumsTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsync = ref.watch(albumsProvider);

    return albumsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: MeloraColors.primary),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (albums) {
        final filtered = searchQuery.isEmpty
            ? albums
            : albums
                  .where(
                    (a) => a.name.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ),
                  )
                  .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.music_filter,
                  size: 48,
                  color: context.textTertiary,
                ),
                const SizedBox(height: MeloraDimens.md),
                Text('No albums found', style: context.textTheme.bodyMedium),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            MeloraDimens.pagePadding,
            0,
            MeloraDimens.pagePadding,
            180,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.78,
            crossAxisSpacing: MeloraDimens.md,
            mainAxisSpacing: MeloraDimens.md,
          ),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final album = filtered[i];
            return GestureDetector(
              onTap: () {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          MeloraDimens.radiusMd,
                        ),
                        gradient: LinearGradient(
                          colors: [
                            MeloraColors.primary.withOpacity(0.2),
                            MeloraColors.secondary.withOpacity(0.2),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Iconsax.music_square,
                          size: 40,
                          color: context.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: MeloraDimens.sm),
                  Text(
                    album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleSmall?.copyWith(
                      color: context.textPrimary,
                    ),
                  ),
                  Text(
                    '${album.artist} • ${album.songCount} songs',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ),
            ).animate().fadeIn(
              delay: Duration(milliseconds: 50 * i),
              duration: 300.ms,
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
  const _FavoritesTab({required this.searchQuery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favAsync = ref.watch(favoriteSongsProvider);

    return favAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: MeloraColors.primary),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (songs) {
        final filtered = searchQuery.isEmpty
            ? songs
            : songs
                  .where(
                    (s) => s.title.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ),
                  )
                  .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Iconsax.heart, size: 48, color: context.textTertiary),
                const SizedBox(height: MeloraDimens.md),
                Text('No favorites yet', style: context.textTheme.bodyMedium),
                const SizedBox(height: MeloraDimens.xs),
                Text(
                  'Long press a song to add to favorites',
                  style: context.textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 180),
          itemCount: filtered.length,
          itemBuilder: (ctx, i) {
            final song = filtered[i];
            return SongTile(
              song: song,
              index: i,
              onTap: () {
                ref.read(audioHandlerProvider).playSong(song, queue: filtered);
              },
              onLongPress: () {
                MeloraBottomSheet.showSongMenu(
                  context: context,
                  songTitle: song.displayTitle,
                  artist: song.displayArtist,
                  isFavorite: true,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(folderName),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
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
            padding: const EdgeInsets.only(bottom: 180),
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
                onLongPress: () {
                  MeloraBottomSheet.showSongMenu(
                    context: context,
                    songTitle: song.displayTitle,
                    artist: song.displayArtist,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
