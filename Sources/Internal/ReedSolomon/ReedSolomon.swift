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

class ReedSolomon {
  
  private var matrix: RCMatrix!
  var parityRows = [[Int8]]()
  
  func encode(_ shards: [RCBit]) -> [RCBit] {
    matrix = vandermonde(rows: shards.count, columns: shards.count + 1)
//    parityRows = new byte [parityShardCount] [];
//    for (int i = 0; i < parityShardCount; i++) {
//      parityRows[i] = matrix.getRow(dataShardCount + i);
//    }
//    
    
    
    
    return []
  }
  
  func isDataCorrect() -> Bool {
    return true
  }
}

extension ReedSolomon {
  func vandermonde(rows: Int, columns: Int) -> RCMatrix {
    let matrix = RCMatrix(rows: rows, columns: columns)
    (0..<rows).forEach { row in
      (0..<columns).forEach { column in
        matrix[row, column] = GaloisField.shared.exp(a: Int8(row), n: column)
      }
    }
    return matrix
  }
}
