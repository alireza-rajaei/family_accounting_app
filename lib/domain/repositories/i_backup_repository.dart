abstract class IBackupRepository {
  Future<String> exportJson();
  Future<void> importJson(Map<String, dynamic> json);
}
