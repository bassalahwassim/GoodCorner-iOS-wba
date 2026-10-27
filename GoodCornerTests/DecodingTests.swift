import XCTest
@testable import GoodCorner

final class DecodingTests: XCTestCase {
    private let json = """
    {
      "page": 1, "has_more": true, "total": 300, "limit": 2,
      "items": [
        {
          "is_urgent": true, "id": 1547408955, "creation_date": "2019-11-06T11:22:35Z",
          "title": "Vinyle", "price": 10, "category_id": 7, "description": "desc",
          "images_url": { "small": "/images/ad-small/a.jpg", "thumb": "/images/ad-thumb/a.jpg" }
        },
        {
          "is_urgent": false, "id": 2, "creation_date": "2019-11-06T11:22:29Z",
          "title": "Sans image", "price": 250.5, "category_id": 11, "description": "d"
        }
      ]
    }
    """

    func testDecodesEnvelopeAndListing() throws {
        let response = try JSONDecoder.api.decode(ListingsResponse.self, from: Data(json.utf8))
        XCTAssertEqual(response.total, 300)
        XCTAssertTrue(response.hasMore)
        XCTAssertEqual(response.items.count, 2)
        XCTAssertEqual(response.items[0].categoryID, 7)
        XCTAssertTrue(response.items[0].isUrgent)
        XCTAssertEqual(response.items[0].imagesURL?.thumb, "/images/ad-thumb/a.jpg")
    }

    func testMissingImagesDecodesToNil() throws {
        let response = try JSONDecoder.api.decode(ListingsResponse.self, from: Data(json.utf8))
        XCTAssertNil(response.items[1].imagesURL)
        XCTAssertEqual(response.items[1].price, 250.5)
    }

    func testCreationDateIsParsed() throws {
        let response = try JSONDecoder.api.decode(ListingsResponse.self, from: Data(json.utf8))
        let expected = ISO8601DateFormatter().date(from: "2019-11-06T11:22:35Z")
        XCTAssertEqual(response.items[0].creationDate, expected)
    }
}
