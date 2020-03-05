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

public final class RCCoderConfiguration {
  
  public let maxMessageCount: Int
  public let symbols: [Character]
  public let bitesPerSymbol: Int
  internal let emptySymbols: [Character]
  internal let characterSet: CharacterSet
  
  public init(symbols: String, shouldFillEmptySpace: Bool = true) {
    self.characterSet = CharacterSet(charactersIn: symbols.map({String($0)}).reduce("", +))
    var symbolsArray = symbols.map({$0})
    if shouldFillEmptySpace {
      self.emptySymbols = RCConstants.emptySymbols
      symbolsArray.insert(emptySymbols[0], at: symbolsArray.count / 3)
      symbolsArray.insert(emptySymbols[1], at: symbolsArray.count / 3 * 2)
    } else {
      self.emptySymbols = [RCConstants.emptySymbols[0]]
      symbolsArray.insert(emptySymbols[0], at: 0)
    }
    self.symbols = symbolsArray
    self.bitesPerSymbol = String(symbols.count, radix: 2).count
    self.maxMessageCount = RCConstants.maxBites / bitesPerSymbol
  }
  
  func indexOf(symbol: Character) -> Int {
    return symbols.firstIndex(of: symbol)!
  }
  
  func emptySymbolsIndex() -> [Int] {
    return emptySymbols.map({symbols.firstIndex(of: $0)!})
  }
  
  public static var uuidConfiguration: RCCoderConfiguration {
    return RCCoderConfiguration(symbols: "-ABCDEF0123456789")
  }
  
  public static var numericConfiguration: RCCoderConfiguration {
    return RCCoderConfiguration(symbols: ".,_0123456789")
  }
  
  public static var shortConfiguration: RCCoderConfiguration {
    return RCCoderConfiguration(symbols: " -abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
  }
  
  public static var defaultConfiguration: RCCoderConfiguration {
    return RCCoderConfiguration(symbols: ##"! "#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~"##)
  }
}
