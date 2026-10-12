import KaiwuCore
import KaiwuUI
import SwiftUI

public struct TerminalModule: FeatureModule {
    private let service: any TerminalServicing
    public init(service: any TerminalServicing = GhosttyLauncher()) { self.service = service }
    public var descriptor: FeatureDescriptor {
        .init(id: "terminal", title: "终端", symbol: "terminal", summary: "在选定目录中打开 Ghostty，预留内嵌终端。")
    }
    public func makeView() -> AnyView { AnyView(TerminalView(service: service)) }
}
