import 'package:mdmpi_mobile_app/base/utils/helpers/network_manager.dart';
import 'package:mdmpi_mobile_app/base/utils/logger.dart';

typedef AsyncListLoader<T> = Future<List<T>> Function();
typedef AsyncListCache<T> = Future<void> Function(List<T> items);

class OfflineDataLoader {
  const OfflineDataLoader._();

  static Future<List<T>> loadLocalThenRemoteIfOnline<T>({
    required AsyncListLoader<T> loadLocal,
    required AsyncListLoader<T> loadRemote,
    AsyncListCache<T>? cacheRemote,
    required String sourceName,
    bool forceRemote = false,
  }) async {
    if (!forceRemote) {
      final localItems = await _tryLoadLocal(loadLocal, sourceName);
      if (localItems.isNotEmpty) {
        return localItems;
      }
    }

    final isConnected = await NetworkManager.instance.isConnected();
    if (!isConnected) {
      return forceRemote ? await _tryLoadLocal(loadLocal, sourceName) : <T>[];
    }

    try {
      final remoteItems = await loadRemote();
      if (cacheRemote != null) {
        try {
          await cacheRemote(remoteItems);
        } catch (e) {
          logDebug('$sourceName: Failed to cache remote data: $e');
        }
      }
      return remoteItems;
    } catch (e, st) {
      logDebug('$sourceName: Remote load failed: $e\n$st');
      final localItems = await _tryLoadLocal(loadLocal, sourceName);
      if (localItems.isNotEmpty) {
        return localItems;
      }
      rethrow;
    }
  }

  static Future<List<T>> _tryLoadLocal<T>(
    AsyncListLoader<T> loadLocal,
    String sourceName,
  ) async {
    try {
      return await loadLocal();
    } catch (e) {
      logDebug('$sourceName: Local load failed: $e');
      return <T>[];
    }
  }
}
