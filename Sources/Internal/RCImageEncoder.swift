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

final class RCImageEncoder {
  
  let configuration: RCCoderConfiguration
  
  init(configuration: RCCoderConfiguration) {
    self.configuration = configuration
  }
  
  func encode(_ image: RCImage, bits: [RCBit]) -> UIImage {
    let rect = CGRect(origin: .zero, size: CGSize(width: image.size + image.contentInsets.left + image.contentInsets.right, height: image.size + image.contentInsets.top + image.contentInsets.bottom))
    let renderer = UIGraphicsImageRenderer(bounds: rect, format: .default())
    let renderedImage = renderer.image { context in
      let cgContext = context.cgContext
      if !image.isTransparent {
        UIColor.white.setFill()
        context.fill(rect)
      }
      cgContext.translateBy(x: image.contentInsets.left, y: image.contentInsets.top)
      cgContext.saveGState()
      cgContext.saveGState()
      let imageTranslation = image.size * (1 - RCConstants.imageScale) / 2
      cgContext.translateBy(x: imageTranslation, y:  imageTranslation)
      cgContext.scaleBy(x: RCConstants.imageScale, y: RCConstants.imageScale)
      drawAttachment(image)
      cgContext.restoreGState()
      var adjustedRect = rect
      adjustedRect.origin.x = -image.contentInsets.left
      adjustedRect.origin.y = -image.contentInsets.top
      let rectPath = UIBezierPath(rect: adjustedRect)
      rectPath.addClip()
      rectPath.usesEvenOddFillRule = true
      let mainPath = UIBezierPath()
      let size = image.size - image.size * RCConstants.dotSizeScale
      let halfSize = size / 2
      [(halfSize, 0), (size, halfSize), (halfSize, size), (0, halfSize)].map({CGPoint(x: $0.0, y: $0.1)}).forEach { point in
        drawDot(image: image, position: point, path: mainPath)
      }
      bits.chunked(into: 4).enumerated().forEach { value in
        drawMessage(image: image, section: RCBitSection(data: value.element, configuration: configuration), angle: CGFloat(value.offset - 1) * CGFloat.pi / 2, path: mainPath)
      }
      mainPath.usesEvenOddFillRule = true
      mainPath.addClip()
      let colorSpace = CGColorSpaceCreateDeviceRGB()
      let gradient = CGGradient(colorsSpace: colorSpace, colors: image.tintColors.map({$0.cgColor}) as CFArray, locations: nil)!
      switch image.gradientType {
        case .linear:
          cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: image.size, y: image.size), options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
        case .radial:
          let startPoint = CGPoint(x: image.size / 2, y: image.size / 2)
          cgContext.drawRadialGradient(gradient, startCenter: startPoint, startRadius: image.size * (1 - RCConstants.dotSizeScale) / 2, endCenter: startPoint, endRadius: image.size / 2, options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
      }
    }
    return renderedImage
  }
}

private extension RCImageEncoder {
  func drawDot(image: RCImage, position: CGPoint, path: UIBezierPath) {
    let patternSingleSize = image.size * RCConstants.dotSizeScale / RCConstants.dotPatterns.max()!
    let patternSizes = RCConstants.dotPatterns.map({$0 * patternSingleSize})
    patternSizes.enumerated().forEach { value in
      let dotPath = UIBezierPath(ovalIn: CGRect(x: position.x + (patternSizes[0] - value.element) / 2, y: position.y + (patternSizes[0] - value.element) / 2, width: value.element, height: value.element))
      dotPath.close()
      path.append(dotPath)
    }
  }
  
  func drawAttachment(_ image: RCImage) {
    guard let attachmentImage = image.attachmentImage else { return }
    let rect = CGRect(origin: .zero, size: CGSize(width: image.size, height: image.size))
    let path = UIBezierPath(ovalIn: rect)
    path.addClip()
    let aspectRatio = max(image.size / attachmentImage.size.width, image.size / attachmentImage.size.height)
    let scaledImageRect = CGRect(
      x: (image.size - attachmentImage.size.width * aspectRatio) / 2,
      y: (image.size - attachmentImage.size.height * aspectRatio) / 2,
      width: attachmentImage.size.width * aspectRatio,
      height: attachmentImage.size.height * aspectRatio)
    attachmentImage.draw(in: scaledImageRect, blendMode: .normal, alpha: 1)
  }
  
  func drawMessage(image: RCImage, section: RCBitSection, angle: CGFloat, path: UIBezierPath) {
    guard !image.message.isEmpty else { return }
    let lineWidth = image.size * RCConstants.dotSizeScale / 5 //number of lines including spaces
    let mainRadius = image.size / 2
    let startAngle = asin(image.size * RCConstants.dotSizeScale / mainRadius)
    let cornerRadiusAngle = asin(lineWidth / mainRadius) / 2
    let center = CGPoint(x: image.size / 2, y: image.size / 2)
    zip([0.5, 2.5, 4.5].map({mainRadius - lineWidth * $0}), [section.topLevel, section.middleLevel, section.bottomLevel]) .forEach { (radius, bitGroups) in
      let bitAngle = (CGFloat.pi / 2 - startAngle * 2)  / CGFloat(bitGroups.map({$0.count}).reduce(0, +))
      bitGroups.forEach { group in
        guard group.bit == .one else { return }
        let startingPosition = startAngle + bitAngle * CGFloat(group.offset) + angle
        let endPosition = startingPosition + bitAngle * CGFloat(group.count)
        let linePath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startingPosition + cornerRadiusAngle, endAngle: endPosition - cornerRadiusAngle, clockwise: true)
        let cgPath = CGPath(__byStroking: linePath.cgPath, transform: nil, lineWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 1.0)!
        let combinedPath = UIBezierPath(cgPath: cgPath)
        path.append(combinedPath)
      }
    }
  }
}

extension RCImageEncoder {
  struct RCBitGroup {
    let bit: RCBit
    let offset: Int
    var count: Int
  }
  
  struct RCBitSection {
    let topLevel: [RCBitGroup]
    let middleLevel: [RCBitGroup]
    let bottomLevel: [RCBitGroup]
    
    init(data: [RCBit], configuration: RCCoderConfiguration) {
      func toBitGroup(_ bits: [RCBit]) -> [RCBitGroup] {
        var bitGroup = [RCBitGroup(bit: bits[0], offset: 0, count: 0)]
        bits.enumerated().forEach { value in
          bitGroup.last!.bit == value.element ? (bitGroup[bitGroup.count - 1].count += 1) : bitGroup.append(RCBitGroup(bit: value.element, offset: value.offset, count: 1))
        }
        return bitGroup
      }
      var bitData = data
      self.topLevel = toBitGroup(Array(bitData.prefix(configuration.version.topLevelBitesCount)))
      bitData = Array(bitData.dropFirst(configuration.version.topLevelBitesCount))
      self.middleLevel = toBitGroup(Array(bitData.prefix(configuration.version.middleLevelBitesCount)))
      bitData = Array(bitData.dropFirst(configuration.version.middleLevelBitesCount))
      self.bottomLevel = toBitGroup(bitData)
    }
  }
}
