import KaiwuCore
import SwiftUI

@MainActor
public protocol FeatureModule {
    var descriptor: FeatureDescriptor { get }
    func makeView() -> AnyView
}
