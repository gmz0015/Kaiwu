import KaiwuCore
import KaiwuUI
import SwiftUI

public struct NetworkModule: FeatureModule {
    private let service: any NetworkDiagnosing
    public init(service: any NetworkDiagnosing = SystemNetworkDiagnostics()) { self.service = service }
    public var descriptor: FeatureDescriptor {
        .init(id: "network", title: "网络诊断", symbol: "network", summary: "检查 DNS、出口路由、TUN 和网络连通性。")
    }
    public func makeView() -> AnyView { AnyView(NetworkView(service: service)) }
}
