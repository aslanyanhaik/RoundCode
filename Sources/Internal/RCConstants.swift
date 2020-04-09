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

import CoreGraphics

struct RCConstants {
  static let maxBitesPerSection = 60
  static let topLevelBitesCount = 20
  static let middleLevelBitesCount = 20
  static let bottomLevelBitesCount = 20
  
  static let imageScale: CGFloat = 0.8
  static let dotSizeScale: CGFloat = 0.08
  static let dotPatterns: [CGFloat] = [6, 4, 2]
  static let dotPointRange = (Float(1.6)...Float(2.2))
  static let pixelThreshold = 180
  static let emptyCharacters: [Character] = ["\u{0540}", "\u{0531}"]
  static let startingCharacter: Character = "\u{058D}"
  
  
  
  
  static let level1BitesCount = 23
  static let level2BitesCount = 23
  static let level3BitesCount = 23

}
