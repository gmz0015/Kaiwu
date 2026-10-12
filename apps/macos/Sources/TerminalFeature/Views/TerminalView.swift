import KaiwuUI
import SwiftUI

struct TerminalView: View {
    let service: any TerminalServicing
    @State private var directory: URL?
    @State private var message: String?
    @State private var opening = false

    var body: some View {
        FeaturePage("终端", subtitle: "从工作目录开始，进入 Ghostty。") {
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Label(directory?.path ?? "选择一个工作目录", systemImage: "folder")
                    HStack {
                        Button("选择目录…") { if let chosen = FilePanels.directory() { directory = chosen } }
                        Button("用 Ghostty 打开") {
                            guard let directory else { return }
                            opening = true
                            Task {
                                defer { opening = false }
                                do { try await service.open(directory: directory); message = "已打开 Ghostty。" } catch {
                                    message = error.localizedDescription
                                }
                            }
                        }.buttonStyle(.borderedProminent).disabled(directory == nil || opening)
                    }
                    Text("当前版本调用已安装的 Ghostty。应用内的终端面板将在后续接入。")
                        .foregroundStyle(.secondary)
                    Link("下载 Ghostty", destination: URL(string: "https://ghostty.org/download")!)
                    if let message { Text(message).font(.callout) }
                }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
