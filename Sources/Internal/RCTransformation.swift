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

import simd
import QuartzCore

final class RCTransformation {
  
  private let vectors: [SIMD3<Double>]
  private static let zeroColumnBeforeLast: double4x3 = {
    let identity = double3x3(diagonal: SIMD3<Double>(repeating: 1))
    var columns = (0 ... (SIMD3<Double>.scalarCount - 1)).map {identity[$0]}
    columns.insert(SIMD3<Double>(repeating: 0), at: SIMD3<Double>.scalarCount - 1)
    return .init(columns)
  }()
  private static let zeroRowBeforeLast: double3x4 = zeroColumnBeforeLast.transpose
  
  init(_ points: [CGPoint]) {
    self.vectors = points.map {SIMD3<Double>(Double($0.x), Double($0.y), 1)}
  }
  
  func perspectiveTransform(to destination: RCTransformation) -> CATransform3D {
    let destinationBaseVectors = double3x3(Array(destination.vectors[0 ... (SIMD3<Double>.scalarCount - 1)]))
    let destinationVectors = destinationBaseVectors.inverse * destination.vectors[SIMD3<Double>.scalarCount]
    let destinationScale = double3x3(diagonal: destinationVectors)
    let destinationPoints = destinationBaseVectors * destinationScale
    let currentBaseVectors = double3x3(Array(vectors[0 ... (SIMD3<Double>.scalarCount - 1)]))
    let currentVectors = currentBaseVectors.inverse * vectors[SIMD3<Double>.scalarCount]
    let currentScale = double3x3(diagonal: currentVectors)
    let currentPoints = currentBaseVectors * currentScale
    let perspective = destinationPoints * currentPoints.inverse
    let zNormalized = 1 / perspective[SIMD3<Double>.scalarCount - 1, SIMD3<Double>.scalarCount - 1] * perspective
    var matrix = (RCTransformation.zeroRowBeforeLast * zNormalized) * RCTransformation.zeroColumnBeforeLast
    
    matrix[SIMD3<Double>.scalarCount - 1, SIMD3<Double>.scalarCount - 1] = 1
    return unsafeBitCast(matrix, to: CATransform3D.self)
  }
}
