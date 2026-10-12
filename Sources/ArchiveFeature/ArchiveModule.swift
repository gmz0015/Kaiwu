import KaiwuCore
import KaiwuUI
import SwiftUI

public struct ArchiveModule: FeatureModule {
    private let service: any ArchiveServicing
    public init(service: any ArchiveServicing = ZipArchiveService()) { self.service = service }
    public var descriptor: FeatureDescriptor {
        .init(id: "archive", title: "目录打包", symbol: "archivebox", summary: "生成干净的 ZIP 文件，过滤 macOS 元数据。")
    }
    public func makeView() -> AnyView { AnyView(ArchiveView(service: service)) }
}
