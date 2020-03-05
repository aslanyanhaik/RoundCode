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
  
  func encode(message: String) throws -> [[[RCBitGroup]]] {
    guard message.trimmingCharacters(in: configuration.characterSet).isEmpty else {
      throw RCError.invalidCharacter
    }
    guard message.count <= configuration.maxMessageCount else {
      throw RCError.longText
    }
    let dataBytes = message.map({configuration.symbols.firstIndex(of: $0)!})
    let emptyIndexes = configuration.emptySymbolsIndex()
    var randomBytes = (0..<configuration.maxMessageCount).map({_ in emptyIndexes[Int.random(in: 0..<emptyIndexes.count)]})
    randomBytes.insert(contentsOf: dataBytes, at: 0)
    randomBytes = Array(randomBytes.prefix(configuration.maxMessageCount))
    let encodedBits = randomBytes.map { byte -> [RCBit] in
      var stringValue = String(repeating: "0", count: configuration.bitesPerSymbol)
      stringValue += String(byte, radix: 2)
      return stringValue.suffix(configuration.bitesPerSymbol).compactMap({RCBit($0)})
    }.flatMap({$0})
    var totalBits = [RCBit](repeating: .zero, count: RCConstants.maxBites)
    totalBits.insert(contentsOf: encodedBits, at: 0)
    totalBits = Array(totalBits.prefix(RCConstants.maxBites))
    let bitChunks = [RCConstants.level1BitesCount, RCConstants.level2BitesCount, RCConstants.level3BitesCount].map { count in
      return (0...3).map { _ -> [RCBit] in // 4 groups
        let bitChunk = Array(totalBits.prefix(count))
        totalBits = Array(totalBits.dropFirst(count))
        return bitChunk
      }
    }
    let bitGroups = zip(bitChunks[0], zip(bitChunks[1], bitChunks[2])).map {[$0.0, $0.1.0, $0.1.1]}.map { group in
      group.map { row -> [RCBitGroup] in
        var bitGroupRow = [RCBitGroup(bit: row[0], count: 0, offset: 0)]
        row.enumerated().forEach { value  in
          bitGroupRow.last!.bit == value.element ? bitGroupRow.last!.count += 1 : bitGroupRow.append(RCBitGroup(bit: value.element, count: 1, offset: value.offset))
        }
        return bitGroupRow
      }
    }
    return bitGroups
  }
  
  func decode(_ bits: [RCBit]) throws -> String {
    guard bits.contains(.one) else { return "" }
    let emptyIndexes = configuration.emptySymbolsIndex()
    let bitChunks = stride(from: 0, to: bits.count, by: configuration.bitesPerSymbol).map {
      Array(bits[$0 ..< min($0 + configuration.bitesPerSymbol, bits.count)])
    }
    var indexes = bitChunks.map({ bits in
      return bits.reduce(0) { accumulated, current in
        accumulated << 1 | current.rawValue
      }
    })
    indexes = Array(indexes.prefix(configuration.maxMessageCount)).filter({!emptyIndexes.contains($0)})
    guard (indexes.max() ?? 0) <= configuration.symbols.count else {
      throw RCError.wrongConfiguration
    }
    return String(indexes.compactMap({configuration.symbols[$0]}))
  }
}
