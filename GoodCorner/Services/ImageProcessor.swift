import UIKit

enum ImageProcessor {
    /// Décode l'image, la réduit (côté le plus long <= maxDimension) et la recompresse en JPEG.
    /// Évite de stocker des photos de plusieurs Mo dans le brouillon.
    static func jpegData(from data: Data, maxDimension: CGFloat = 1280, quality: CGFloat = 0.8) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let size = image.size
        let longestSide = max(size.width, size.height)
        guard longestSide > 0 else { return nil }

        let scale = min(1, maxDimension / longestSide)
        let target = CGSize(
            width: max(1, (size.width * scale).rounded()),
            height: max(1, (size.height * scale).rounded())
        )

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1   // dimensions en pixels réels
        let renderer = UIGraphicsImageRenderer(size: target, format: format)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: quality)
    }
}
