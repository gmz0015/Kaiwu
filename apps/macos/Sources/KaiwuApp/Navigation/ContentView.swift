import KaiwuUI
import SwiftUI

struct ContentView: View {
    let modules: [any FeatureModule]
    @SceneStorage("navigation.selection") private var selection: String = "overview"

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("工作台", systemImage: "square.grid.2x2").tag("overview")
                Section("工具") {
                    ForEach(modules, id: \.descriptor.id) { module in
                        Label(module.descriptor.title, systemImage: module.descriptor.symbol)
                            .tag(module.descriptor.id)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle(AppIdentity.displayName)
            .navigationSplitViewColumnWidth(min: 180, ideal: 210, max: 260)
            .safeAreaInset(edge: .bottom) {
                HStack {
                    SettingsLink(); Spacer(); Text("开发预览").font(.caption).foregroundStyle(.secondary)
                }.padding()
            }
        } detail: {
            if let module = modules.first(where: { $0.descriptor.id == selection }) {
                module.makeView().id(selection).navigationTitle(module.descriptor.title)
            } else {
                OverviewView(modules: modules) { selection = $0 }
            }
        }
    }
}
