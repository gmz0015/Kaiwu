import KaiwuUI
import SwiftUI

struct OverviewView: View {
    let modules: [any FeatureModule]
    let select: (String) -> Void

    var body: some View {
        FeaturePage("你的日常工作台", subtitle: "终端、文件与网络工具，汇集在一个原生 Mac 应用中。") {
            VStack(spacing: 0) {
                ForEach(modules, id: \.descriptor.id) { module in
                    Button {
                        select(module.descriptor.id)
                    } label: {
                        HStack(spacing: 18) {
                            Image(systemName: module.descriptor.symbol).font(.title2)
                                .foregroundStyle(.tint).frame(width: 36)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(module.descriptor.title).font(.headline)
                                Text(module.descriptor.summary).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                        }.padding(.vertical, 22).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                    Divider()
                }
            }
            Label("基础功能可本地运行；网络探测由你主动发起。", systemImage: "desktopcomputer")
                .font(.callout).foregroundStyle(.secondary)
        }.navigationTitle("工作台")
    }
}
