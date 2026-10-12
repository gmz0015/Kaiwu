import Foundation

/// 大量小文件时合并界面更新；阶段切换与阶段末尾的进度始终保留。
actor ArchiveProgressReporter {
    private let callback: @Sendable (ArchiveProgress) async -> Void
    private var lastUpdate = -Double.infinity
    private(set) var phase = ArchiveProgress.Phase.scanning

    init(callback: @escaping @Sendable (ArchiveProgress) async -> Void) { self.callback = callback }

    func send(_ progress: ArchiveProgress) async {
        let now = ProcessInfo.processInfo.systemUptime
        let changed = phase != progress.phase
        phase = progress.phase
        guard
            changed || now - lastUpdate >= 0.08
                || (progress.totalBytes > 0 && progress.completedBytes == progress.totalBytes)
        else { return }
        lastUpdate = now
        await callback(progress)
    }
}
