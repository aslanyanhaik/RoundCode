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

import UIKit

public final class RCCoder {
  
  public let configuration: RCCoderConfiguration
  
  public init(configuration: RCCoderConfiguration = .defaultConfiguration) {
    self.configuration = configuration
  }
}

public extension RCCoder {
  func encode(_ image: RCImage) throws -> UIImage {
    let bits = try encode(message: image.message)
    let bitChunks = stride(from: 0, to: bits.count, by: bits.count / 4).map({Array(bits[$0 ..< min($0 + bits.count / 4, bits.count)])})
    image.bits = bitChunks.map { chunk -> [[RCBit]] in
      return [0..<RCConstants.level1BitesCount, RCConstants.level1BitesCount..<RCConstants.level1BitesCount + RCConstants.level2BitesCount, RCConstants.level1BitesCount + RCConstants.level2BitesCount..<RCConstants.level1BitesCount + RCConstants.level2BitesCount + RCConstants.level3BitesCount].map({Array(chunk[$0])})
    }
    let drawer = RCDrawer(image: image)
    return drawer.draw()
  }
  
  func decode(_ data: UIImage) throws -> String {
    
    return ""
  }
  
  func validate(_ text: String) -> Bool {
    return text.trimmingCharacters(in: configuration.characterSet).isEmpty && text.count <= configuration.maxMessageCount
  }
}

extension RCCoder {
  private func encode(message: String) throws -> [RCBit] {
    guard validate(message) else { throw RCCoderError.inValidText }
    let dataBytes = message.map({configuration.symbols.firstIndex(of: $0)! + 1})
    let encodedBits = dataBytes.map { byte -> [RCBit] in
      var stringValue = String(repeating: "0", count: configuration.bitesPerSymbol)
      stringValue += String(byte, radix: 2)
      return stringValue.suffix(configuration.bitesPerSymbol).compactMap({RCBit($0)})
    }.flatMap({$0})
    var totalBits = [RCBit](repeating: .zero, count: RCConstants.maxBites)
    totalBits.insert(contentsOf: encodedBits, at: 0)
    return Array(totalBits.prefix(RCConstants.maxBites))
  }
  
  private func decode(_ bits: [RCBit]) throws -> String {
    let bitChunks = stride(from: 0, to: bits.count, by: configuration.bitesPerSymbol).map {
      Array(bits[$0 ..< min($0 + configuration.bitesPerSymbol, bits.count)])
    }
    let indexes = bitChunks.map({ bits in
      return bits.reduce(0) { accumulated, current in
        accumulated << 1 | current.rawValue
      }
    }).filter({$0 != 0})
    guard (indexes.max() ?? 0) <= configuration.symbols.count else {
      throw RCCoderError.wrongConfiguration
    }
    return String(indexes.compactMap({configuration.symbols[$0 - 1]}))
  }
}

public extension RCCoder {
  enum RCCoderError: String, Error {
    case inValidText
    case wrongConfiguration
  }
}
