import ArchiveFeature
import CloudServices
import KaiwuCore
import SwiftUI

struct SettingsView: View {
    let cloudAccount: any CloudAccountServicing
    let archiveLibrary: ArchiveLibraryService
    @AppStorage(ToolPreferences.probeURLKey) private var probe = ToolPreferences.defaultProbeURL
    @AppStorage(ToolPreferences.externalProbesKey) private var externalProbes = ToolPreferences.defaultExternalProbes
    @AppStorage(ToolPreferences.controllerEndpointKey) private var endpoint = ToolPreferences.defaultControllerEndpoint
    @AppStorage(ArchivePreset.preferenceKey) private var preset = ArchivePreset.standard
    @AppStorage(ArchiveLibraryService.historyEnabledKey) private var keepHistory = true
    @State private var cloudOperation = ToolTask<String>()
    @State private var clearOperation = ToolTask<String>()
    @State private var confirmClear = false

    var body: some View {
        TabView {
            Form {
                LabeledContent("应用", value: AppIdentity.displayName)
                Section("目录打包") {
                    Picker("默认规则", selection: $preset) {
                        ForEach(ArchivePreset.allCases, id: \.self) { Text($0.title).tag($0) }
                    }
                    Toggle("在本机保留最近 20 条成功记录", isOn: $keepHistory)
                    Text("记录含源目录与 ZIP 的文件书签，仅保存在本机。关闭记录不会清除已有历史。")
                        .font(.caption).foregroundStyle(.secondary)
                    Button("清除打包历史与书签…", role: .destructive) { confirmClear = true }
                        .disabled(clearOperation.isRunning)
                    if let message = clearOperation.result { Text(message).foregroundStyle(.secondary) }
                    if let error = clearOperation.error { Text(error).foregroundStyle(.red) }
                }
                Section("任务") {
                    Text("离开工具页面会取消该页任务。取消完成前不能重复启动；已保存的 ZIP 会保留。")
                        .foregroundStyle(.secondary)
                }
            }.tabItem { Label("通用", systemImage: "gearshape") }
            Form {
                Section("网络诊断") {
                    TextField("HTTPS 测试地址", text: $probe)
                    Toggle("执行外部 DNS 与 HTTPS 探测", isOn: $externalProbes)
                    Text("测试地址不接受凭证、查询参数或片段。诊断始终由你主动发起。")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Section("本机代理控制器") {
                    TextField("控制器地址", text: $endpoint)
                    Text("Secret 仅保留在当前代理页面内存中，退出页面清空。")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Button("恢复网络默认值") {
                    probe = ToolPreferences.defaultProbeURL
                    endpoint = ToolPreferences.defaultControllerEndpoint
                    externalProbes = ToolPreferences.defaultExternalProbes
                }
            }.tabItem { Label("网络", systemImage: "network") }
            Form {
                LabeledContent("CloudKit", value: cloudOperation.result ?? CloudAccountState.disabled.rawValue)
                Text("已预留云服务接口。完成开发者签名、iCloud 容器配置及同步实现后，可在此开启。")
                    .foregroundStyle(.secondary)
                Button("检查账户状态") {
                    cloudOperation.start { try await cloudAccount.accountState().rawValue }
                }.disabled(cloudOperation.isRunning)
                if let error = cloudOperation.error { Text(error).foregroundStyle(.red) }
            }.tabItem { Label("同步", systemImage: "icloud") }
        }
        .formStyle(.grouped).padding(16).frame(width: 580, height: 460)
        .confirmationDialog("清除本机打包历史与书签？源目录和 ZIP 文件会保留。", isPresented: $confirmClear) {
            Button("清除记录", role: .destructive) {
                clearOperation.start {
                    try await archiveLibrary.reset(); return "打包历史与书签已清除。"
                }
            }
        }
        .onDisappear {
            cloudOperation.cancel(); clearOperation.cancel()
        }
    }
}
