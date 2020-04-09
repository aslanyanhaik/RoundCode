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

import Accelerate

final class RCMatrix {
  
  //MARK: Properties
  let rows: Int
  var columns: Int {
    data.count / rows
  }
  var data: [Int8]
  
  //MARK: Inits
  init(size: Int) {
    self.rows = size
    data = Array(repeating: 0, count: rows * rows)
  }
  
  init(rows: Int, columns: Int) {
    self.rows = rows
    data = Array(repeating: 0, count: rows * columns)
  }
  
  init(columns: Int, items: [Int8]) {
    guard items.count % columns == 0 else {
      fatalError("number of columns are not matching")
    }
    self.rows = items.count / columns
    self.data = items
  }
  
  init(rows: Int, items: [Int8]) {
    guard items.count % rows == 0 else {
      fatalError("number of rows are not matching")
    }
    self.rows = rows
    self.data = items
  }
}

//MARK: Public methods
extension RCMatrix {
  static func identity(size: Int) -> RCMatrix {
    let matrix = RCMatrix(size: size)
    (0..<size).forEach({matrix[$0, $0] = 1})
    return matrix
  }
  
  subscript(column: Int, row: Int) -> Int8 {
    get {
      return data[self.rows * row + column]
    }
    set {
      data[self.rows * row + column] = newValue
    }
  }
  
  func row(for index: Int) -> [Int8] {
    let range = (columns * index)..<(columns * (index + 1))
    return Array(data[range])
  }
  
  func column(for index: Int) -> [Int8] {
    let indexes = stride(from: 0, to: data.count, by: self.columns).map({$0})
    return indexes.map({data[index + $0]})
  }
  
  func rowsData() -> [[Int8]] {
    return stride(from: 0, to: data.count, by: self.columns).map { index in
      Array(data[index ..< min(index + self.columns, data.count)])
    }
  }
  
  func subMatrix(rowMin: Int, columnMin: Int, rowMax: Int, columnMax: Int) -> RCMatrix {
    let data = rowsData()[rowMin...rowMax].map({$0[columnMin...columnMax]}).flatMap({$0})
    return RCMatrix(rows: (rowMin...rowMax).count, items: data)
  }
  
  func multiply(by matrix: RCMatrix) -> RCMatrix {
    guard self.columns == matrix.rows else {
      fatalError("Cannot subract matrices of different dimensions")
    }
    var currentData = self.data.map({Float($0)})
    var matrixData = matrix.data.map({Float($0)})
    var result = [Float](repeating: 0, count: self.rows * matrix.columns)
    vDSP_mmul(&currentData, 1, &matrixData, 1, &result, 1, UInt(self.rows), UInt(matrix.columns), UInt(self.columns))
    return RCMatrix(rows: self.rows, items: result.map({Int8($0)}))
  }
  
  func invert() {
    guard rows == columns else {
      fatalError("Only square matrices can be inverted")
    }
    var invertedData = data.map({Double($0)})
    var size = __CLPK_integer(self.rows)
    var pivots = [__CLPK_integer](repeating: 0, count: Int(size))
    var workspace = [Double](repeating: 0.0, count: Int(size))
    var error = __CLPK_integer(0)
    withUnsafeMutablePointer(to: &size) {
      dgetrf_($0, $0, &invertedData, $0, &pivots, &error)
      dgetri_($0, &invertedData, $0, &pivots, &workspace, $0, &error)
    }
    guard error == 0 else {
      fatalError("error inverting matrix: Error(\(error))")
    }
    invertedData.enumerated().forEach { value in
      self.data[value.offset] = Int8(value.element)
    }
  }
}

//MARK: CustomStringConvertible
extension RCMatrix: CustomStringConvertible {
  var description: String {
    var message = "columns: \(columns), rows: \(rows) \n"
    rowsData().forEach { row in
      row.forEach({message += " \($0)"})
      message += "\n"
    }
    return message
  }
}
