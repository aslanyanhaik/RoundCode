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

class RCDrawer {
  
  let image: RCImage
  
  init(image: RCImage) {
    self.image = image
  }
  
  func draw() -> UIImage {
    let rect = CGRect(origin: .zero, size: CGSize(width: image.size + image.contentInsets.left + image.contentInsets.right, height: image.size + image.contentInsets.top + image.contentInsets.bottom))
    let renderer = UIGraphicsImageRenderer(bounds: rect, format: .default())
    let image = renderer.image { context in
      let cgContext = context.cgContext
      if !self.image.isTransparent {
        UIColor.white.setFill()
        context.fill(rect)
      }
      self.image.tintColor.setFill()
      self.image.tintColor.setStroke()
      cgContext.translateBy(x: self.image.contentInsets.left, y: self.image.contentInsets.top)
      let size = self.image.size - self.image.size * RCConstants.dotSizeScale
      let halfSize = size / 2
      [(halfSize, 0), (size, halfSize), (halfSize, size), (0, halfSize)].map({CGPoint(x: $0.0, y: $0.1)}).forEach { point in
        cgContext.saveGState()
        cgContext.translateBy(x: point.x, y: point.y)
        drawDot()
        cgContext.restoreGState()
      }
      cgContext.saveGState()
      let imageTranslation = self.image.size * (1 - RCConstants.imageScale) / 2
      cgContext.translateBy(x: imageTranslation, y:  imageTranslation)
      cgContext.scaleBy(x: RCConstants.imageScale, y: RCConstants.imageScale)
      drawImage()
      cgContext.restoreGState()
      for value in self.image.bits.enumerated() {
        cgContext.saveGState()
        cgContext.translateBy(x: self.image.size / 2, y: self.image.size / 2)
        cgContext.rotate(by: CGFloat(value.offset - 1) * CGFloat.pi / 2)
        drawMessage(group: value.element)
        cgContext.restoreGState()
      }
    }
    return image
  }
}

private extension RCDrawer {
  func drawDot() {
    let dot = UIBezierPath()
    let patternSingleSize = image.size * RCConstants.dotSizeScale / RCConstants.dotPatterns.max()!
    let patternSizes = RCConstants.dotPatterns.map({$0 * patternSingleSize})
    for value in patternSizes.enumerated() {
      let path = UIBezierPath(ovalIn: CGRect(x: (patternSizes[0] - value.element) / 2, y: (patternSizes[0] - value.element) / 2, width: value.element, height: value.element))
      path.close()
      value.element != patternSizes.last! ? dot.append(path) : path.fill()
    }
    dot.usesEvenOddFillRule = true
    dot.fill()
  }
  
  func drawImage() {
    guard let image = self.image.attachmentImage else { return }
    let rect = CGRect(origin: .zero, size: CGSize(width: self.image.size, height: self.image.size))
    let path = UIBezierPath(ovalIn: rect)
    path.addClip()
    let aspectRatio = max(self.image.size / image.size.width, self.image.size / image.size.height)
    let scaledImageRect = CGRect(
      x: (self.image.size - image.size.width * aspectRatio) / 2,
      y: (self.image.size - image.size.height * aspectRatio) / 2,
      width: image.size.width * aspectRatio,
      height: image.size.height * aspectRatio)
    image.draw(in: scaledImageRect, blendMode: .normal, alpha: 1)
  }
  
  func drawMessage(group: [[RCBit]]) {
    guard !image.message.isEmpty else { return }
    let lineWidth = image.size * RCConstants.dotSizeScale / 11 * 2 //number of lines including spaces
    let mainRadius = (self.image.size - lineWidth) / 2
    let path = UIBezierPath()
    let rowRadius = group.indices.map({mainRadius - lineWidth * CGFloat($0 * 2)})
    let startAngle = asin(self.image.size * RCConstants.dotSizeScale / mainRadius)
    let distancePerBit = (CGFloat.pi / 2 - startAngle * 2) / CGFloat(group.first!.count)
    zip(rowRadius, group).forEach {
      let bits = $0.1
      let radius = $0.0
      for (offset, bit) in bits.enumerated() {
        guard bit.boolValue else { continue }
        let startPosition = startAngle + distancePerBit * CGFloat(offset)
        let endPosition = startPosition + distancePerBit
        let linePath = UIBezierPath(arcCenter: .zero, radius: radius, startAngle: startPosition, endAngle: endPosition, clockwise: true)
        path.append(linePath)
      }
    }
    path.lineWidth = lineWidth
    path.lineCapStyle = .round
    path.stroke()
  }
}
