import KaiwuCore
import KaiwuUI
import SwiftUI

struct ProxyView: View {
    @AppStorage(ToolPreferences.controllerEndpointKey) private var endpoint = ToolPreferences.defaultControllerEndpoint
    @State private var secret = ""
    @State private var operation = ToolTask<String>()

    var body: some View {
        FeaturePage("代理", subtitle: "连接本机核心，逐步构建原生代理工作台。") {
            GroupBox("Mihomo 控制器") {
                VStack(alignment: .leading, spacing: 16) {
                    TextField("控制器地址", text: $endpoint).disabled(operation.isRunning)
                    SecureField("Secret（仅本次保存在内存中）", text: $secret).disabled(operation.isRunning)
                    HStack {
                        Button("读取版本") { connect() }.buttonStyle(.borderedProminent).disabled(operation.isRunning)
                        if operation.isRunning {
                            ToolTaskControls(isCancelling: operation.isCancelling, cancel: operation.cancel)
                        }
                    }
                    if let result = operation.result { Text(result).font(.callout) }
                    if let error = operation.error { Text(error).foregroundStyle(.red) }
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
            operation.cancel(); secret = ""
        }
    }

    private func connect() {
        let address = endpoint
        let credential = secret
        operation.start {
            guard let url = URL(string: address) else { throw ProxyError.invalidEndpoint }
            let controller = try MihomoController(endpoint: url, secret: credential)
            let version = try await controller.version()
            try Task.checkCancellation()
            return "已连接，核心版本：\(version.version)"
        }
    }
}
