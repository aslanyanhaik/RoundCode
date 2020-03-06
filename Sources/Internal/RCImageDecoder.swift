//  MIT License

//  Copyright (c) 2020 Haik Aslanyan

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit
import CoreImage

final class RCImageDecoder {
  
  private var context = CIContext()
  
  func process(buffer: UnsafeMutableBufferPointer<UInt8>, size: Int) throws -> [RCBit] {
    let data = RCMatrix<UInt8>(rows: size, items: buffer)
    let points = try scanControlPoints(data)
    let imageData = fixPerspective(data, points: points)
    let bits = decode(imageData)
    return bits
  }
  
  func decode(_ image: UIImage) throws -> [RCBit] {
    let size = image.cgImage!.height
    var pixelData = UnsafeMutableRawPointer.allocate(byteCount: size * size, alignment: MemoryLayout<UInt8>.alignment)
    let context = CGContext(data: pixelData, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
    context?.draw(image.cgImage!, in: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
    let buffer = UnsafeMutableBufferPointer(start: pixelData.assumingMemoryBound(to: UInt8.self), count: size * size)
    let bits = try process(buffer: buffer, size: size)
    defer {
      pixelData.deallocate()
    }
    return bits
  }
}

extension RCImageDecoder {
  
  private func scanControlPoints( _ data: RCMatrix<UInt8>) throws -> [CGPoint] {
    var points = [CGPoint]()
    
    let range = (CGFloat(1.8)...CGFloat(2.2))
    for rowIndex in 0..<data.rows {
      let rowBuffer = data.row(for: rowIndex)
      var pixelBuffer = [RCPixelPattern]()
        let first = RCPixelPattern.init(bit: (rowBuffer[0] > 180 ? RCBit.zero : RCBit.one), startPoint: CGPoint.init(x: 0, y: CGFloat(rowIndex)), count: 0)
        pixelBuffer.append(first)
        rowBuffer.enumerated().forEach { value in
          let bit = value.element > 180 ? RCBit.zero : RCBit.one
          if pixelBuffer.last!.bit == bit {
            pixelBuffer[pixelBuffer.count - 1].count += 1
          } else {
            let pixel = RCPixelPattern.init(bit: bit, startPoint: CGPoint.init(x: CGFloat(value.offset), y: CGFloat(rowIndex)), count: 1)
            pixelBuffer.append(pixel)
          }
        }
        guard pixelBuffer.count >= 7 else { break }
        for pixelIndex in 2..<(pixelBuffer.count - 4) {
          let pixel = pixelBuffer[pixelIndex]
          guard pixel.bit == .one, pixel.count >= 10 else { continue }
          
          let leftTwo = pixelBuffer[pixelIndex - 2]
          let leftOne = pixelBuffer[pixelIndex - 1]
          let rightOne = pixelBuffer[pixelIndex + 1]
          let rightTwo = pixelBuffer[pixelIndex + 2]
          
          guard leftTwo.bit == .one else { continue }
          guard leftOne.bit == .zero else { continue }
          guard rightOne.bit == .zero else { continue }
          guard rightTwo.bit == .one else { continue }
          guard range.contains(pixel.count / leftTwo.count) else { continue }
          guard range.contains(pixel.count / leftOne.count) else { continue }
          guard range.contains(pixel.count / rightOne.count) else { continue }
          guard range.contains(pixel.count / rightTwo.count) else { continue }
          
          
          let point = CGPoint.init(x: pixel.startPoint.x, y: pixel.startPoint.y + CGFloat(pixel.count) / 2)
          points.append(point)
          
          
      }
      
    }
    return points
  }
  
  private func fixPerspective(_ data: RCMatrix<UInt8>, points: [CGPoint]) -> RCMatrix<UInt8> {
    let path = UIBezierPath()
    path.move(to: points[0])
    path.addLine(to: points[1])
    path.addLine(to: points[2])
    path.addLine(to: points[3])
    path.close()
    let originalBounds = path.bounds
    path.apply(CGAffineTransform(scaleX: sqrt(2.0), y: sqrt(2.0)))
    let scaledBounds = path.bounds
    path.apply(CGAffineTransform(translationX: (originalBounds.width - scaledBounds.width) / 2 , y: (originalBounds.height - scaledBounds.height) / 2))
    let vectors = points.map{CGVector(dx: $0.x, dy: $0.y)}
    let image = CIImage() //.image(from: data)
    let perspectiveFilter = CIFilter(name: "CIPerspectiveCorrection")!
    perspectiveFilter.setValue(image, forKey: "inputImage")
    perspectiveFilter.setValue(vectors[0], forKey: "inputTopLeft")
    perspectiveFilter.setValue(vectors[1], forKey: "inputTopRight")
    perspectiveFilter.setValue(vectors[2], forKey: "inputBottomRight")
    perspectiveFilter.setValue(vectors[3], forKey: "inputBottomLeft")
    let transform = CGAffineTransform(translationX: image.extent.midX, y: image.extent.midY).rotated(by: CGFloat.pi / 4).translatedBy(x: -image.extent.midX, y: -image.extent.midY)
    let correctedImage = perspectiveFilter.outputImage!.transformed(by: transform)
    let cgImage = context.createCGImage(correctedImage, from: CGRect(x: 0, y: 0, width: data.columns, height: data.columns))!
    var pixelValues = UnsafeMutableRawPointer.allocate(byteCount: cgImage.width * cgImage.height, alignment: MemoryLayout<UInt8>.alignment)
    let colorSpace = CGColorSpaceCreateDeviceGray()
    let contextRef = CGContext(data: &pixelValues, width: cgImage.width, height: cgImage.height, bitsPerComponent: 8, bytesPerRow: cgImage.width, space: colorSpace, bitmapInfo: 0)
    contextRef?.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: cgImage.width, height: cgImage.height)))
    data.data.deallocate()
    data.data = UnsafeMutableBufferPointer<UInt8>(start: pixelValues.bindMemory(to: UInt8.self, capacity: data.columns * data.rows), count: data.columns * data.rows)
    return data
  }
  
  private func decode(_ data: RCMatrix<UInt8>) -> [RCBit] {
    let size = CGFloat(data.columns)
    let lineWidth = size * RCConstants.dotSizeScale / 11 * 2 //number of lines including spaces
    let mainRadius = (size - lineWidth) / 2
    let startAngle = asin(size * RCConstants.dotSizeScale / mainRadius)
    let distancePerBit = (CGFloat.pi / 2 - startAngle * 2) / CGFloat(RCConstants.level1BitesCount)
    var points = [CGPoint]()
    [RCConstants.level1BitesCount, RCConstants.level2BitesCount, RCConstants.level3BitesCount].enumerated().forEach { row in
      let radius = mainRadius - lineWidth * CGFloat(row.offset * 2)
      (0..<4).forEach { group in
        let baseDistance = -CGFloat.pi / 2 + CGFloat.pi / 2 * CGFloat(group) + startAngle
        (0..<row.element).forEach { bitCount in
          let angle = baseDistance + distancePerBit * CGFloat(bitCount) + distancePerBit / 2
          let x = cos(angle) * radius
          let y = sin(angle) * radius
          let point = CGPoint(x: x + size / 2, y: y + size / 2)
          points.append(point)
        }
      }
    }
    return points.map { data[Int($0.x), Int($0.y)] > 200 ? RCBit.zero : RCBit.one }
  }
}

private extension RCImageDecoder {
  
  struct RCPixelPattern: CustomStringConvertible {
    
    let bit: RCBit
    let startPoint: CGPoint
    var count: CGFloat
    
    
    var description: String {
      "\(bit.debugDescription), start: \(startPoint.x), count: \(count), \n "
    }
  }
}
