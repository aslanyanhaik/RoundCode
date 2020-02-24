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
  var data: [Float]
  
  //MARK: Inits
  init(size: Int) {
    self.rows = size
    data = [Float](repeating: 0, count: rows * rows)
  }
  
  init(rows: Int, columns: Int) {
    self.rows = rows
    data = [Float](repeating: 0, count: rows * columns)
  }
  
  init(columns: Int, items: [Float]) {
    guard items.count % columns == 0 else {
      fatalError("number of columns are not matching")
    }
    self.rows = items.count / columns
    self.data = items
  }
  
  init(rows: Int, items: [Float]) {
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
  
  subscript(row: Int, column: Int) -> Float {
    get {
      return data.withUnsafeBufferPointer { buffer in
        return buffer[self.rows * row + column]
      }
    }
    set {
      data.withUnsafeMutableBufferPointer { buffer in
        buffer[self.rows * row + column] = newValue
      }
    }
  }
  
  func row(for index: Int) -> [Float] {
    return data.withUnsafeBufferPointer { buffer in
      let range = (columns * index)..<(columns * (index + 1))
      return Array(buffer[range])
    }
  }
  
  func column(for index: Int) -> [Float] {
    return stride(from: 0, to: data.count, by: self.columns).map { rowIndex in
      data.withUnsafeBufferPointer { buffer in
        return buffer[index + rowIndex]
      }
    }
  }
  
  func rowsData() -> [[Float]] {
    return data.withUnsafeBufferPointer { buffer in
      stride(from: 0, to: data.count, by: self.columns).map { index in
        Array(buffer[index ..< min(index + self.columns, data.count)])
      }
    }
  }
  
  func columnsData() -> [[Float]] {
    return data.withUnsafeBufferPointer { buffer in
      let rowIndexes = (0..<self.columns).map({$0})
      return rowIndexes.map { index in
        return stride(from: 0, to: data.count, by: self.columns).map { rowIndex in
          return buffer[index + rowIndex]
        }
      }
    }
  }
  
  func swap(row firstRow: Int, with lastRow: Int) {
    var rowsData = self.rowsData()
    rowsData.swapAt(firstRow, lastRow)
    self.data = rowsData.flatMap({$0})
  }
  
  func multiply(by matrix: RCMatrix) -> RCMatrix {
    guard self.columns == matrix.rows else {
      fatalError("Cannot subract matrices of different dimensions")
    }
    var result = [Float](repeating: 0, count: self.rows * matrix.columns)
    vDSP_mmul(self.data, 1, matrix.data, 1, &result, 1, UInt(self.rows), UInt(matrix.columns), UInt(self.columns))
    return RCMatrix(rows: self.rows, items: result)
  }
  
  func augment(by matrix: RCMatrix) -> RCMatrix {
    guard self.rows == matrix.rows else {
      fatalError("Matrices don't have the same number of rows")
    }
    let data = zip(self.rowsData(), matrix.rowsData()).map({$0.0 + $0.1}).flatMap({$0})
    return RCMatrix(rows: self.rows, items: data)
  }
  
  func inverted() -> RCMatrix {
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
    return RCMatrix(rows: self.rows, items: invertedData.map({Float($0)}))
  }
  
  func subMatrix(rowMin: Int, columnMin: Int, rowMax: Int, columnMax: Int) -> RCMatrix {
    let data = rowsData()[rowMin...rowMax].map({$0[columnMin...columnMax]}).flatMap({$0})
    return RCMatrix(rows: (rowMin...rowMax).count, items: data)
  }
}

//MARK: Equatable
extension RCMatrix: Equatable {
  static func == (lhs: RCMatrix, rhs: RCMatrix) -> Bool {
    return lhs.data == rhs.data
  }
}

//MARK: CustomStringConvertible
extension RCMatrix: CustomStringConvertible {
  var description: String {
    var message = "columns: \(columns), rows: \(rows)"
    rowsData().forEach({message += "\n \($0.description)"})
    return message
  }
}
