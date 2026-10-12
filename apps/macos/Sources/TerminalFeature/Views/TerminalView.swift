import KaiwuCore
import KaiwuUI
import SwiftUI

struct TerminalView: View {
    let service: any TerminalServicing
    @State private var directory: URL?
    @State private var operation = ToolTask<String>()

    var body: some View {
        FeaturePage("终端", subtitle: "从工作目录开始，进入 Ghostty。") {
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Label(directory?.path ?? "选择一个工作目录", systemImage: "folder")
                    HStack {
                        Button("选择目录…") {
                            if let chosen = FilePanels.directory() { directory = chosen; operation.clear() }
                        }.disabled(operation.isRunning)
                        Button("用 Ghostty 打开") {
                            guard let directory else { return }
                            operation.start {
                                try Task.checkCancellation()
                                try await service.open(directory: directory)
                                return "已打开 Ghostty。"
                            }
                        }.buttonStyle(.borderedProminent).disabled(directory == nil || operation.isRunning)
                        if operation.isRunning {
                            ToolTaskControls(isCancelling: operation.isCancelling, cancel: operation.cancel)
                        }
                    }
                    Text("当前版本调用已安装的 Ghostty；已经打开的外部窗口不会因取消而关闭。")
                        .foregroundStyle(.secondary)
                    Link("下载 Ghostty", destination: URL(string: "https://ghostty.org/download")!)
                    if let message = operation.result { Text(message).font(.callout) }
                    if let error = operation.error { Text(error).foregroundStyle(.red) }
                }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
            }
        }.onDisappear { operation.cancel() }
    }
}
