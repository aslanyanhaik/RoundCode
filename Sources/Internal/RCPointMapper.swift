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

import QuartzCore

struct RCPointMapper {
  
  private var transform: CATransform3D
  private let denominatorX: CGFloat
  private let denominatorY: CGFloat
  private let denominatorW: CGFloat
  private let size: CGFloat
  
  init(transform: CATransform3D, size: Int) {
    let translateDueToDisposition = CATransform3DMakeTranslation(-CGFloat(size) / 2, -CGFloat(size) / 2, 0)
    self.transform = CATransform3DConcat(transform, translateDueToDisposition)
    self.size = CGFloat(size)
    self.denominatorX = transform.m12 * transform.m21 - transform.m11  * transform.m22 + transform.m14 * transform.m22 * transform.m41 - transform.m12 * transform.m24 * transform.m41 - transform.m14 * transform.m21 * transform.m42 + transform.m11 * transform.m24 * transform.m42
    self.denominatorY = -transform.m12 * transform.m21 + transform.m11 * transform.m22 - transform.m14 * transform.m22 * transform.m41 + transform.m12 * transform.m24 * transform.m41 + transform.m14 * transform.m21 * transform.m42 - transform.m11 * transform.m24 * transform.m42
    self.denominatorW = transform.m12 * transform.m21 - transform.m11 * transform.m22 + transform.m14 * transform.m22 * transform.m41 - transform.m12 * transform.m24 * transform.m41 - transform.m14 * transform.m21 * transform.m42 + transform.m11 * transform.m24 * transform.m42
  }
  
  func map(points: [CGPoint]) -> [CGPoint] {
    return points.map { point in
      let modelPoint =  CGPoint(x: (point.x * 2.0 - size) / 2.0, y: (point.y * 2.0 - size) / 2.0)
      let x = modelPoint.x
      let y = modelPoint.y
      let xp: CGFloat = (transform.m22 * transform.m41 - transform.m21 * transform.m42 - transform.m22 * x + transform.m24 * transform.m42 * x + transform.m21 * y - transform.m24 * transform.m41 * y) / denominatorX
      let yp: CGFloat = (-transform.m11 * transform.m42 + transform.m12 * (transform.m41 - x) + transform.m14 * transform.m42 * x + transform.m11 * y - transform.m14 * transform.m41 * y) / denominatorY
      let wp: CGFloat = (transform.m12 * transform.m21 - transform.m11 * transform.m22 + transform.m14 * transform.m22 * x - transform.m12 * transform.m24 * x - transform.m14 * transform.m21 * y + transform.m11 * transform.m24 * y) / denominatorW
      let actualPoint = CGPoint(x: xp / wp, y: yp / wp)
      let isOutOfBounds = !(0...size).contains(actualPoint.x) || !(0...size).contains(actualPoint.y)
      return isOutOfBounds ? .zero : actualPoint
    }
  }
}
