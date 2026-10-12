import KaiwuUI
import SwiftUI

struct NetworkView: View {
    let service: any NetworkDiagnosing
    @AppStorage("network.probeURL") private var probe = "https://www.baidu.com"
    @State private var report: NetworkReport?
    @State private var task: Task<Void, Never>?
    @State private var error: String?

    var body: some View {
        FeaturePage("网络诊断", subtitle: "先看清网络状态，再决定如何恢复。") {
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    TextField("HTTPS 测试地址", text: $probe).textFieldStyle(.roundedBorder)
                    Text("开始后将请求测试地址、查询 223.5.5.5，并读取本机网络状态。不会修改系统配置。")
                        .font(.callout).foregroundStyle(.secondary)
                    HStack {
                        Button("开始诊断", action: diagnose).buttonStyle(.borderedProminent).disabled(task != nil)
                        if task != nil {
                            ProgressView().controlSize(.small)
                            Button("取消") { task?.cancel() }
                        }
                    }
                }.padding(12)
            }
            if let error { Text(error).foregroundStyle(.red) }
            if let report {
                Text("检查时间：\(report.date.formatted(date: .abbreviated, time: .standard))").font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(report.findings) { finding in
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Label(finding.title, systemImage: symbol(finding.level)).font(.headline)
                            Text(finding.detail).font(.system(.callout, design: .monospaced))
                                .foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                        }.padding(8)
                    }
                }
                GroupBox("恢复建议") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(report.repairPlan.suggestions, id: \.self) { Text("• " + $0) }
                        Divider()
                        Text("自动修复将在签名的系统助手接入后开放；当前版本提供诊断和建议。")
                            .foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(8)
                }
            }
        }
        .onDisappear { task?.cancel() }
    }

    private func diagnose() {
        guard let url = URL(string: probe) else { error = "请输入有效的 HTTPS 地址。"; return }
        error = nil
        report = nil
        task = Task {
            defer { task = nil }
            do { report = try await service.diagnose(url: url) } catch is CancellationError { error = "诊断已取消。" } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func symbol(_ level: DiagnosticLevel) -> String {
        switch level {
        case .pass: "checkmark.circle"
        case .info: "info.circle"
        case .warning: "exclamationmark.triangle"
        case .failure: "xmark.circle"
        case .unavailable: "questionmark.circle"
        }
    }
}
