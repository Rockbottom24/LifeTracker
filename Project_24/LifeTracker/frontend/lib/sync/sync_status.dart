enum SyncStatus {
  pendingCreate,
  pendingUpdate,
  pendingDelete,
  synced,
  failed;

  bool get isPending =>
      this == SyncStatus.pendingCreate ||
      this == SyncStatus.pendingUpdate ||
      this == SyncStatus.pendingDelete;

  static SyncStatus fromName(String? value) {
    return SyncStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => SyncStatus.synced,
    );
  }
}
