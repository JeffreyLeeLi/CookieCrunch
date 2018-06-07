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

let numColumns = 9
let numRows    = 9

class Level {
  private var tiles = Array2D<Tile>(columns: numColumns, rows: numRows)
  private var cookies = Array2D<Cookie>(columns: numColumns, rows: numRows)
  
  init(filename: String) {
    guard let data = LevelData.loadFrom(file: filename) else {
      return
    }
    
    let tileArray = data.tiles
    for (i, array) in tileArray.enumerated() {
      let row = numRows-i-1
      
      for (j, value) in array.enumerated() {
        let column = j
        
        if value == 1 {
          self.tiles[column, row] = Tile()
        }
      }
    }
  }
  
  func shuffle() -> Set<Cookie> {
    var aSet: Set<Cookie> = []
    
    for column in 0..<numColumns {
      for row in 0..<numRows {
        let type = CookieType.random()
        let cookie = Cookie(column: column, row: row, type: type)
        
        self.cookies[column, row] = cookie
        aSet.insert(cookie)
      }
    }
    
    return aSet
  }
  
  func cookieAt(column: Int, row: Int) -> Cookie? {
    precondition(0 <= column && column < numColumns)
    precondition(0 <= row && row < numRows)
    
    return self.cookies[column, row]
  }
  
  func tileAt(column: Int, row: Int) -> Tile? {
    precondition(0 <= column && column < numColumns)
    precondition(0 <= row && row < numRows)
    
    return self.tiles[column, row]
  }
}
