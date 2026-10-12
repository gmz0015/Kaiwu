import Darwin
import Foundation
import NetworkFeature
import Testing

/// 仅在回环接口的系统分配端口监听，固定响应，不读取真实网络配置。
@Test func localTCPAndPACProbesReachControlledLoopbackServer() async throws {
    let server = socket(AF_INET, SOCK_STREAM, 0)
    guard server >= 0 else { throw POSIXError(.EIO) }
    defer { close(server) }
    var address = sockaddr_in()
    address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
    address.sin_family = sa_family_t(AF_INET)
    address.sin_addr.s_addr = inet_addr("127.0.0.1")
    let bound = withUnsafePointer(to: &address) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            bind(server, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
    }
    guard bound == 0, listen(server, 2) == 0 else { throw POSIXError(.EIO) }
    var length = socklen_t(MemoryLayout<sockaddr_in>.size)
    let named = withUnsafeMutablePointer(to: &address) {
        $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(server, $0, &length) }
    }
    guard named == 0 else { throw POSIXError(.EIO) }
    let port = Int(UInt16(bigEndian: address.sin_port))
    let serving = Task.detached {
        var request = ""
        for index in 0..<2 {
            var descriptor = pollfd(fd: server, events: Int16(POLLIN), revents: 0)
            guard poll(&descriptor, 1, 5000) > 0 else { throw POSIXError(.ETIMEDOUT) }
            let client = accept(server, nil, nil)
            guard client >= 0 else { throw POSIXError(.EIO) }
            defer { close(client) }
            if index == 0 { continue }
            var incoming = pollfd(fd: client, events: Int16(POLLIN), revents: 0)
            guard poll(&incoming, 1, 5000) > 0 else { throw POSIXError(.ETIMEDOUT) }
            var buffer = [UInt8](repeating: 0, count: 4096)
            let count = recv(client, &buffer, buffer.count, 0)
            guard count > 0 else { throw POSIXError(.EIO) }
            request = String(decoding: buffer.prefix(count), as: UTF8.self)
            var noSignal: Int32 = 1
            _ = setsockopt(client, SOL_SOCKET, SO_NOSIGPIPE, &noSignal, socklen_t(MemoryLayout<Int32>.size))
            let response = Array("HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".utf8)
            _ = response.withUnsafeBytes { send(client, $0.baseAddress, $0.count, 0) }
        }
        return request
    }
    let probe = LocalProxyProbe()
    #expect(try await probe.port(host: "127.0.0.1", port: port) == .pass)
    #expect(try await probe.pac(url: URL(string: "http://localhost:\(port)/fixture.pac")!) == .pass)
    let request = try await serving.value
    #expect(request.hasPrefix("HEAD /fixture.pac HTTP/"))
}
