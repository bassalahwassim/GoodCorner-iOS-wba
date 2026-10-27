import XCTest
import UIKit
@testable import goodCorner

private final class PhotoFakeStore: DraftStore {
    var stored: ListingDraft?
    func load() throws -> ListingDraft? { stored }
    func save(_ draft: ListingDraft) throws { stored = draft }
    func discard() throws { stored = nil }
}

final class DraftPhotoTests: XCTestCase {
    private func makePNG(width: CGFloat, height: CGFloat) -> Data {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        return renderer.pngData { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    func testImageProcessorDownscalesLargeImage() throws {
        let output = try XCTUnwrap(ImageProcessor.jpegData(from: makePNG(width: 3000, height: 2000)))
        let image = try XCTUnwrap(UIImage(data: output))
        XCTAssertEqual(max(image.size.width * image.scale, image.size.height * image.scale), 1280, accuracy: 1)
    }

    func testImageProcessorKeepsSmallImageSize() throws {
        let output = try XCTUnwrap(ImageProcessor.jpegData(from: makePNG(width: 400, height: 300)))
        let image = try XCTUnwrap(UIImage(data: output))
        XCTAssertEqual(image.size.width * image.scale, 400, accuracy: 1)
    }

    func testImageProcessorRejectsInvalidData() {
        XCTAssertNil(ImageProcessor.jpegData(from: Data([0x00, 0x01, 0x02])))
    }

    func testDraftWithOnlyAPhotoIsNotEmpty() {
        var draft = ListingDraft()
        draft.imageData = Data([0x01])
        XCTAssertFalse(draft.isEmpty)
    }

    func testStoreRoundTripKeepsImageData() throws {
        let persistence = PersistenceController(inMemory: true)
        let store = CoreDataDraftStore(container: persistence.container)
        let draft = ListingDraft(title: "Avec photo", imageData: makePNG(width: 50, height: 50))

        try store.save(draft)

        XCTAssertEqual(try store.load()?.imageData, draft.imageData)
    }

    @MainActor
    func testAttachPhotoStoresResizedImageInDraft() async throws {
        let viewModel = DraftViewModel(store: PhotoFakeStore())

        await viewModel.attachPhoto(rawData: makePNG(width: 2400, height: 1600))

        let data = try XCTUnwrap(viewModel.draft.imageData)
        let image = try XCTUnwrap(UIImage(data: data))
        XCTAssertLessThanOrEqual(max(image.size.width, image.size.height), 1281)
        XCTAssertNil(viewModel.errorMessage)
    }

    @MainActor
    func testAttachInvalidPhotoSetsErrorAndKeepsDraftUnchanged() async {
        let viewModel = DraftViewModel(store: PhotoFakeStore())

        await viewModel.attachPhoto(rawData: Data([0x00]))

        XCTAssertNil(viewModel.draft.imageData)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testRemovePhotoClearsImage() {
        let viewModel = DraftViewModel(store: PhotoFakeStore())
        viewModel.draft.imageData = Data([0x01])
        viewModel.removePhoto()
        XCTAssertNil(viewModel.draft.imageData)
    }
}
