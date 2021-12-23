
import Accelerate
import Foundation
import UIKit

extension CVPixelBuffer {
    func normalized(_ width: Int, _ height: Int) -> [Float]? {
        let w = CVPixelBufferGetWidth(self)
        let h = CVPixelBufferGetHeight(self)

        let pixelBufferType = CVPixelBufferGetPixelFormatType(self)
        assert(pixelBufferType == kCVPixelFormatType_32BGRA)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)
        let bytesPerPixel = 4
        let croppedImageSize = min(w, h)
        CVPixelBufferLockBaseAddress(self, .readOnly)
        let oriX = w > h ? (w - h) / 2 : 0
        let oriY = h > w ? (h - w) / 2 : 0
        guard let baseAddr = CVPixelBufferGetBaseAddress(self)?.advanced(by: oriY * bytesPerRow + oriX * bytesPerPixel) else {
            return nil
        }
        
        // 카메라에서 들어온 이미지 버퍼 vImage_Buffer 형식으로 변환하며 input
        var inBuff = vImage_Buffer(data: baseAddr, height: UInt(croppedImageSize), width: UInt(croppedImageSize), rowBytes: bytesPerRow)
        guard let dstData = malloc(width * height * bytesPerPixel) else {
            return nil
        }
        
        
//
//        let formats = vImage_CGImageFormat(
//            bitsPerComponent: 8,
//            bitsPerPixel: 32,
//            colorSpace: CGColorSpaceCreateDeviceRGB(),
//            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue),
//            renderingIntent: .defaultIntent)
//
//
//        let result = try? inBuff.createCGImage(format: formats!)
//        let image = UIImage(cgImage: result!)
//        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
//
        
        // input 값 학습 규격에 맞는 사이즈로 변환 하며 output 값 저장
        var outBuff = vImage_Buffer(data: dstData, height: UInt(height), width: UInt(width), rowBytes: width * bytesPerPixel)
        let err = vImageScale_ARGB8888(&inBuff, &outBuff, nil, vImage_Flags(0))
        CVPixelBufferUnlockBaseAddress(self, .readOnly)
        if err != kvImageNoError {
            free(dstData)
            return nil
        }
        
        // 이비지 버퍼 -> float[] 값으로 변환 normalized 작업
        var normalizedBuffer: [Float32] = [Float32](repeating: 0, count: width * height * 3)
        for i in 0 ..< width * height {
            normalizedBuffer[i] = Float32(dstData.load(fromByteOffset: i * 4 + 0, as: UInt8.self)) / 255.0  // R
            normalizedBuffer[width * height + i] = Float32(dstData.load(fromByteOffset: i * 4 + 1, as: UInt8.self)) / 255.0 // G
            normalizedBuffer[width * height * 2 + i] = Float32(dstData.load(fromByteOffset: i * 4 + 2, as: UInt8.self)) / 255.0 // B
        }
        free(dstData)
        return normalizedBuffer
    }
    
    func crop(to rect: CGRect) -> CVPixelBuffer? {
            CVPixelBufferLockBaseAddress(self, .readOnly)
            defer { CVPixelBufferUnlockBaseAddress(self, .readOnly) }

            guard let baseAddress = CVPixelBufferGetBaseAddress(self) else {
                return nil
            }

            let inputImageRowBytes = CVPixelBufferGetBytesPerRow(self)

            let imageChannels = 4
            let startPos = Int(rect.origin.y) * inputImageRowBytes + imageChannels * Int(rect.origin.x)
            let outWidth = UInt(rect.width)
            let outHeight = UInt(rect.height)
            let croppedImageRowBytes = Int(outWidth) * imageChannels

            var inBuffer = vImage_Buffer()
            inBuffer.height = outHeight
            inBuffer.width = outWidth
            inBuffer.rowBytes = inputImageRowBytes

            inBuffer.data = baseAddress + UnsafeMutableRawPointer.Stride(startPos)

            guard let croppedImageBytes = malloc(Int(outHeight) * croppedImageRowBytes) else {
                return nil
            }

            var outBuffer = vImage_Buffer(data: croppedImageBytes, height: outHeight, width: outWidth, rowBytes: croppedImageRowBytes)

            let scaleError = vImageScale_ARGB8888(&inBuffer, &outBuffer, nil, vImage_Flags(0))

            guard scaleError == kvImageNoError else {
                free(croppedImageBytes)
                return nil
            }

            return croppedImageBytes.toCVPixelBuffer(pixelBuffer: self, targetWith: Int(outWidth), targetHeight: Int(outHeight), targetImageRowBytes: croppedImageRowBytes)
        }
}

extension UnsafeMutableRawPointer {
    // Converts the vImage buffer to CVPixelBuffer
    func toCVPixelBuffer(pixelBuffer: CVPixelBuffer, targetWith: Int, targetHeight: Int, targetImageRowBytes: Int) -> CVPixelBuffer? {
        let pixelBufferType = CVPixelBufferGetPixelFormatType(pixelBuffer)
        let releaseCallBack: CVPixelBufferReleaseBytesCallback = {mutablePointer, pointer in
            if let pointer = pointer {
                free(UnsafeMutableRawPointer(mutating: pointer))
            }
        }

        var targetPixelBuffer: CVPixelBuffer?
        let conversionStatus = CVPixelBufferCreateWithBytes(nil, targetWith, targetHeight, pixelBufferType, self, targetImageRowBytes, releaseCallBack, nil, nil, &targetPixelBuffer)

        guard conversionStatus == kCVReturnSuccess else {
            free(self)
            return nil
        }

        return targetPixelBuffer
    }
}
