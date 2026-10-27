import XCTest
@testable import GoodCorner

final class APIClientTests: XCTestCase {
    private let base = URL(string: "http://localhost:8081")!

    func testRequestBuilding() {
        let request = APIClient(baseURL: base).makeRequest(path: "listings")
        XCTAssertEqual(request.url?.absoluteString, "http://localhost:8081/listings")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testRelativeImagePathBecomesAbsoluteURL() {
        let url = AppConfig.absoluteURL(for: "/images/ad-small/x.jpg", baseURL: base)
        XCTAssertEqual(url?.absoluteString, "http://localhost:8081/images/ad-small/x.jpg")
    }

    func testNilOrEmptyImagePathGivesNoURL() {
        XCTAssertNil(AppConfig.absoluteURL(for: nil, baseURL: base))
        XCTAssertNil(AppConfig.absoluteURL(for: "", baseURL: base))
    }
}
