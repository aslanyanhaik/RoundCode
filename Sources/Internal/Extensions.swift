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

extension Array {
  func chunked(into size: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: count / size).map {
      Array(self[$0 ..< Swift.min($0 + count / size, count)])
    }
  }
}

extension UInt8 {
  var bits: [RCBit] {
    var bytes = self
    var bits = [RCBit](repeating: .zero, count: self.bitWidth)
    (0..<bitWidth).forEach { index in
      let currentBit = bytes & 0x01
      if currentBit != 0 {
        bits[index] = .one
      }
      bytes >>= 1
    }
    return bits
  }
}

extension Array where Self.Element == RCBit {
  func bytes() -> [UInt8] {
    let numBits = count
    let numBytes = (numBits + 7) / 8
    var bytes = [UInt8](repeating: 0, count: numBytes)
    self.enumerated().forEach { item in
      if item.element == .one {
        bytes[item.offset / 8] += 1 << (7 - item.offset % 8)
      }
    }
    return  bytes
  }
}
