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

final class RCImageDecoder {
  
  var size: Int
  var padding = 0
  lazy var bytesPerRow = self.size
  let configuration: RCCoderConfiguration
  private let sectionSize: Int
  
  init(size: Int, configuration: RCCoderConfiguration) {
    self.size = size
    sectionSize = size / 5
    self.configuration = configuration
  }
}

extension RCImageDecoder {
  func process(pointer: UnsafeMutablePointer<UInt8>) throws -> [RCBit] {
    let bufferData = UnsafeMutableBufferPointer<UInt8>(start: pointer, count: size * bytesPerRow)
    let data = PixelContainer(rows: bytesPerRow, items: bufferData)
    var points = [CGPoint]()
    for side in Side.allCases {
      switch side {
        case .left:
          let point = try scanControlPoint(for: data, region: (padding, (size - sectionSize) / 2), side: side)
          points.append(point)
        case .top:
          let point = try scanControlPoint(for: data, region: ((size - sectionSize) / 2, padding), side: side)
          points.append(point)
        case .right:
          let point = try scanControlPoint(for: data, region: (size - sectionSize - padding, (size - sectionSize) / 2), side: side)
          points.append(point)
        case .bottom:
          let point = try scanControlPoint(for: data, region: ((size - sectionSize) / 2, size - sectionSize - padding), side: side)
          points.append(point)
      }
    }
    let image = try fixPerspective(pointer, points: points)
    let bits = decode(image)
    return bits
  }
  
  func decode(_ image: UIImage, size: Int) throws -> [RCBit] {
    self.size = size
    self.bytesPerRow = size
    let pixelData = UnsafeMutableRawPointer.allocate(byteCount: size * size, alignment: MemoryLayout<UInt8>.alignment)
    let context = generateContext(data: pixelData, size: size, bytesPerRow: self.bytesPerRow)
    context?.draw(image.cgImage!, in: CGRect(origin: .zero, size: CGSize(width: size, height: size)))
    let bits = try process(pointer: pixelData.assumingMemoryBound(to: UInt8.self))
    pixelData.deallocate()
    return bits
  }
}

extension RCImageDecoder {
  private func scanControlPoint(for data: PixelContainer, region: (x: Int, y: Int), side: Side) throws -> CGPoint {
    
    func scan(region: (x: Int, y: Int, size: Int), data: PixelContainer, coordinate: (Int) -> (x: Int, y: Int), comparison: (PixelPattern, (x: Int, y: Int)) -> Bool) -> [PixelPattern] {
      var lastPattern = PixelPattern(bit: data[region.x, region.y] > RCConstants.pixelThreshold ? RCBit.zero : RCBit.one, x: region.x, y: region.y, count: 0)
      var pixelPatterns = [lastPattern]
      var count = 0
      let maxSize = region.size * region.size
      while count < maxSize {
        let coordinate = coordinate(count)
        let bit = data[coordinate.x, coordinate.y] > RCConstants.pixelThreshold ? RCBit.zero : RCBit.one
        if comparison(lastPattern, coordinate), lastPattern.bit == bit {
          lastPattern.count += 1
          pixelPatterns[pixelPatterns.count - 1] = lastPattern
        } else {
          lastPattern = PixelPattern(bit: bit, x: coordinate.x, y: coordinate.y, count: 1)
          pixelPatterns.append(lastPattern)
        }
        count += 1
      }
      return pixelPatterns
    }
    
    let pixelPatterns: [PixelPattern]
    switch side {
      case .left, .right:
        pixelPatterns = scan(region: (region.x, region.y, sectionSize), data: data, coordinate: { count in
          let x = count % sectionSize + region.x
          let y = count / sectionSize + region.y
          return (x, y)
        }, comparison: { (pattern, coordinate) in
          return pattern.y == coordinate.y
        })
      case .top, .bottom:
        pixelPatterns = scan(region: (region.x, region.y, sectionSize), data: data, coordinate: { count in
          let x = count / sectionSize + region.x
          let y = count % sectionSize + region.y
          return (x, y)
        }, comparison: { (pattern, coordinate) in
          return pattern.x == coordinate.x
        })
    }
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
  
  private func fixPerspective(_ data: UnsafeMutablePointer<UInt8>, points: [CGPoint]) throws -> CGImage {
    guard let context = generateContext(data: data, size: size, bytesPerRow: bytesPerRow), let cgImage = context.makeImage() else {
      throw RCError.decoding
    }
    let image = UIGraphicsImageRenderer(size: CGSize(width: CGFloat(size), height: CGFloat(size))).image { context in
      let baseView = UIView(frame: context.format.bounds)
      let imageView = UIImageView(frame: context.format.bounds)
      baseView.addSubview(imageView)
      imageView.image = UIImage(cgImage: cgImage)
      imageView.layer.anchorPoint = .zero
      imageView.layer.frame = context.format.bounds
      let perspective = RCTransformation(points)
      let destination = RCTransformation([CGPoint(x: context.format.bounds.minX, y: context.format.bounds.midY),
                                          CGPoint(x: context.format.bounds.midX, y: context.format.bounds.minY),
                                          CGPoint(x: context.format.bounds.midX, y: context.format.bounds.maxY),
                                          CGPoint(x: context.format.bounds.maxX, y: context.format.bounds.midY)])
      let transform = perspective.perspectiveTransform(to: destination)
      imageView.transform3D = transform
      baseView.drawHierarchy(in: context.format.bounds, afterScreenUpdates: true)
    }
    guard let renderImage = image.cgImage else {
      throw RCError.decoding
    }
    return renderImage
  }
  
  private func decode(_ image: CGImage) -> [RCBit] {
    let pixelData = UnsafeMutableRawPointer.allocate(byteCount: image.width * image.height, alignment: MemoryLayout<UInt8>.alignment)
    let context = generateContext(data: pixelData, size: image.width, bytesPerRow: image.width)
    context?.draw(image, in: CGRect(origin: .zero, size: CGSize(width: image.width, height: image.height)))
    let buffer = UnsafeMutableBufferPointer<UInt8>(start: pixelData.assumingMemoryBound(to: UInt8.self), count: image.width * image.height)
    let data = PixelContainer(rows: image.height, items: buffer)
    let size = CGFloat(data.columns)
    let lineWidth = CGFloat(image.height) * RCConstants.dotSizeScale / 5 //number of lines including spaces
    let mainRadius = CGFloat(image.height) / 2
    let startAngle = asin(CGFloat(image.height) * RCConstants.dotSizeScale / mainRadius)
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
    let bits = points.map { data[Int($0.x), Int($0.y)] > RCConstants.pixelThreshold ? RCBit.zero : RCBit.one }
    pixelData.deallocate()
    return bits
  }
}

extension RCImageDecoder {
  private func generateContext(data: UnsafeMutableRawPointer?, size: Int, bytesPerRow: Int) -> CGContext? {
    return  CGContext(data: data, width: size, height: size, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
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
