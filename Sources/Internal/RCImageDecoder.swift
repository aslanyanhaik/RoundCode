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

class RCImageDecoder {
  
  func decode(_ image: UIImage) throws -> [RCBit] {
    guard let cgImage = image.cgImage else { throw RCCoder.RCCoderError.decoding }
    var pixelValues = [UInt8](repeating: 0, count: cgImage.width * cgImage.height)
    let colorSpace = CGColorSpaceCreateDeviceGray()
    let contextRef = CGContext(data: &pixelValues, width: cgImage.width, height: cgImage.height, bitsPerComponent: 8, bytesPerRow: cgImage.width, space: colorSpace, bitmapInfo: 0)
    contextRef?.draw(cgImage, in: CGRect(origin: .zero, size: CGSize(width: cgImage.width, height: cgImage.height)))
    let imageMatrix = RCMatrix(rows: cgImage.width, items: pixelValues)
    let center = CGPoint(x: cgImage.width, y: cgImage.width)
    let lineWidth = CGFloat(cgImage.width) * RCConstants.dotSizeScale / 11 * 2 //number of lines including spaces
    let mainRadius = (CGFloat(cgImage.width) - lineWidth) / 2
    let startAngle = asin(CGFloat(cgImage.width) * RCConstants.dotSizeScale / mainRadius)
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
          let point = CGPoint(x: x + center.x.rounded() / 2, y: y + center.y.rounded() / 2)
          points.append(point)
        }
      }
    }
    return points.map { imageMatrix[Int($0.x), Int($0.y)] > 200 ? RCBit.zero : RCBit.one }
  }
}


