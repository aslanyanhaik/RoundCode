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

public struct RCCoderConfiguration {
  
  public let symbols: [Character]
  public let maxMessageCount: Int
  internal let bitesPerSymbol: Int
  internal lazy var characterSet: CharacterSet = {
    CharacterSet(charactersIn: symbols.map({String($0)}).reduce("", +))
  }()
  
  public init(symbols: String, maxMessageCount: Int) throws {
    var hash = [Character : Int]()
    for value in symbols.enumerated() {
      if hash[value.element] != nil {
        throw RCCoderConfigurationError.containsDuplicateSymbols
      }
      hash[value.element] = value.offset
    }
    self.symbols = symbols.map({$0})
    self.maxMessageCount = maxMessageCount
    self.bitesPerSymbol = String(symbols.count, radix: 2).count
  }
  
  public static var uuidConfiguration: RCCoderConfiguration {
    return try! RCCoderConfiguration(symbols: "-abcdef0123456789", maxMessageCount: 36)
  }
  
  public static var numericConfiguration: RCCoderConfiguration {
    return try! RCCoderConfiguration(symbols: ".,_0123456789", maxMessageCount: 25)
  }
  
  public static var defaultConfiguration: RCCoderConfiguration {
    return try! RCCoderConfiguration(symbols: " -abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789", maxMessageCount: 32)
  }
  
  public static var asciiConfiguration: RCCoderConfiguration {
    return try! RCCoderConfiguration(symbols: ##"! "#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~"##, maxMessageCount: 42)
  }
}

public extension RCCoderConfiguration {
  
  enum RCCoderConfigurationError: Error {
    case containsDuplicateSymbols
  }
}
