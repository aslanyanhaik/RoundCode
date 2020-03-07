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
  
  func process(pointer: UnsafeMutablePointer<UInt8>, size: Int) throws -> [RCBit] {
    let bufferData = UnsafeMutableBufferPointer<UInt8>(start: pointer, count: size * size)
    let data = RCMatrix<UInt8>(rows: size, items: bufferData)
    let sectionSize = size / 5
    let sectors = Side.allCases.map { side -> (side: Side, x: Int, y: Int) in
      switch side {
        case .top:
          let x = (size - sectionSize) / 2
          let y = 0
          return (side, x, y)
        case .bottom:
          let x = (size - sectionSize) / 2
          let y = size - sectionSize
          return (side, x, y)
        case .left:
          let x = 0
          let y = (size - sectionSize) / 2
          return (side, x, y)
        case .right:
          let x = size - sectionSize
          let y = (size - sectionSize) / 2
          return (side, x, y)
      }
    }
    var points = [CGPoint]()
    for sector in sectors {
      let point = try scanControlPoint(region: (sector.x, sector.y, sectionSize), data: data, side: sector.side)
      points.append(point)
    }
    print(points)
    let image = try fixPerspective(pointer, points: points, size: size)
    let bits = decode(image)
    return bits
  }
  
  func decode(_ image: UIImage) throws -> [RCBit] {
    let size = image.cgImage!.height
    var pixelData = UnsafeMutableRawPointer.allocate(byteCount: size * size, alignment: MemoryLayout<UInt8>.alignment)
    let context = CGContext(data: pixelData, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
    context?.draw(image.cgImage!, in: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
    defer {
      pixelData.deallocate()
    }
    let bits = try process(pointer: pixelData.assumingMemoryBound(to: UInt8.self), size: size)
    return bits
  }
}

extension RCImageDecoder {
  private func scanControlPoint(region: (x: Int, y: Int, size: Int), data: RCMatrix<UInt8>, side: Side) throws -> CGPoint {
    var points = [CGPoint]()
    var lastPattern = RCPixelPattern(bit: data[region.x, region.y] > 180 ? RCBit.zero : RCBit.one, row: region.y, column: region.x, count: 0)
    var pixelPatterns = [lastPattern]
    var count = 0
    let maxSize = region.size * region.size
    while count < maxSize {
      let rowIndex = count / region.size + region.y
      let columnIndex = count % region.size + region.x
      let bit = data[columnIndex, rowIndex] > 180 ? RCBit.zero : RCBit.one
      if lastPattern.row == rowIndex, lastPattern.bit == bit {
        lastPattern.count += 1
        pixelPatterns[pixelPatterns.count - 1] = lastPattern
      } else {
        lastPattern = RCPixelPattern(bit: bit, row: rowIndex, column: columnIndex, count: 1)
        pixelPatterns.append(lastPattern)
      }
      count += 1
    }
    let pixelPatternsBuffer = UnsafeMutableBufferPointer(start: UnsafeMutableRawPointer(mutating: pixelPatterns).assumingMemoryBound(to: RCPixelPattern.self), count: pixelPatterns.count)
    //    NotificationCenter.default.post(name: NSNotification.Name.init("random"), object: pixelPatterns)
    guard pixelPatternsBuffer.count >= 5 else { throw RCError.decoding }
    var countIndex = 0
    while countIndex < pixelPatternsBuffer.count - 5 {
      let pattern1 = pixelPatternsBuffer[countIndex]
      let pattern2 = pixelPatternsBuffer[countIndex + 1]
      let pattern3 = pixelPatternsBuffer[countIndex + 2]
      let pattern4 = pixelPatternsBuffer[countIndex + 3]
      let pattern5 = pixelPatternsBuffer[countIndex + 4]
      countIndex += 1
      guard pattern3.count >= 10 else { continue }
      let row = pattern1.row
      guard pattern2.row == row, pattern3.row == row, pattern4.row == row, pattern5.row == row else { continue }
      guard pattern1.bit == .one, pattern2.bit == .zero, pattern3.bit == .one, pattern4.bit == .zero, pattern5.bit == .one else { continue }
      guard RCConstants.dotPointRange.contains(pattern3.count / pattern1.count) else { continue }
      guard RCConstants.dotPointRange.contains(pattern3.count / pattern2.count) else { continue }
      guard RCConstants.dotPointRange.contains(pattern3.count / pattern4.count) else { continue }
      guard RCConstants.dotPointRange.contains(pattern3.count / pattern5.count) else { continue }
      switch side {
        case .left:
          points.append(CGPoint(x: pattern1.column, y: pattern1.row))
        case .right:
          points.append(CGPoint(x: CGFloat(pattern5.column) + CGFloat(pattern5.count), y: CGFloat(pattern5.row)))
        case .top:
          let distance = (CGFloat(pattern5.column) + CGFloat(pattern5.count) - CGFloat(pattern1.column)) / 2
          let centerX = CGFloat(pattern1.column) + distance
          let centerY = CGFloat(row) - distance
          points.append(CGPoint(x: centerX, y: centerY))
        case .bottom:
          let distance = (CGFloat(pattern5.column) + CGFloat(pattern5.count) - CGFloat(pattern1.column)) / 2
          let centerX = CGFloat(pattern1.column) + distance
          let centerY = CGFloat(row) + distance
          points.append(CGPoint(x: centerX, y: centerY))
      }
    }
    guard !points.isEmpty else { throw RCError.decoding }
    switch side {
      case .left:
        return points.sorted(by: {$0.x < $1.x}).first!
      case .right:
        return points.sorted(by: {$0.x > $1.x}).first!
      case .top:
        return points.sorted(by: {$0.y < $1.y}).first!
      case .bottom:
        return points.sorted(by: {$0.y > $1.y}).first!
    }
  }
  
  private func fixPerspective(_ data: UnsafeMutablePointer<UInt8>, points: [CGPoint], size: Int) throws -> CGImage {
    let data = CFDataCreate(nil, data, size * size)!
    let provider = CGDataProvider(data: data)!
    let cgImage = CGImage(width: size, height: size, bitsPerComponent: 8, bitsPerPixel: 8, bytesPerRow: size, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: 0), provider: provider, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)!
    
    
    
    
    //    let path = UIBezierPath()
    //    path.move(to: points[0])
    //    path.addLine(to: points[1])
    //    path.addLine(to: points[2])
    //    path.addLine(to: points[3])
    //    path.close()
    //    let originalBounds = path.bounds
    //    path.apply(CGAffineTransform(scaleX: sqrt(2.0), y: sqrt(2.0)))
    //    let scaledBounds = path.bounds
    //    path.apply(CGAffineTransform(translationX: (originalBounds.width - scaledBounds.width) / 2 , y: (originalBounds.height - scaledBounds.height) / 2))
    //    let vectors = points.map{CGVector(dx: $0.x, dy: $0.y)}
    //    let image = CIImage() //.image(from: data)
    //    let perspectiveFilter = CIFilter(name: "CIPerspectiveCorrection")!
    //    perspectiveFilter.setValue(image, forKey: "inputImage")
    //    perspectiveFilter.setValue(vectors[0], forKey: "inputTopLeft")
    //    perspectiveFilter.setValue(vectors[1], forKey: "inputTopRight")
    //    perspectiveFilter.setValue(vectors[2], forKey: "inputBottomRight")
    //    perspectiveFilter.setValue(vectors[3], forKey: "inputBottomLeft")
    //    let transform = CGAffineTransform(translationX: image.extent.midX, y: image.extent.midY).rotated(by: CGFloat.pi / 4).translatedBy(x: -image.extent.midX, y: -image.extent.midY)
    //    let correctedImage = perspectiveFilter.outputImage!.transformed(by: transform)
    //    let cgImage = context.createCGImage(correctedImage, from: CGRect(x: 0, y: 0, width: data.columns, height: data.columns))!
    //    var pixelValues = UnsafeMutableRawPointer.allocate(byteCount: cgImage.width * cgImage.height, alignment: MemoryLayout<UInt8>.alignment)
    //    let colorSpace = CGColorSpaceCreateDeviceGray()
    //    let contextRef = CGContext(data: &pixelValues, width: cgImage.width, height: cgImage.height, bitsPerComponent: 8, bytesPerRow: cgImage.width, space: colorSpace, bitmapInfo: 0)
    //    contextRef?.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: cgImage.width, height: cgImage.height)))
    //    data.data.deallocate()
    //    data.data = UnsafeMutableBufferPointer<UInt8>(start: pixelValues.bindMemory(to: UInt8.self, capacity: data.columns * data.rows), count: data.columns * data.rows)
    //    return data
    throw RCError.decoding
    //    return UIImage().cgImage!
  }
  
  private func decode(_ image: CGImage) -> [RCBit] {
    let pixelData = UnsafeMutableRawPointer.allocate(byteCount: image.width * image.height, alignment: MemoryLayout<UInt8>.alignment)
    let context = CGContext(data: pixelData, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
    context?.draw(image, in: CGRect(origin: .zero, size: CGSize(width: image.width, height: image.height)))
    let buffer = UnsafeMutableBufferPointer<UInt8>(start: pixelData.assumingMemoryBound(to: UInt8.self), count: image.width * image.height)
    let data = RCMatrix(rows: image.height, items: buffer)
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
    pixelData.deallocate()
    return points.map { data[Int($0.x), Int($0.y)] > 200 ? RCBit.zero : RCBit.one }
  }
}

extension RCImageDecoder {
  
  struct RCPixelPattern: CustomStringConvertible {
    
    let bit: RCBit
    let row: Int
    let column: Int
    var count: Float
    
    var description: String {
      "\(bit.debugDescription), start: \(row) \(column), count: \(count)"
    }
  }
  
  enum Side: CaseIterable {
    case left
    case top
    case right
    case bottom
  }
}
