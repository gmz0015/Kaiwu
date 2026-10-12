import Foundation
import Observation

/// 页面拥有任务；取消后等待操作真正退出，防止重复启动和旧结果覆盖。
@MainActor @Observable
public final class ToolTask<Value: Sendable> {
    public private(set) var result: Value?
    public private(set) var error: String?
    public private(set) var isRunning = false
    public private(set) var isCancelling = false
    @ObservationIgnored private var task: Task<Void, Never>?

    public init() {}

    public func start(_ operation: @escaping @MainActor @Sendable () async throws -> Value) {
        guard !isRunning else { return }
        result = nil
        error = nil
        isRunning = true
        isCancelling = false
        task = Task {
            defer {
                isRunning = false
                isCancelling = false
                task = nil
            }
            do { result = try await operation() } catch is CancellationError { error = "操作已取消。" } catch let error
                as URLError where error.code == .cancelled && Task.isCancelled
            {
                self.error = "操作已取消。"
            } catch { self.error = error.localizedDescription }
        }
    }

    public func cancel() {
        guard isRunning else { return }
        isCancelling = true
        task?.cancel()
    }

    public func clear() {
        guard !isRunning else { return }
        result = nil
        error = nil
    }
}
