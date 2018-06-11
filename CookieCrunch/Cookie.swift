/// Copyright (c) 2018 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation
import SpriteKit

enum CookieType: Int {
  case unknown = 0, croissant, cupcake, danish, donut, macaroon, sugarCookie
  
  var spriteName: String {
    let names = [
      "Unknown",
      
      "Croissant",
      "Cupcake",
      "Danish",
      "Donut",
      "Macaroon",
      "SugarCookie",
    ]
    
    return names[rawValue]
  }
  
  var highlightedSpriteName: String {
    return spriteName + "-Highlighted"
  }
  
  static func random() -> CookieType {
    let aValue = arc4random_uniform(6) + 1
    return CookieType(rawValue: Int(aValue))!
  }
}

class Cookie: Hashable, CustomStringConvertible {
  var column: Int
  var row   : Int
  
  let type: CookieType
  
  var sprite: SKSpriteNode?
  
  var description: String {
    return "Type: \(self.type) Square: [\(self.column), \(self.row)]"
  }
  
  init(column: Int, row: Int, type: CookieType) {
    self.column = column
    self.row = row
    
    self.type = type
  }
  
  var hashValue: Int {
    return self.row*9 + self.column
  }
  
  static func ==(one: Cookie, another: Cookie) -> Bool {
    return (one.column == another.column) && (one.row == another.row)
  }
}
