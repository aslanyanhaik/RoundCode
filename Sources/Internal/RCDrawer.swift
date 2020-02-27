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
      cgContext.translateBy(x: self.image.contentInsets.left, y: self.image.contentInsets.top)
      cgContext.saveGState()
      cgContext.saveGState()
      let imageTranslation = self.image.size * (1 - RCConstants.imageScale) / 2
      cgContext.translateBy(x: imageTranslation, y:  imageTranslation)
      cgContext.scaleBy(x: RCConstants.imageScale, y: RCConstants.imageScale)
      drawImage()
      cgContext.restoreGState()
      var adjustedRect = rect
      adjustedRect.origin.x = -self.image.contentInsets.left
      adjustedRect.origin.y = -self.image.contentInsets.top
      let rectPath = UIBezierPath(rect: adjustedRect)
      rectPath.addClip()
      rectPath.usesEvenOddFillRule = true
      let mainPath = UIBezierPath()
      let size = self.image.size - self.image.size * RCConstants.dotSizeScale
      let halfSize = size / 2
      [(halfSize, 0), (size, halfSize), (halfSize, size), (0, halfSize)].map({CGPoint(x: $0.0, y: $0.1)}).forEach { point in
        drawDot(position: point, path: mainPath)
      }
      self.image.bits.enumerated().forEach { value in
        drawMessage(group: value.element, angle: CGFloat(value.offset - 1) * CGFloat.pi / 2, path: mainPath)
      }
      mainPath.usesEvenOddFillRule = true
      mainPath.addClip()
      let colorSpace = CGColorSpaceCreateDeviceRGB()
      let gradient = CGGradient(colorsSpace: colorSpace, colors: self.image.tintColors.map({$0.cgColor}) as CFArray, locations: nil)!
      switch self.image.gradientType {
        case .linear:
          cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: self.image.size, y: self.image.size), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        case .radial:
          let startPoint = CGPoint(x: self.image.size / 2, y: self.image.size / 2)
          cgContext.drawRadialGradient(gradient, startCenter: startPoint, startRadius: self.image.size * (1 - RCConstants.dotSizeScale) / 2, endCenter: startPoint, endRadius: self.image.size / 2, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
      }
    }
    return image
  }
}

private extension RCDrawer {
  func drawDot(position: CGPoint, path: UIBezierPath) {
    let patternSingleSize = image.size * RCConstants.dotSizeScale / RCConstants.dotPatterns.max()!
    let patternSizes = RCConstants.dotPatterns.map({$0 * patternSingleSize})
    patternSizes.enumerated().forEach { value in
      let dotPath = UIBezierPath(ovalIn: CGRect(x: position.x + (patternSizes[0] - value.element) / 2, y: position.y + (patternSizes[0] - value.element) / 2, width: value.element, height: value.element))
      dotPath.close()
      path.append(dotPath)
    }
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
  
  func drawMessage(group: [[RCBitGroup]], angle: CGFloat, path: UIBezierPath) {
    guard !image.message.isEmpty else { return }
    let lineWidth = image.size * RCConstants.dotSizeScale / 11 * 2 //number of lines including spaces
    let mainRadius = (self.image.size - lineWidth) / 2
    let rowRadius = group.indices.map({mainRadius - lineWidth * CGFloat($0 * 2)})
    var startAngle = asin(self.image.size * RCConstants.dotSizeScale / mainRadius)
    let distancePerBit = (CGFloat.pi / 2 - startAngle * 2) / CGFloat(RCConstants.level1BitesCount)
    let center = CGPoint(x: self.image.size / 2, y: self.image.size / 2)
    startAngle += angle
    zip(rowRadius, group).forEach {
      let rowBitsGroup = $0.1
      let radius = $0.0
      rowBitsGroup.forEach { bit in
        guard bit.bit.boolValue else { return }
        let startPosition = startAngle + distancePerBit * CGFloat(bit.offset)
        let endPosition = startPosition + distancePerBit * CGFloat(bit.count)
        let linePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startPosition, endAngle: endPosition, clockwise: true)
        let cgPath = CGPath(__byStroking: linePath.cgPath, transform: nil, lineWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 1.0)!
        let combinedPath = UIBezierPath(cgPath: cgPath)
        path.append(combinedPath)
      }
    }
  }
}

