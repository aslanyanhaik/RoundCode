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
    let rect = CGRect(origin: .zero, size: CGSize(width: image.size, height: image.size))
    let renderer = UIGraphicsImageRenderer(bounds: rect, format: .default())
    let image = renderer.image { context in
      let cgContext = context.cgContext
      if !self.image.isTransparent {
        UIColor.white.setFill()
        context.fill(rect)
      }
      self.image.tintColor.setFill()
      let size = self.image.size - self.image.size * 0.15
      let halfSize = size / 2
      [(halfSize, 0), (size, halfSize), (halfSize, size), (0, halfSize)].map({CGPoint(x: $0.0, y: $0.1)}).forEach { point in
        cgContext.saveGState()
        cgContext.translateBy(x: point.x, y: point.y)
        drawDot()
        cgContext.restoreGState()
      }
      cgContext.saveGState()
      cgContext.translateBy(x: rect.size.height / 4, y:  rect.size.height / 4)
      cgContext.scaleBy(x: 0.5, y: 0.5)
      drawImage()
      cgContext.restoreGState()
      for value in self.image.bits.enumerated() {
        cgContext.saveGState()
        cgContext.translateBy(x: self.image.size / 2, y: self.image.size / 2)
        cgContext.rotate(by: CGFloat(value.offset) * CGFloat.pi / 2)
        drawMessage(row: value.element)
        cgContext.restoreGState()
      }
    }
    return image
  }
}

private extension RCDrawer {
  func drawDot() {
    let dot = UIBezierPath()
    let patternSingleSize = image.size * 0.15 / 6.5
    let patternSizes = [6.5, 4.5, 2.5].map({$0 * patternSingleSize})
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
  
  func drawMessage() {
    
  }
}
