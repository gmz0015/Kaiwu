import KaiwuCore
import KaiwuUI
import SwiftUI

public struct ProxyModule: FeatureModule {
    public init() {}
    public var descriptor: FeatureDescriptor {
        .init(
            id: "proxy", title: "代理", symbol: "point.3.connected.trianglepath.dotted",
            summary: "连接本机 Mihomo 控制器，读取核心版本。")
    }
    public func makeView() -> AnyView { AnyView(ProxyView()) }
}
