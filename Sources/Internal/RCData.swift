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

struct RCBitSection {
  
  var topLevel = [RCBit]()
  var middleLevel = [RCBit]()
  var bottomLevel = [RCBit]()
}

struct RCData {
  
  var firstShard = RCBitSection()
  var secondShard = RCBitSection()
  var thirdShard = RCBitSection()
  var parity = RCBitSection()
  
  init(_ bits: [RCBit]) {
    let sections = bits.chunked(into: 4).map { sectionBits -> RCBitSection in
      var data = sectionBits
      var section = RCBitSection()
      section.topLevel = Array(data.prefix(RCConstants.topLevelBitesCount))
      data = Array(data.dropFirst(RCConstants.topLevelBitesCount))
      section.middleLevel = Array(data.prefix(RCConstants.middleLevelBitesCount))
      data = Array(data.dropFirst(RCConstants.middleLevelBitesCount))
      section.bottomLevel = data
      return section
    }
    firstShard = sections[0]
    secondShard = sections[1]
    thirdShard = sections[2]
    parity = sections[3]
  }
}


final class RCBitGroup1 {
  
  var bit: RCBit
  var count: Int
  var offset: Int
  
  init(bit: RCBit, count: Int, offset: Int) {
    self.bit = bit
    self.count = count
    self.offset = offset
  }
}

extension RCBitGroup1: CustomDebugStringConvertible {
  var debugDescription: String {
    "bit: \(bit), count: \(count), offset: \(offset) \n"
  }
}

