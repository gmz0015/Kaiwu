import AppKit
import KaiwuUI
import SwiftUI

struct ArchiveView: View {
    let service: any ArchiveServicing
    @State private var source: URL?
    @State private var excludeDevelopment = false
    @State private var task: Task<Void, Never>?
    @State private var receipt: ArchiveReceipt?
    @State private var error: String?

    var body: some View {
        FeaturePage("目录打包", subtitle: "选择目录，导出便于分享的 ZIP。") {
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Label(source?.path ?? "尚未选择目录", systemImage: "folder")
                        .lineLimit(3).frame(maxWidth: .infinity, alignment: .leading)
                    Button("选择目录…") {
                        if let chosen = FilePanels.directory() { source = chosen; receipt = nil; error = nil }
                    }.disabled(task != nil)
                    Divider()
                    Text("自动排除 .DS_Store、._*、__MACOSX 等元数据；跳过符号链接。")
                        .font(.callout).foregroundStyle(.secondary)
                    Toggle("同时排除 .git、.build、node_modules、DerivedData", isOn: $excludeDevelopment)
                        .disabled(task != nil)
                    HStack {
                        Button("导出 ZIP…", action: export).buttonStyle(.borderedProminent)
                            .disabled(source == nil || task != nil)
                        if task != nil {
                            ProgressView().controlSize(.small)
                            Button("取消") { task?.cancel() }
                        }
                    }
                }.padding(12)
            }
            if let receipt {
                Label("已打包 \(receipt.fileCount) 个文件，跳过 \(receipt.skippedCount) 个条目。", systemImage: "checkmark.circle")
                Button("在 Finder 中显示") { NSWorkspace.shared.activateFileViewerSelecting([receipt.destination]) }
            }
            if let error { Text(error).foregroundStyle(.red) }
        }
        .onDisappear { task?.cancel() }
    }

    private func export() {
        guard let source, let destination = FilePanels.archive(named: source.lastPathComponent) else { return }
        error = nil
        receipt = nil
        let policy = ArchivePolicy(excludeDevelopmentArtifacts: excludeDevelopment)
        task = Task {
            defer { task = nil }
            do {
                receipt = try await service.create(.init(source: source, destination: destination, policy: policy))
            } catch is CancellationError { error = "打包已取消。" } catch { self.error = error.localizedDescription }
        }
    }
}
