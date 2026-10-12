import CloudServices
import Foundation
import Testing

@Test func cloudIsDisabledWithoutSignedConfiguration() async throws {
    #expect(try await DisabledCloudAccountService().accountState() == .disabled)
}

@Test func syncEnvelopeIsVersionedAndRoundTrips() throws {
    let value = SyncedPreferences(excludeDevelopmentArtifacts: true, modifiedAt: Date(timeIntervalSince1970: 100))
    let data = try JSONEncoder().encode(value)
    #expect(try JSONDecoder().decode(SyncedPreferences.self, from: data) == value)
    #expect(value.schemaVersion == 1)
}
