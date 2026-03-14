import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/knowledge_base.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/cache_manager.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/debug_logger.dart';

/// Cache keys for knowledge base data.
const String _basesKey = 'knowledge_bases';
String _itemsKey(String baseId) => 'knowledge_items:$baseId';

/// TTL for knowledge cache entries.
const Duration _knowledgeCacheTtl = Duration(minutes: 10);

/// Centralized cache manager for knowledge base data.
///
/// Uses the shared [CacheManager] pattern for TTL and LRU eviction.
class KnowledgeCacheManager {
  static final KnowledgeCacheManager _instance =
      KnowledgeCacheManager._internal();
  factory KnowledgeCacheManager() => _instance;
  KnowledgeCacheManager._internal();

  final CacheManager _cache = CacheManager(
    defaultTtl: _knowledgeCacheTtl,
    maxEntries: 64,
  );

  /// Returns cached knowledge bases, or null if not cached.
  List<KnowledgeBase>? getCachedBases() {
    final (hit: hit, value: bases) =
        _cache.lookup<List<KnowledgeBase>>(_basesKey);
    if (hit) {
      DebugLogger.log('cache-hit', scope: 'knowledge/bases');
    }
    return hit ? bases : null;
  }

  /// Caches knowledge bases.
  void cacheBases(List<KnowledgeBase> bases) {
    _cache.write<List<KnowledgeBase>>(_basesKey, bases);
    DebugLogger.log(
      'cache-write',
      scope: 'knowledge/bases',
      data: {'count': bases.length},
    );
  }

  /// Returns cached items for a knowledge base, or null if not cached.
  List<KnowledgeBaseItem>? getCachedItems(String baseId) {
    final (hit: hit, value: items) =
        _cache.lookup<List<KnowledgeBaseItem>>(_itemsKey(baseId));
    if (hit) {
      DebugLogger.log('cache-hit', scope: 'knowledge/items', data: {'baseId': baseId});
    }
    return hit ? items : null;
  }

  /// Caches items for a knowledge base.
  void cacheItems(String baseId, List<KnowledgeBaseItem> items) {
    _cache.write<List<KnowledgeBaseItem>>(_itemsKey(baseId), items);
    DebugLogger.log(
      'cache-write',
      scope: 'knowledge/items',
      data: {'baseId': baseId, 'count': items.length},
    );
  }

  /// Clears all knowledge cache entries.
  void clear() {
    _cache.invalidateMatching((key) => key.startsWith('knowledge'));
    DebugLogger.log('cache-clear', scope: 'knowledge');
  }

  /// Returns cache statistics for debugging.
  Map<String, dynamic> stats() => _cache.stats();
}

/// State for the knowledge cache provider.
class KnowledgeCacheState {
  const KnowledgeCacheState({
    this.bases = const <KnowledgeBase>[],
    this.items = const <String, List<KnowledgeBaseItem>>{},
    this.isLoading = false,
  });

  final List<KnowledgeBase> bases;
  final Map<String, List<KnowledgeBaseItem>> items;
  final bool isLoading;

  KnowledgeCacheState copyWith({
    List<KnowledgeBase>? bases,
    Map<String, List<KnowledgeBaseItem>>? items,
    bool? isLoading,
  }) {
    return KnowledgeCacheState(
      bases: bases ?? this.bases,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier that wraps [KnowledgeCacheManager] with Riverpod reactivity.
class KnowledgeCacheNotifier extends Notifier<KnowledgeCacheState> {
  final _cacheManager = KnowledgeCacheManager();

  @override
  KnowledgeCacheState build() {
    // Initialize from cache if available
    final cachedBases = _cacheManager.getCachedBases();
    if (cachedBases != null && cachedBases.isNotEmpty) {
      return KnowledgeCacheState(bases: cachedBases);
    }
    return const KnowledgeCacheState();
  }

  ApiService? get _api => ref.read(apiServiceProvider);

  Future<void> ensureBases() async {
    // Check if already loaded in state
    if (state.bases.isNotEmpty) return;

    // Check cache
    final cached = _cacheManager.getCachedBases();
    if (cached != null && cached.isNotEmpty) {
      state = state.copyWith(bases: cached);
      return;
    }

    if (_api == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final bases = await _api!.getKnowledgeBases();
      _cacheManager.cacheBases(bases);
      state = state.copyWith(bases: bases, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> fetchItemsForBase(String baseId) async {
    // Check if already in state
    if (state.items.containsKey(baseId)) return;

    // Check cache
    final cached = _cacheManager.getCachedItems(baseId);
    if (cached != null) {
      final next = Map<String, List<KnowledgeBaseItem>>.from(state.items);
      next[baseId] = cached;
      state = state.copyWith(items: next);
      return;
    }

    if (_api == null) return;

    final next = Map<String, List<KnowledgeBaseItem>>.from(state.items);
    try {
      final items = await _api!.getKnowledgeBaseItems(baseId);
      _cacheManager.cacheItems(baseId, items);
      next[baseId] = items;
    } catch (_) {
      next[baseId] = const <KnowledgeBaseItem>[];
    }
    state = state.copyWith(items: next);
  }

  /// Clears both in-memory state and persistent cache.
  void clearCache() {
    _cacheManager.clear();
    state = const KnowledgeCacheState();
  }
}

final knowledgeCacheProvider =
    NotifierProvider<KnowledgeCacheNotifier, KnowledgeCacheState>(
  KnowledgeCacheNotifier.new,
);
