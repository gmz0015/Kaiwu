public struct FeatureDescriptor: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let symbol: String
    public let summary: String

    public init(id: String, title: String, symbol: String, summary: String) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.summary = summary
    }
}
