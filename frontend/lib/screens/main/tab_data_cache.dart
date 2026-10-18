import '../../models/history/history_model.dart';
import '../../models/materials/material_folder_model.dart';
import '../../models/materials/material_model.dart';

typedef HomeTabData = ({
  String displayName,
  String role,
  bool isGuest,
  List<MaterialModel> materials,
});

typedef MaterialsTabData = ({
  List<MaterialModel> materials,
  List<MaterialFolderModel> folders,
  bool isGuest,
});

typedef ProfileTabData = ({
  bool isGuest,
  String firstName,
  String lastName,
  String email,
  String role,
  String guestNickname,
});

/// The last successfully loaded data of each main tab, kept in memory only.
///
/// Tabs are rebuilt every time they are opened. On a return visit a tab
/// shows this data at once instead of a skeleton, then reloads in the
/// background as before. MainScreen owns the cache, so it is discarded on
/// logout or session exit, when MainScreen is removed.
class TabDataCache {
  HomeTabData? home;
  List<HistoryRecord>? history;
  MaterialsTabData? materials;
  ProfileTabData? profile;

  void clear() {
    home = null;
    history = null;
    materials = null;
    profile = null;
  }
}
