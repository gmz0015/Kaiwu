import KaiwuUI
import SwiftUI

struct ProxyView: View {
    @AppStorage("proxy.controllerEndpoint") private var endpoint = "http://127.0.0.1:9090"
    @State private var secret = ""
    @State private var result: String?
    @State private var task: Task<Void, Never>?

    var body: some View {
        FeaturePage("代理", subtitle: "连接本机核心，逐步构建原生代理工作台。") {
            GroupBox("Mihomo 控制器") {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("控制器地址", text: $endpoint)
                    SecureField("Secret（仅本次保存在内存中）", text: $secret)
                    HStack {
                        Button("读取版本") { connect() }.buttonStyle(.borderedProminent).disabled(task != nil)
                        if task != nil { ProgressView().controlSize(.small) }
                    }
                    if let result { Text(result).font(.callout) }
                    Text("请在现有代理应用中启用 external-controller。此操作仅读取版本，不会启动核心或切换系统代理。")
                        .foregroundStyle(.secondary)
                }.textFieldStyle(.roundedBorder).padding(12)
            }
            GroupBox("后续能力") {
                Text("订阅与配置管理、节点与规则、流量与连接、系统代理及 TUN 控制，将分别接入独立服务。")
                    .foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading).padding(12)
            }
        }
        .onDisappear {
            task?.cancel(); secret = ""
        }
    }

    private func connect() {
        result = nil
        task = Task {
            defer { task = nil }
            do {
                guard let url = URL(string: endpoint) else { throw ProxyError.invalidEndpoint }
                let controller = try MihomoController(endpoint: url, secret: secret)
                let version = try await controller.version()
                result = "已连接，核心版本：\(version.version)"
            } catch { result = error.localizedDescription }
        }
    }
}
