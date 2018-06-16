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
  
  private var possibleSwaps: Set<Swap> = []
  
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
  
  func initialSet() -> Set<Cookie> {
    var set: Set<Cookie>
    
    repeat {
      set = self.generateShuffleCookies()
      self.possibleSwaps = self.detectPossibleSwaps()
    } while (self.possibleSwaps.count == 0)
    
    return set
  }
  
  func isPossible(swap: Swap) -> Bool {
    return self.possibleSwaps.contains(swap)
  }
  
  private func hasChainForCookieAt(column: Int, row: Int) -> Bool {
    let type = self.cookieAt(column: column, row: row)?.type
    
    var horizontalLength = 1
    var i = 0
    
    i = column-1
    while i >= 0 && self.cookieAt(column: i, row: row)?.type == type {
      i-=1
      horizontalLength+=1
    }
    
    i = column+1
    while i < numColumns && self.cookieAt(column: i, row: row)?.type == type {
      i+=1
      horizontalLength+=1
    }
    
    if horizontalLength >= 3 {
      return true
    }
    
    var verticalLength = 1
    var j = 0
    
    j = row-1
    while j > 0 && self.cookieAt(column: column, row: j)?.type == type {
      j-=1
      verticalLength+=1
    }
    
    j = row+1
    while j < numRows && self.cookieAt(column: column, row: j)?.type == type {
      j+=1
      verticalLength+=1
    }
    
    if verticalLength >= 3 {
      return true
    }
    
    return false
  }
  
  func generateShuffleCookies() -> Set<Cookie> {
    var aSet: Set<Cookie> = []
    
    for column in 0..<numColumns {
      for row in 0..<numRows {
        if self.tiles[column, row] == nil {
          continue
        }
        
        var type: CookieType
        repeat {
          type = CookieType.random()
        } while(
          (column >= 2 && self.cookies[column-1, row]?.type == type && self.cookies[column-2, row]?.type == type)
          ||
          (row >= 2 && self.cookies[column, row-1]?.type == type && self.cookies[column, row-2]?.type == type)
        )
        
        let cookie = Cookie(column: column, row: row, type: type)
        
        self.cookies[column, row] = cookie
        aSet.insert(cookie)
      }
    }
    
    return aSet
  }
  
  func detectPossibleSwaps() -> Set<Swap> {
    var aSet: Set<Swap> = []
    
    for column in 0..<numColumns {
      for row in 0..<numRows {
        if let one = self.cookieAt(column: column, row: row) {
          if column < numColumns-1, let another = self.cookieAt(column: column+1, row: row) {
            self.cookies[column, row] = another
            self.cookies[column+1, row] = one
            
            if self.hasChainForCookieAt(column: column, row: row) || self.hasChainForCookieAt(column: column+1, row: row) {
              aSet.insert(Swap(cookieOne: one, cookieAnother: another))
            }
            
            self.cookies[column, row] = one
            self.cookies[column+1, row] = another
          }
          
          if row < numRows-1, let another = self.cookieAt(column: column, row: row+1) {
            self.cookies[column, row] = another
            self.cookies[column, row+1] = one
            
            if self.hasChainForCookieAt(column: column, row: row) || self.hasChainForCookieAt(column: column, row: row+1) {
              aSet.insert(Swap(cookieOne: one, cookieAnother: another))
            }
            
            self.cookies[column, row] = one
            self.cookies[column, row+1] = another
          }
        }
      }
    }
    
    return aSet
  }
  
  func detectAllChains() -> Set<Chain> {
    let horizontalChains = self.detectHorizontalChains()
    let verticalChains = self.detectVerticalChains()
    
    return horizontalChains.union(verticalChains)
  }
  
  private func detectHorizontalChains() -> Set<Chain> {
    var aSet: Set<Chain> = []
    
    for row in 0..<numRows {
      var column = 0
      while column < numColumns-2 {
        if let cookie = self.cookieAt(column: column, row: row) {
          let type = cookie.type
          
          if self.cookieAt(column: column+1, row: row)?.type == type && self.cookieAt(column: column+2, row: row)?.type == type {
            let chain = Chain(type: .horizontal)
            column+=1
            repeat {
              chain.add(cookie: cookie)
            } while column < numColumns && self.cookieAt(column: column, row: row)?.type == type
            
            aSet.insert(chain)
            
            continue
          }
        }
        
        column+=1
      }
    }
    
    return aSet
  }
  
  private func detectVerticalChains() -> Set<Chain> {
    var aSet: Set<Chain> = []
    
    for column in 0..<numColumns {
      var row = 0
      while row < numRows-2 {
        if let cookie = self.cookieAt(column: column, row: row) {
          let type = cookie.type
          
          if self.cookieAt(column: column, row: row+1)?.type == type && self.cookieAt(column: column, row: row+2)?.type == type {
            let chain = Chain(type: .horizontal)
            row+=1
            repeat {
              chain.add(cookie: cookie)
            } while row < numRows && self.cookieAt(column: column, row: row)?.type == type
            
            aSet.insert(chain)
            
            continue
          }
        }
        
        row+=1
      }
    }
    
    return aSet
  }
  
  func performSwap(swap: Swap) {
    let columnOne = swap.cookieOne.column
    let rowOne = swap.cookieOne.row
    
    let columnAnother = swap.cookieAnother.column
    let rowAnother = swap.cookieAnother.row
    
    self.cookies[columnOne, rowOne] = swap.cookieAnother
    self.cookies[columnAnother, rowAnother] = swap.cookieOne
    
    swap.cookieOne.column = columnAnother
    swap.cookieOne.row = rowAnother
    
    swap.cookieAnother.column = columnOne
    swap.cookieAnother.row = rowOne
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
