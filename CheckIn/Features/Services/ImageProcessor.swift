import UIKit

class ImageProcessor {
    func prepareImageForAnalysis(_ image: UIImage) -> UIImage {
        // 1. First fix orientation to ensure consistent processing
        let orientedImage = image.fixedOrientation()
        
        // 2. Resize to optimal size for face detection
        let targetSize = CGSize(width: 1024, height: 1024)
        let resizedImage = orientedImage.resizedImage(to: targetSize)
        
        return resizedImage
    }
    
    func compressImage(_ image: UIImage?) -> Data? {
        guard let image = image else { return nil }
        
        // Always fix orientation before compression to ensure consistent display
        let orientedImage = image.fixedOrientation()
        return orientedImage.jpegData(compressionQuality: 0.7)
    }
    
    // New method to prepare image specifically for storage
    func prepareImageForStorage(_ image: UIImage) -> Data? {
        // Fix orientation and resize for storage
        let orientedImage = image.fixedOrientation()
        let resizedImage = orientedImage.resizedImage(to: CGSize(width: 512, height: 512))
        return resizedImage.jpegData(compressionQuality: 0.8)
    }
}

extension UIImage {
    // Renamed to avoid ambiguity
    func resizedImage(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    func fixedOrientation() -> UIImage {
        // If orientation is already up, no need to redraw
        if imageOrientation == .up { return self }
        
        // Calculate the transformation needed
        var transform = CGAffineTransform.identity
        
        switch imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
        default:
            break
        }
        
        switch imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
        default:
            break
        }
        
        // Calculate the bounding box for the transformed image
        let ctx = CGContext(data: nil, width: Int(size.width), height: Int(size.height),
                           bitsPerComponent: 8, bytesPerRow: 0,
                           space: CGColorSpaceCreateDeviceRGB(),
                           bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        
        ctx.concatenate(transform)
        
        switch imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            ctx.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.height, height: size.width))
        default:
            ctx.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
        
        let cgImage = ctx.makeImage()!
        return UIImage(cgImage: cgImage)
    }
    
    // Additional method for better quality image processing
    func normalizedImage() -> UIImage {
        if imageOrientation == .up { return self }
        
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage ?? self
    }
}
