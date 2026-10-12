import KaiwuCore
import Foundation
import Testing

@Test func argumentsAreNeverInterpretedByAShell() async throws {
    let literal = "hello ; $(touch /tmp/kaiwu-should-not-exist) `id` \" spaced"
    let result = try await ProcessRunner().run(Command("/usr/bin/printf", arguments: ["%s", literal]))
    #expect(result.status == 0)
    #expect(result.output == literal)
}

@Test func largeOutputDoesNotDeadlockAPipe() async throws {
    let result = try await ProcessRunner().run(Command("/usr/bin/seq", arguments: ["1", "40000"]))
    #expect(result.status == 0)
    #expect(result.output.hasSuffix("40000\n"))
}

@Test func timeoutStopsChildProcess() async throws {
    await #expect(throws: CommandError.self) {
        try await ProcessRunner().run(Command("/bin/sleep", arguments: ["10"], timeout: 0.1))
    }
}

@Test func cancellationStopsChildProcess() async throws {
    let task = Task { try await ProcessRunner().run(Command("/bin/sleep", arguments: ["10"])) }
    try await Task.sleep(for: .milliseconds(100))
    task.cancel()
    await #expect(throws: CancellationError.self) { try await task.value }
}
