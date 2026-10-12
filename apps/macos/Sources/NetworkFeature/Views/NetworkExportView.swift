import KaiwuCore
import KaiwuUI
import SwiftUI

struct NetworkExportView: View {
    let text: String
    @Environment(\.dismiss) private var dismiss
    @State private var operation = ToolTask<String>()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("脱敏摘要预览").font(.title2.bold())
            Text("下方内容将原样保存。详细证据仅留在诊断页，不包含在导出文件中。")
                .foregroundStyle(.secondary)
            ScrollView {
                Text(text).font(.system(.callout, design: .monospaced)).textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }.frame(minHeight: 240)
            if let error = operation.error { Text(error).foregroundStyle(.red) }
            if let result = operation.result { Label(result, systemImage: "checkmark.circle") }
            HStack {
                Button("关闭") { dismiss() }.keyboardShortcut(.cancelAction).disabled(operation.isRunning)
                Spacer()
                Button("保存文本…") {
                    guard let url = FilePanels.text(named: "Kaiwu-网络诊断摘要.txt") else { return }
                    operation.start {
                        try await NetworkReportWriter().write(text, to: url); return "摘要已保存。"
                    }
                }.buttonStyle(.borderedProminent).disabled(operation.isRunning)
            }
        }.padding(24).frame(width: 640, height: 520)
            .interactiveDismissDisabled(operation.isRunning)
            .onDisappear { operation.cancel() }
    }
}
