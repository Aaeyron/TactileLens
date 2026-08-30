import '../../database/history/history_database.dart';
import '../../database/materials/material_folder_database.dart';
import '../../utils/session_manager.dart';
import '../materials/material_service.dart';

class GuestDataService {
  const GuestDataService._();

  static Future<void> deleteGuestData() async {
    final bool isGuest = await SessionManager.isGuest();

    if (!isGuest) {
      throw const GuestDataDeletionException(
        'Guest data can only be deleted while Guest Mode is active.',
      );
    }

    final MaterialService materialService = MaterialService();

    try {
      // Delete history records and their managed image files.
      await HistoryDatabase.instance.deleteAllHistory();

      // Delete material records and their managed files.
      await materialService.deleteAllGuestMaterials();

      // Delete folders only after their materials have been removed.
      await MaterialFolderDatabase.instance.deleteAllFolders();

      // Remove the persistent guest identity last.
      await SessionManager.resetGuestProfile();
    } catch (error) {
      throw GuestDataDeletionException(
        'Guest data could not be completely deleted.',
        cause: error,
      );
    } finally {
      materialService.dispose();
    }
  }
}

class GuestDataDeletionException implements Exception {
  const GuestDataDeletionException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}
