import Foundation

/// Photos the user chose to keep: swiped right, favorited, or filed to an
/// album. Persisted so the home screen can list them across sessions.
final class KeptStore {
    private let key = "keptAssetIDs"
    private let migratedKey = "keptAssetIDsMigrated"
    private let defaults = UserDefaults.standard
    private(set) var ids: Set<String>

    init() { ids = Set(defaults.stringArray(forKey: key) ?? []) }

    /// Builds before this store only saved "reviewed", so kept photos from
    /// then are backfilled once, on the first launch that has this store.
    var didMigrate: Bool { defaults.bool(forKey: migratedKey) }
    func markMigrated() { defaults.set(true, forKey: migratedKey) }

    func add(_ id: String) { ids.insert(id); persist() }
    func add(_ new: Set<String>) { ids.formUnion(new); persist() }
    func remove(_ id: String) { ids.remove(id); persist() }
    func clear() { ids.removeAll(); persist() }

    /// Forget photos no longer in the library.
    func drop(notIn existing: Set<String>) {
        guard !ids.isSubset(of: existing) else { return }
        ids.formIntersection(existing); persist()
    }

    private func persist() { defaults.set(Array(ids), forKey: key) }
}
