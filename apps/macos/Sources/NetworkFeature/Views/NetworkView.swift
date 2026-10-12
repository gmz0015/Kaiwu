import KaiwuCore
import KaiwuUI
import SwiftUI

struct NetworkView: View {
    let service: any NetworkDiagnosing
    @AppStorage(ToolPreferences.probeURLKey) private var probe = ToolPreferences.defaultProbeURL
    @AppStorage(ToolPreferences.externalProbesKey) private var externalProbes = ToolPreferences.defaultExternalProbes
    @State private var operation = ToolTask<NetworkReport>()
    @State private var inputError: String?
    @State private var exportText: String?

    var body: some View {
        FeaturePage("网络诊断", subtitle: "先看清网络状态，再决定如何恢复。") {
            GroupBox {
                VStack(alignment: .leading, spacing: 14) {
                    TextField("HTTPS 测试地址", text: $probe).textFieldStyle(.roundedBorder)
                        .disabled(operation.isRunning || !externalProbes)
                    Toggle("执行外部 DNS 与 HTTPS 探测", isOn: $externalProbes).disabled(operation.isRunning)
                    Text(
                        externalProbes
                            ? "将请求测试地址、查询 223.5.5.5，并读取网络配置、检查已配置的本机代理端口和 PAC。"
                            : "仅读取本机网络配置，并检查已配置的回环代理端口和 PAC，不发送外部 DNS 或 HTTPS 探测。"
                    )
                    .font(.callout).foregroundStyle(.secondary)
                    Text("不修改系统配置，不执行 PAC 脚本。离开页面会取消诊断。")
                        .font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Button("开始诊断", action: diagnose).buttonStyle(.borderedProminent).disabled(operation.isRunning)
                        if operation.isRunning {
                            ToolTaskControls(isCancelling: operation.isCancelling, cancel: operation.cancel)
                        }
                    }
                }.padding(12)
            }
            if let error = inputError ?? operation.error { Text(error).foregroundStyle(.red) }
            if let report = operation.result {
                HStack {
                    Text("检查时间：\(report.date.formatted(date: .abbreviated, time: .standard))")
                        .font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Button("预览脱敏摘要…") { exportText = NetworkReportExport.text(report) }
                }
                summary(report)
                ForEach(DiagnosticCategory.allCases, id: \.self) { category in
                    let findings = report.findings.filter { $0.category == category }
                    if !findings.isEmpty {
                        GroupBox(category.rawValue) {
                            VStack(alignment: .leading, spacing: 14) {
                                ForEach(findings) { finding in
                                    DisclosureGroup {
                                        Text(finding.detail).font(.system(.callout, design: .monospaced))
                                            .foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.vertical, 8)
                                    } label: {
                                        HStack {
                                            Label(finding.title, systemImage: symbol(finding.level))
                                            Spacer()
                                            Text(finding.level.title).font(.caption).foregroundStyle(
                                                color(finding.level))
                                        }
                                    }
                                }
                            }.padding(8)
                        }
                    }
                }
                GroupBox("恢复建议") {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(report.repairPlan.suggestions, id: \.self) { Text("• " + $0) }
                        Divider()
                        Text("自动修复将在签名的系统助手接入后开放。")
                            .foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(8)
                }
            }
        }
        .onDisappear { operation.cancel() }
        .sheet(isPresented: Binding(get: { exportText != nil }, set: { if !$0 { exportText = nil } })) {
            if let exportText { NetworkExportView(text: exportText) }
        }
    }

    private func summary(_ report: NetworkReport) -> some View {
        let warnings = report.findings.filter { [.warning, .failure].contains($0.level) }.count
        let unavailable = report.findings.filter { $0.level == .unavailable }.count
        return Label(
            "\(report.findings.count) 项检查 · \(warnings) 项需留意 · \(unavailable) 项未取得结果",
            systemImage: "list.bullet.clipboard"
        )
        .font(.callout)
    }

    private func diagnose() {
        let value =
            externalProbes ? probe.trimmingCharacters(in: .whitespacesAndNewlines) : ToolPreferences.defaultProbeURL
        guard let url = URL(string: value) else { inputError = "请输入有效的 HTTPS 地址。"; return }
        inputError = nil
        let runExternal = externalProbes
        operation.start { try await service.diagnose(url: url, externalProbes: runExternal) }
    }

    private func symbol(_ level: DiagnosticLevel) -> String {
        switch level {
        case .pass: "checkmark.circle"
        case .info: "info.circle"
        case .warning: "exclamationmark.triangle"
        case .failure: "xmark.circle"
        case .unavailable: "questionmark.circle"
        case .skipped: "minus.circle"
        }
    }

    private func color(_ level: DiagnosticLevel) -> Color {
        switch level {
        case .pass: .green
        case .warning: .orange
        case .failure: .red
        case .info, .unavailable, .skipped: .secondary
        }
    }
}
