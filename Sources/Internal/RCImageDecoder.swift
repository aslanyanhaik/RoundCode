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

struct RCImageDecoder {
  
  internal let configuration: RCCoderConfiguration
  internal var size = 720
  internal var bytesPerRow = 720
  internal var pixelThreshold = RCConstants.lightBackgroundRange
}

extension RCImageDecoder {
  func process(pointer: UnsafeMutablePointer<UInt8>) throws -> [RCBit] {
    let bufferData = UnsafeMutableBufferPointer<UInt8>(start: pointer, count: size * bytesPerRow)
    let data = PixelContainer(rows: bytesPerRow, items: bufferData)
    let points = try scanControlPoints(for: data)
    let transform = calculateTransform(from: points)
    let mapper = RCPointMapper(transform: transform, size: size)
    let locations = mapper.map(points: calculateBitLocations())
    let bits = locations.map { pixelThreshold.contains(data[Int($0.x), Int($0.y)]) ? RCBit.one : RCBit.zero }
    return bits
  }
  
  func decode(_ image: UIImage) throws -> [RCBit] {
    let pixelData = UnsafeMutableRawPointer.allocate(byteCount: size * size, alignment: MemoryLayout<UInt8>.alignment)
    let context = CGContext(data: pixelData, width: size, height: size, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
    context?.draw(image.cgImage!, in: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
    let bits = try process(pointer: pixelData.assumingMemoryBound(to: UInt8.self))
    pixelData.deallocate()
    return bits
  }
}

extension RCImageDecoder {
  private func scanControlPoints(for data: PixelContainer) throws -> [CGPoint] {
    var horizontalPatterns = [PixelPattern]()
    var verticalPatterns = [PixelPattern]()
    var points = [CGPoint]()
    for side in Side.allCases {
      switch side {
        case .left:
          horizontalPatterns = scanPixelPattern(for: .horizontal, data: data)
          points.append(try controlPoint(for: horizontalPatterns, side: side))
        case .right:
          points.append(try controlPoint(for: horizontalPatterns, side: side))
        case .top:
          verticalPatterns = scanPixelPattern(for: .vertical, data: data)
          points.append(try controlPoint(for: verticalPatterns, side: side))
        case .bottom:
          points.append(try controlPoint(for: verticalPatterns, side: side))
      }
    }
    return points
  }

  
  private func scanPixelPattern(for mode: ScanMode, data: PixelContainer) -> [PixelPattern] {
    var lastPattern = PixelPattern.init(bit: pixelThreshold.contains((data[0, 0])) ? RCBit.one : RCBit.zero, x: 0, y: 0, count: 0)
    var pixelPatterns = [lastPattern]
    var count = 0
    let maxSize = size * size
    switch mode {
      case .horizontal:
        while count < maxSize {
          let x = count % size
          let y = count / size
          let bit = pixelThreshold.contains(data[x, y]) ? RCBit.one : RCBit.zero
          if lastPattern.y == y, lastPattern.bit == bit {
            lastPattern.count += 1
            pixelPatterns[pixelPatterns.count - 1] = lastPattern
          } else {
            lastPattern = PixelPattern(bit: bit, x: x, y: y, count: 1)
            pixelPatterns.append(lastPattern)
          }
          count += 1
      }
      case .vertical:
        while count < maxSize {
          let x = count / size
          let y = count % size
          let bit = pixelThreshold.contains(data[x, y]) ? RCBit.one : RCBit.zero
          if lastPattern.x == x, lastPattern.bit == bit {
            lastPattern.count += 1
            pixelPatterns[pixelPatterns.count - 1] = lastPattern
          } else {
            lastPattern = PixelPattern(bit: bit, x: x, y: y, count: 1)
            pixelPatterns.append(lastPattern)
          }
          count += 1
      }
    }
    return pixelPatterns
  }
  
  private func controlPoint(for pixelPatterns: [PixelPattern], side: Side) throws -> CGPoint {
    let controlPoints = try pixelPatterns.withUnsafeBufferPointer { (pixelPatternsBuffer) -> [CGPoint] in
      var points = [CGPoint]()
      guard pixelPatternsBuffer.count >= 5 else { throw RCError.decoding }
      var countIndex = 0
      while countIndex < pixelPatternsBuffer.count - 5 {
        guard pixelPatternsBuffer[countIndex + 2].count >= 10 else {
          countIndex += 1
          continue
        }
        let pattern = (0...4).map({pixelPatternsBuffer[$0 + countIndex]})
        countIndex += 1
        switch side {
          case .left, .right:
            let axis = pattern[0].y
            guard pattern.allSatisfy({$0.y == axis}) else { continue }
          case .top, .bottom:
            let axis = pattern[0].x
            guard pattern.allSatisfy({$0.x == axis}) else { continue }
        }
        guard pattern[0].bit == .one, pattern[1].bit == .zero, pattern[2].bit == .one, pattern[3].bit == .zero, pattern[4].bit == .one else { continue }
        guard RCConstants.dotPointRange.contains(pattern[2].count / pattern[0].count) else { continue }
        guard RCConstants.dotPointRange.contains(pattern[2].count / pattern[1].count) else { continue }
        guard RCConstants.dotPointRange.contains(pattern[2].count / pattern[3].count) else { continue }
        guard RCConstants.dotPointRange.contains(pattern[2].count / pattern[4].count) else { continue }
        switch side {
          case .left:
            points.append(CGPoint(x: pattern[0].x, y: pattern[0].y))
          case .right:
            points.append(CGPoint(x: CGFloat(pattern[4].x) + CGFloat(pattern[4].count), y: CGFloat(pattern[4].y)))
          case .top:
            points.append(CGPoint(x: pattern[0].x, y: pattern[0].y))
          case .bottom:
            points.append(CGPoint(x: CGFloat(pattern[0].x), y: CGFloat(pattern[4].y) + CGFloat(pattern[4].count)))
        }
      }
      return points
    }
    guard !controlPoints.isEmpty else { throw RCError.decoding }
    return controlPoints.sorted {
      switch side {
        case .left:
          return $0.x < $1.x
        case .right:
          return $0.x > $1.x
        case .top:
          return $0.y < $1.y
        case .bottom:
          return $0.y > $1.y
      }
    }.first!
  }
    
  private func calculateTransform(from points: [CGPoint]) -> CATransform3D {
    let perspective = RCTransformation(points)
    let middleRect = CGRect(origin: .zero, size: CGSize(width: CGFloat(size), height: CGFloat(size)))
    let destination = RCTransformation([CGPoint(x: middleRect.minX, y: middleRect.midY),
                                        CGPoint(x: middleRect.midX, y: middleRect.minY),
                                        CGPoint(x: middleRect.midX, y: middleRect.maxY),
                                        CGPoint(x: middleRect.maxX, y: middleRect.midY)])
    return perspective.perspectiveTransform(to: destination)
  }
  
  private func calculateBitLocations() -> [CGPoint] {
    let size = CGFloat(self.size)
    let lineWidth = size * RCConstants.dotSizeScale / 5 //number of lines including spaces
    let mainRadius = size / 2
    let startAngle = asin(size * RCConstants.dotSizeScale / mainRadius)
    var points = [CGPoint]()
    let center = CGPoint(x: size / 2, y: size / 2)
    (0...3).forEach { offset in
      let angle = CGFloat(offset - 1) * CGFloat.pi / 2
      zip([0.5, 2.5, 4.5].map({mainRadius - lineWidth * $0}), [configuration.version.topLevelBitesCount, configuration.version.middleLevelBitesCount, configuration.version.bottomLevelBitesCount]) .forEach { (radius, bitCount) in
        let bitAngle = (CGFloat.pi / 2 - startAngle * 2)  / CGFloat(bitCount)
        (0..<bitCount).forEach { bitIndex in
          let bitIndexAngle = startAngle + bitAngle * (CGFloat(bitIndex) + 0.5) + angle
          let x = cos(bitIndexAngle) * radius
          let y = sin(bitIndexAngle) * radius
          let point = CGPoint(x: x + center.x, y: y + center.y)
          points.append(point)
        }
      }
    }
    return points
  }
}

extension RCImageDecoder {
  
  struct PixelPattern {
    let bit: RCBit
    let x: Int
    let y: Int
    var count: Float
  }
  
  enum Side: CaseIterable {
    case left
    case top
    case bottom
    case right
  }
  
  enum ScanMode {
    case horizontal
    case vertical
  }
  
  final class PixelContainer {
    let rows: Int
    var columns: Int { data.count / rows }
    let data: UnsafeMutableBufferPointer<UInt8>
    
    init(rows: Int, items: UnsafeMutableBufferPointer<UInt8>) {
      guard items.count % rows == 0 else { fatalError("number of rows are not matching") }
      self.rows = rows
      self.data = items
    }
    
    subscript(column: Int, row: Int) -> UInt8 {
      get { return data[self.rows * row + column] }
      set { data[self.rows * row + column] = newValue }
    }
  }
}
