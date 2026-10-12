import Foundation
import ProxyFeature
import Testing

@Test func controllerRejectsRemoteAndAmbiguousEndpoints() throws {
    for address in [
        "http://example.com:9090", "http://127.0.0.1.evil.com:9090", "http://localhost:9090",
        "http://user:pass@127.0.0.1:9090", "http://127.0.0.1:9090/?token=x", "http://127.0.0.1:9090/path",
        "http://127.0.0.1:9090/#fragment", "http://127.0.0.1:0", "http://127.0.0.1",
    ] {
        #expect(throws: ProxyError.self) { try MihomoController(endpoint: URL(string: address)!) }
    }
}

@Test func secretGoesOnlyIntoTheAuthorizationHeader() throws {
    let controller = try MihomoController(endpoint: URL(string: "http://127.0.0.1:9090")!, secret: "private-token")
    let request = controller.versionRequest()
    #expect(request.url?.absoluteString == "http://127.0.0.1:9090/version")
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer private-token")
    #expect(throws: ProxyError.self) {
        try MihomoController(endpoint: controller.endpoint, secret: "x\r\nInjected: true")
    }
}

@Test func ipv6LoopbackAndVersionDecodingWork() throws {
    let controller = try MihomoController(endpoint: URL(string: "http://[::1]:9090")!)
    #expect(controller.versionRequest().url?.path == "/version")
    let version = try JSONDecoder().decode(ProxyVersion.self, from: Data(#"{"version":"v1.0.0","meta":true}"#.utf8))
    #expect(version.version == "v1.0.0")
    #expect(version.meta == true)
}
