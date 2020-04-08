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

final class RCBitCoder {
  
  private let configuration: RCCoderConfiguration
  
  init(configuration: RCCoderConfiguration) {
    self.configuration = configuration
  }
}

extension RCBitCoder {
  func encode(message: String) throws -> RCData {
    var specialCharacters = RCConstants.emptyCharacters
    specialCharacters.append(RCConstants.startingCharacter)
    guard message.map({$0}).allSatisfy({configuration.characters.contains($0) && !specialCharacters.contains($0)}) else {
      throw RCError.invalidCharacter
    }
    guard message.count <= configuration.maxMessageCount else {
      throw RCError.longText
    }
    var dataBytes = message.map({configuration.characters.firstIndex(of: $0)!})
    dataBytes.insert(configuration.characters.firstIndex(of: RCConstants.startingCharacter)!, at: 0)
    let emptyIndexes = RCConstants.emptyCharacters.map({configuration.characters.firstIndex(of: $0)!})
    let randomBytes = (0..<configuration.maxMessageCount).map({_ in emptyIndexes[Int.random(in: 0..<emptyIndexes.count)]})
    dataBytes.append(contentsOf: randomBytes)
    dataBytes = Array(dataBytes.prefix(configuration.maxMessageCount))
    let encodedBits = dataBytes.map { byte -> [RCBit] in
      var stringValue = String(repeating: "0", count: configuration.bitesPerSymbol)
      stringValue += String(byte, radix: 2)
      return stringValue.suffix(configuration.bitesPerSymbol).compactMap({RCBit($0)})
    }.flatMap({$0})
    var totalBits = [RCBit](repeating: .zero, count: RCConstants.maxBitesPerSection * 3)
    totalBits.insert(contentsOf: encodedBits, at: 0)
    totalBits = Array(totalBits.prefix(RCConstants.maxBitesPerSection * 3))
    //reed solomon
    return RCData(totalBits)
  }
  
  
  func decode(_ bits: [RCBit]) throws -> String {
    guard bits.contains(.one) else { return "" }
    //decode bits to indexes
    let bytes = stride(from: 0, to: bits.count, by: configuration.bitesPerSymbol).map {
      Array(bits[$0 ..< min($0 + configuration.bitesPerSymbol, bits.count)])
    }
    var indexes = bytes.map({ bits in
      return bits.reduce(0) { accumulated, current in
        accumulated << 1 | current.rawValue
      }
    })
    var sectionIndexes = indexes.chunked(into: 4)
    let startingIndex = configuration.characters.firstIndex(of: RCConstants.startingCharacter)!
    guard let firstSectionIndex = sectionIndexes.firstIndex(where: {$0.first == startingIndex}) else {
      throw RCError.decoding
    }
    let previousSections = Array(sectionIndexes.prefix(firstSectionIndex))
    sectionIndexes = Array(sectionIndexes.dropFirst(firstSectionIndex))
    sectionIndexes.append(contentsOf: previousSections)
    //reed solomon check
    let emptyIndexes = RCConstants.emptyCharacters.map({configuration.characters.firstIndex(of: $0)!})
    indexes = Array(sectionIndexes.flatMap({$0}).prefix(configuration.maxMessageCount)).filter({!emptyIndexes.contains($0)})
    guard (indexes.max() ?? 0) <= configuration.characters.count else {
      throw RCError.wrongConfiguration
    }
    return String(indexes.compactMap({configuration.characters[$0]}))
  }
}
