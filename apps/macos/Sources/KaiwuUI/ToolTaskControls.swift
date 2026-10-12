import SwiftUI

public struct ToolTaskControls: View {
    let isCancelling: Bool
    let cancel: () -> Void

    public init(isCancelling: Bool, cancel: @escaping () -> Void) {
        self.isCancelling = isCancelling
        self.cancel = cancel
    }

    public var body: some View {
        ProgressView().controlSize(.small)
        Button(isCancelling ? "正在取消…" : "取消", action: cancel)
            .disabled(isCancelling)
    }
}
