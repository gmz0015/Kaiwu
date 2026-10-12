import CloudServices
import SwiftUI

struct SettingsView: View {
    let cloudAccount: any CloudAccountServicing
    @State private var cloudState = CloudAccountState.disabled.rawValue

    var body: some View {
        TabView {
            Form {
                LabeledContent("应用", value: AppIdentity.displayName)
                LabeledContent("最低系统版本", value: "macOS 14")
                Text("网络与代理工具的探测参数保存在本机。Secret 仅保留在当前页面内存中。")
                    .foregroundStyle(.secondary)
            }.tabItem { Label("通用", systemImage: "gearshape") }
            Form {
                LabeledContent("CloudKit", value: cloudState)
                Text("已预留云服务接口。完成开发者签名、iCloud 容器配置及同步实现后，可在此开启。")
                    .foregroundStyle(.secondary)
                Button("检查账户状态") {
                    Task {
                        do { cloudState = try await cloudAccount.accountState().rawValue } catch {
                            cloudState = error.localizedDescription
                        }
                    }
                }
            }.tabItem { Label("同步", systemImage: "icloud") }
        }
        .formStyle(.grouped)
        .padding(16)
        .frame(width: 520, height: 300)
    }
}
