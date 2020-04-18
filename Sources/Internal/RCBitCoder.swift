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

struct RCBitCoder {
  
  private let configuration: RCCoderConfiguration
  
  init(configuration: RCCoderConfiguration) {
    self.configuration = configuration
  }
}

extension RCBitCoder {
  func encode(message: String) throws -> [RCBit] {
    var specialCharacters = configuration.version.emptyCharacters
    specialCharacters.append(configuration.version.startingCharacter)
    guard message.map({$0}).allSatisfy({configuration.characters.contains($0) && !specialCharacters.contains($0)}) else {
      throw RCError.invalidCharacter
    }
    guard message.count <= configuration.maxMessageCount else {
      throw RCError.longText
    }
    guard !message.isEmpty else {
      return [RCBit](repeating: .zero, count: configuration.version.maxBitesPerSection * 4)
    }
    //mapping into character indexes
    var indexes = message.map({configuration.characters.firstIndex(of: $0)!})
    //adding staring character index and filling with special indexes
    indexes.insert(configuration.characters.firstIndex(of: configuration.version.startingCharacter)!, at: 0)
    let emptyIndexes = configuration.version.emptyCharacters.map({configuration.characters.firstIndex(of: $0)!})
    let randomBytes = (0...configuration.maxMessageCount).map({_ in emptyIndexes[Int.random(in: 0..<emptyIndexes.count)]})
    indexes.append(contentsOf: randomBytes)
    indexes = Array(indexes.prefix(configuration.maxMessageCount + 1))
    //encoding into bits
    let encodedBits = indexes.map { byte -> [RCBit] in
      var stringValue = String(repeating: "0", count: configuration.bitesPerSymbol)
      stringValue += String(byte, radix: 2)
      return stringValue.suffix(configuration.bitesPerSymbol).compactMap({RCBit($0)})
    }.flatMap({$0})
    //filling with empty bits
    var totalBits = [RCBit](repeating: .zero, count: configuration.version.maxBitesPerSection * 3)
    totalBits.insert(contentsOf: encodedBits, at: 0)
    totalBits = Array(totalBits.prefix(configuration.version.maxBitesPerSection * 3))
    //calculating parity
    let parityBits = parity(for: totalBits)
    totalBits.append(contentsOf: parityBits)
    return totalBits
  }
  
  
  func decode(_ bits: [RCBit]) throws -> String {
    //starting character to bits
    var startingIndexCharacter = String(repeating: "0", count: configuration.bitesPerSymbol)
    startingIndexCharacter += String(configuration.characters.firstIndex(of: configuration.version.startingCharacter)!, radix: 2)
    let startingIndexBits = startingIndexCharacter.suffix(configuration.bitesPerSymbol).compactMap({RCBit($0)})
    //chunked into 4 sections
    var sectionBytes = bits.chunked(into: 4)
    //get starting section index
    guard let firstSectionIndex = sectionBytes.firstIndex(where: { sectionBits in
      zip(sectionBits.prefix(startingIndexBits.count), startingIndexBits).allSatisfy({$0 == $1})
    }) else {
      throw RCError.decoding
    }
    //fix arrangement of sections
    let previousSections = Array(sectionBytes.prefix(firstSectionIndex))
    sectionBytes = Array(sectionBytes.dropFirst(firstSectionIndex))
    sectionBytes.append(contentsOf: previousSections)
    let parityBits = sectionBytes.last!
    let dataBits = sectionBytes.dropLast().flatMap({$0})
    //validate data
    guard validate(parityData: parityBits, data: dataBits) else {
      throw RCError.decoding
    }
    //mapping to custom size byte
    let bytes = stride(from: 0, to: dataBits.count, by: configuration.bitesPerSymbol).map {
      Array(dataBits[$0 ..< min($0 + configuration.bitesPerSymbol, dataBits.count)])
    }.prefix(configuration.maxMessageCount + 1)
    //converting binary into decimal
    let indexes = bytes.map({ bits in
      return bits.reduce(0) { accumulated, current in
        accumulated << 1 | current.rawValue
      }
    })
    var characters = indexes.compactMap({configuration.characters[$0]})
    //removing staring and random characters
    var redundantCharacters = configuration.version.emptyCharacters
    redundantCharacters.append(configuration.version.startingCharacter)
    characters = characters.filter({!redundantCharacters.contains($0)})
    return String(characters)
  }
}

extension RCBitCoder {
  private func parity(for data: [RCBit]) -> [RCBit] {
    let bytes = data.bytes()
    var parityMatrix = RCMatrix(rows: 1, items: configuration.version.parityTable)
    let dataMatrix = RCMatrix(rows: configuration.version.parityTable.count, items: bytes)
    parityMatrix = parityMatrix.reducedMultiply(by: dataMatrix)
    return parityMatrix.data.map({$0.bits}).flatMap({$0})
  }
  
  private func validate(parityData: [RCBit], data: [RCBit]) -> Bool {
    let validationParity = parity(for: data)
    return zip(parityData, validationParity).allSatisfy({$0 == $1})
  }
}
