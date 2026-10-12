import SwiftUI

struct ArchiveProgressView: View {
    let progress: ArchiveProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(progress.phase.rawValue).font(.headline)
            if [.copying, .saving].contains(progress.phase), progress.totalBytes > 0 {
                ProgressView(value: Double(progress.completedBytes), total: Double(progress.totalBytes))
                Text("\(size(progress.completedBytes)) / \(size(progress.totalBytes))")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            } else {
                Text(progress.phase == .compressing ? "压缩时长取决于文件内容，请稍候。" : "正在检查文件，请稍候。")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text(
                "\(progress.fileCount) 个\(progress.phase == .scanning ? "条目已发现" : "文件已准备") · 跳过 \(progress.skippedCount) 个条目"
            )
            .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func size(_ bytes: Int64) -> String { ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file) }
}
