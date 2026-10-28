import XCTest
@testable import GoodCorner

/// Intercepte les requêtes URLSession (aucun serveur nécessaire).
private final class StubURLProtocol: URLProtocol {
    static var lastRequest: URLRequest?
    static var error: Error?
    static var data = Data(#"{"page":1,"has_more":false,"total":0,"limit":0,"items":[]}"#.utf8)

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        if let error = Self.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class APIClientSearchTests: XCTestCase {
    private let base = URL(string: "http://localhost:8081")!

    private func makeClient() -> APIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return APIClient(baseURL: base, session: URLSession(configuration: configuration))
    }

    override func setUp() {
        super.setUp()
        StubURLProtocol.lastRequest = nil
        StubURLProtocol.error = nil
    }

    func testQueryItemIsPercentEncoded() {
        let request = APIClient(baseURL: base).makeRequest(
            path: "listings",
            queryItems: [URLQueryItem(name: "query", value: "a b+c")]
        )
        XCTAssertEqual(request.url?.absoluteString, "http://localhost:8081/listings?query=a%20b%2Bc")
    }

    func testSearchTermIsSentAsQueryParameter() async throws {
        _ = try await makeClient().fetchListings(query: " vinyle ")
        XCTAssertEqual(StubURLProtocol.lastRequest?.url?.absoluteString,
                       "http://localhost:8081/listings?query=vinyle")
    }

    func testNilOrBlankTermSendsNoQueryParameter() async throws {
        let client = makeClient()
        _ = try await client.fetchListings(query: nil)
        XCTAssertEqual(StubURLProtocol.lastRequest?.url?.absoluteString, "http://localhost:8081/listings")

        _ = try await client.fetchListings(query: "   ")
        XCTAssertEqual(StubURLProtocol.lastRequest?.url?.absoluteString, "http://localhost:8081/listings")
    }

    func testCancelledRequestThrowsCancellationErrorNotAPIError() async {
        StubURLProtocol.error = URLError(.cancelled)
        do {
            _ = try await makeClient().fetchListings(query: "x")
            XCTFail("Une erreur était attendue")
        } catch is CancellationError {
            // attendu
        } catch {
            XCTFail("CancellationError attendu, reçu \(error)")
        }
    }

    func testOtherNetworkFailureIsMappedToAPIError() async {
        StubURLProtocol.error = URLError(.notConnectedToInternet)
        do {
            _ = try await makeClient().fetchListings(query: "x")
            XCTFail("Une erreur était attendue")
        } catch {
            XCTAssertEqual(error as? APIError, .network)
        }
    }
}
