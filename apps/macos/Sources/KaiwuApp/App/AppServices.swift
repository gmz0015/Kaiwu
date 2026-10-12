import ArchiveFeature
import CloudServices
import KaiwuCore
import KaiwuUI
import NetworkFeature
import ProxyFeature
import TerminalFeature

@MainActor
struct AppServices {
    let modules: [any FeatureModule]
    let archiveLibrary: ArchiveLibraryService
    let cloudAccount: any CloudAccountServicing

    static func live() -> AppServices {
        let runner = ProcessRunner()
        let archiveLibrary = ArchiveLibraryService()
        return AppServices(
            modules: [
                TerminalModule(),
                ArchiveModule(service: ZipArchiveService(runner: runner), library: archiveLibrary),
                NetworkModule(service: SystemNetworkDiagnostics(runner: runner)),
                ProxyModule(),
            ], archiveLibrary: archiveLibrary, cloudAccount: DisabledCloudAccountService())
    }
}
