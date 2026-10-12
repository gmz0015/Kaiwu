import Foundation
import KaiwuCore
import Testing

private actor TaskGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var opened = false
    func wait() async {
        if opened { return }
        await withCheckedContinuation { continuation = $0 }
    }
    func open() { opened = true; continuation?.resume(); continuation = nil }
}

@Test @MainActor func toolTaskWaitsForCancellationBeforeAllowingRestart() async throws {
    let task = ToolTask<Int>()
    let gate = TaskGate()
    task.start {
        await gate.wait(); try Task.checkCancellation(); return 1
    }
    task.cancel()
    #expect(task.isRunning && task.isCancelling)
    task.start {
        Issue.record("取消尚未完成时不能启动新任务"); return 2
    }
    await gate.open()
    for _ in 0..<100 where task.isRunning { try await Task.sleep(for: .milliseconds(5)) }
    #expect(!task.isRunning)
    #expect(task.result == nil)
    #expect(task.error == "操作已取消。")
    task.start { 3 }
    for _ in 0..<100 where task.isRunning { try await Task.sleep(for: .milliseconds(5)) }
    #expect(task.result == 3 && task.error == nil)
}

@Test @MainActor func toolTaskPreservesFailureAndCanClearCompletedResult() async throws {
    let task = ToolTask<Int>()
    task.start { throw CommandError.failed("fixture failure") }
    for _ in 0..<100 where task.isRunning { try await Task.sleep(for: .milliseconds(5)) }
    #expect(task.error == "fixture failure")
    task.clear()
    #expect(task.error == nil && task.result == nil)
}

@Test @MainActor func cancellationDoesNotHideAnIndependentFailure() async throws {
    let task = ToolTask<Int>()
    let gate = TaskGate()
    task.start {
        await gate.wait(); throw CommandError.failed("磁盘写入失败")
    }
    task.cancel()
    await gate.open()
    for _ in 0..<100 where task.isRunning { try await Task.sleep(for: .milliseconds(5)) }
    #expect(task.error == "磁盘写入失败")
    #expect(task.result == nil)
}
