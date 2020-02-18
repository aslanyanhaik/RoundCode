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

import Foundation

final class RCMatrix {
  
  //MARK: Properties
  let rows: Int
  let columns: Int
  private var data = [[Float32]]()
  
  //MARK: Inits
  init(size: Int) {
    self.rows = size
    self.columns = size
    for _ in 0..<size {
      data.append(Array(repeating: 0, count: size))
    }
  }
  
  init(columns: Int, items: [Float32]) {
    guard items.count % columns == 0 else {
      fatalError("number of columns are not matching")
    }
    self.columns = columns
    self.rows = items.count / columns
    data = stride(from: 0, to: items.count, by: self.columns).map {
      Array(items[$0 ..< min($0 + self.rows, items.count)])
    }
  }
}

//MARK: Public methods
extension RCMatrix {
  subscript(row: Int, column: Int) -> Float32 {
    get {
      guard (0...self.rows).contains(row), (0...self.columns).contains(column) else {
        fatalError("out of bounds")
      }
      return data[row][column]
    }
    set {
     data[row][column] = newValue
    }
  }
  
  func row(for index: Int) -> [Float32] {
    return data[index]
  }
  
  func column(for index: Int) -> [Float32] {
    return data.compactMap({$0[index]})
  }
  
  func swap(row firstRow: Int, with lastRow: Int) {
    guard (0...self.rows).contains(firstRow) else {
      fatalError("out of bounds")
    }
    data.swapAt(firstRow, lastRow)
  }
  
  static func identity(size: Int) -> RCMatrix {
    let matrix = RCMatrix(size: size)
    for index in 0..<size {
      matrix[index, index] = 1
    }
    return matrix
  }
}

extension RCMatrix: Equatable {
  static func == (lhs: RCMatrix, rhs: RCMatrix) -> Bool {
    return lhs.data.flatMap({$0}) == rhs.data.flatMap({$0})
  }
}

//MARK: CustomStringConvertible
extension RCMatrix: CustomStringConvertible {
  var description: String {
    var message = "columns: \(columns), rows: \(rows)"
    data.forEach({message += "\n \($0.description)"})
    return message
  }
}
