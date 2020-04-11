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
  
  public let version: Version
  public let maxMessageCount: Int
  public let bitesPerSymbol: Int
  public let characters: [Character]
  
  public init(version: Version = .v1, characters: String) {
    self.version = version
    var charactersArray = characters.map({$0})
    charactersArray.append(version.startingCharacter)
    charactersArray.append(contentsOf: version.emptyCharacters)
    self.characters = charactersArray
    self.bitesPerSymbol = String(charactersArray.count - 1, radix: 2).count
    self.maxMessageCount = version.maxBitesPerSection * 3 / bitesPerSymbol
  }
  
  func validate(_ text: String) -> Bool {
    var specialCharacters = version.emptyCharacters
    specialCharacters.append(version.startingCharacter)
    return text.map({$0}).allSatisfy({characters.contains($0) && !specialCharacters.contains($0)}) && text.count <= maxMessageCount
  }
  
  public static var uuidConfiguration: RCCoderConfiguration {
    return RCCoderConfiguration(characters: "-ABCDEF0123456789")
  }
  
  public static var numericConfiguration: RCCoderConfiguration {
    return RCCoderConfiguration(characters: ".,_0123456789")
  }
  
  public static var shortConfiguration: RCCoderConfiguration {
    return RCCoderConfiguration(characters: " -abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
  }
  
  public static var defaultConfiguration: RCCoderConfiguration {
    return RCCoderConfiguration(characters: ##"! "#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~"##)
  }
}

public extension RCCoderConfiguration {
  enum Version {
    case v1

    var maxBitesPerSection: Int {
      topLevelBitesCount + middleLevelBitesCount + bottomLevelBitesCount //should be multiple of 8
    }
    
    var topLevelBitesCount: Int {
      switch self {
        case .v1: return 16
      }
    }
    
    var middleLevelBitesCount: Int {
      switch self {
        case .v1: return 16
      }
    }
    
    var bottomLevelBitesCount: Int {
      switch self {
        case .v1: return 16
      }
    }
    
    var parityTable: [UInt8] {
      switch self {
        case .v1:
        return [0x03, 0x65, 0xB9]
      }
    }
    
    var emptyCharacters: [Character] {
      ["\u{0540}", "\u{0531}"]
    }
    
    var startingCharacter: Character { "\u{058D}" }
  }
}
