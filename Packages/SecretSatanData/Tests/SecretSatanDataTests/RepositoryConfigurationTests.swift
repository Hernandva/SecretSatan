import Foundation
@testable import SecretSatanData
import Testing

struct RepositoryConfigurationTests {
    @Test func buildsTheURLOfADeclaredService() throws {
        let configuration = RepositoryConfiguration(baseURL: "https://api.example.com/v1", serviceNames: ["users"])
        #expect(try configuration.url(for: "users").absoluteString == "https://api.example.com/v1/users")
    }

    @Test func appBaseURLIsEmptyWithoutTheInfoPlistKey() {
        // The test runner's Info.plist has no APIBaseURL.
        #expect(RepositoryConfiguration.appBaseURL.isEmpty)
    }

    @Test func rejectsAnEmptyBaseURL() {
        let configuration = RepositoryConfiguration(baseURL: "", serviceNames: ["users"])
        #expect(throws: NetworkError.missingBaseURL) { try configuration.url(for: "users") }
    }

    @Test(arguments: ["api.example.com", "api.example.com/", "ftp://api.example.com", "https://"])
    func rejectsABaseURLWithoutHTTPSchemeOrHost(baseURL: String) {
        let configuration = RepositoryConfiguration(baseURL: baseURL, serviceNames: ["users"])
        #expect(throws: NetworkError.invalidURL(baseURL)) { try configuration.url(for: "users") }
    }

    @Test func keepsATrailingSlashOutOfTheServiceURL() throws {
        let configuration = RepositoryConfiguration(baseURL: "https://api.example.com/", serviceNames: ["auth/apple"])
        #expect(try configuration.url(for: "auth/apple").absoluteString == "https://api.example.com/auth/apple")
    }

    @Test func rejectsAnUndeclaredService() {
        let configuration = RepositoryConfiguration(baseURL: "https://api.example.com", serviceNames: [])
        #expect(throws: NetworkError.unknownService("users")) { try configuration.url(for: "users") }
    }
}
