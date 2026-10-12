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
    let cloudAccount: any CloudAccountServicing

    static func live() -> AppServices {
        let runner = ProcessRunner()
        return AppServices(
            modules: [
                TerminalModule(),
                ArchiveModule(service: ZipArchiveService(runner: runner)),
                NetworkModule(service: SystemNetworkDiagnostics(runner: runner)),
                ProxyModule(),
            ], cloudAccount: DisabledCloudAccountService())
    }
}
