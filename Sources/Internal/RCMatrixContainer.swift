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

final class RCMatrixContainer {
  
  //MARK: Properties
  let rows: Int
  var columns: Int {
    data.count / rows
  }
  let data: UnsafeMutableBufferPointer<UInt8>
  
  init(columns: Int, items: UnsafeMutableBufferPointer<UInt8>) {
    guard items.count % columns == 0 else {
      fatalError("number of columns are not matching")
    }
    self.rows = items.count / columns
    self.data = items
  }
  
  init(rows: Int, items: UnsafeMutableBufferPointer<UInt8>) {
    guard items.count % rows == 0 else {
      fatalError("number of rows are not matching")
    }
    self.rows = rows
    self.data = items
  }
  
  subscript(column: Int, row: Int) -> UInt8 {
    get {
      return data[self.rows * row + column]
    }
    set {
      data[self.rows * row + column] = newValue
    }
  }
}
