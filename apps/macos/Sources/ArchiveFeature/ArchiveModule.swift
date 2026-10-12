import KaiwuCore
import KaiwuUI
import SwiftUI

public struct ArchiveModule: FeatureModule {
    private let service: any ArchiveServicing
    private let library: ArchiveLibraryService
    public init(
        service: any ArchiveServicing = ZipArchiveService(), library: ArchiveLibraryService = ArchiveLibraryService()
    ) {
        self.service = service
        self.library = library
    }
    public var descriptor: FeatureDescriptor {
        .init(id: "archive", title: "目录打包", symbol: "archivebox", summary: "生成干净的 ZIP 文件，过滤 macOS 元数据。")
    }
    public func makeView() -> AnyView { AnyView(ArchiveView(service: service, libraryService: library)) }
}
