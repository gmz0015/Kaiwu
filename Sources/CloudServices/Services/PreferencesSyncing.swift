import Foundation

/// 后续适配器负责冲突处理、变更令牌、重试与账户切换。
public protocol PreferencesSyncing: Sendable {
    func fetch() async throws -> SyncedPreferences?
    func save(_ preferences: SyncedPreferences) async throws
}
