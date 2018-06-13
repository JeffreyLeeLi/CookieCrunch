/**
 * GameScene.swift
 * CookieCrunch
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import SpriteKit
import GameplayKit

class GameScene: SKScene {
  // Sound FX
  let swapSound = SKAction.playSoundFileNamed("Chomp.wav", waitForCompletion: false)
  let invalidSwapSound = SKAction.playSoundFileNamed("Error.wav", waitForCompletion: false)
  let matchSound = SKAction.playSoundFileNamed("Ka-Ching.wav", waitForCompletion: false)
  let fallingCookieSound = SKAction.playSoundFileNamed("Scrape.wav", waitForCompletion: false)
  let addCookieSound = SKAction.playSoundFileNamed("Drip.wav", waitForCompletion: false)
  
  var level: Level!
  
  let tileWidth : CGFloat = 32.0
  let tileHeight: CGFloat = 36.0
  
  let gameLayer   = SKNode()
  let cookieLayer = SKNode()
  
  let tileLayer = SKNode()
  let maskLayer = SKNode()
  let cropLayer = SKCropNode()
  
  private var selectedSprite = SKSpriteNode()
  
  private var swipeFromColumn: Int?
  private var swipeFromRow   : Int?
  
  var swipeHandler: ((Swap) -> Void)?
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder) is not used in this app")
  }
  
  override init(size: CGSize) {
    super.init(size: size)
    
    self.anchorPoint = CGPoint(x: 0.5, y: 0.5)
    
    let background = SKSpriteNode(imageNamed: "Background")
    background.size = self.size
    self.addChild(background)
    
    self.addChild(self.gameLayer)
    
    let position = CGPoint(x: -self.tileWidth*CGFloat(numColumns)/2.0, y: -self.tileHeight*CGFloat(numRows)/2.0)
    
    self.tileLayer.position = position
    self.gameLayer.addChild(self.tileLayer)
    
    self.maskLayer.position = position
    self.gameLayer.addChild(self.cropLayer)
    
    self.cookieLayer.position = position
    self.cropLayer.addChild(self.cookieLayer)
    
    self.cropLayer.maskNode = self.maskLayer
  }
  
  func highlight(cookie: Cookie) {
    if let sprite = cookie.sprite {
      let name = cookie.type.highlightedSpriteName
      let texture = SKTexture(imageNamed: name)
      
      self.selectedSprite.size = CGSize(width: self.tileWidth, height: self.tileHeight)
      self.selectedSprite.run(SKAction.setTexture(texture))
      self.selectedSprite.alpha = 1.0
      
      sprite.addChild(self.selectedSprite)
    }
  }
  
  func hidelight() {
    self.selectedSprite.run(SKAction.sequence([
      SKAction.fadeOut(withDuration: 0.3),
      SKAction.removeFromParent()
    ]))
  }
  
  func addTiles() {
    for column in 0..<numColumns {
      for row in 0..<numRows {
        if self.level.tileAt(column: column, row: row) == nil {
          continue
        }
        
        let sprite = SKSpriteNode(imageNamed: "MaskTile")
        
        sprite.size = CGSize(width: self.tileWidth, height: self.tileHeight)
        sprite.position = positionForCookieAt(column: column, row: row)
        
        self.maskLayer.addChild(sprite)
      }
    }
    
    for column in 0...numColumns {
      for row in 0...numRows {
        let tl = (column > 0) && (row < numRows) && self.level.tileAt(column: column-1, row: row) != nil
        let bl = (column > 0) && (row > 0) && self.level.tileAt(column: column-1, row: row-1) != nil
        let tr = (column < numColumns) && (row < numRows) && self.level.tileAt(column: column, row: row) != nil
        let br = (column < numColumns) && (row > 0) && self.level.tileAt(column: column, row: row-1) != nil
        
        var value = 0
        
        value = value | tl.hashValue << 0
        value = value | tr.hashValue << 1
        value = value | bl.hashValue << 2
        value = value | br.hashValue << 3
        
        if value != 0 && value != 6 && value != 9 {
          let name = String(format: "Tile_%ld", value)
          let sprite = SKSpriteNode(imageNamed: name)
          
          sprite.size = CGSize(width: self.tileWidth, height: self.tileHeight)
          sprite.position = self.positionForTileAt(column: column, row: row)
          
          self.tileLayer.addChild(sprite)
        }
      }
    }
  }
  
  func addSprites(for cookies : Set<Cookie>) {
    for cookie in cookies {
      let sprite = SKSpriteNode(imageNamed: cookie.type.spriteName)
      
      sprite.size = CGSize(width: self.tileWidth, height: self.tileHeight)
      sprite.position = self.positionForCookieAt(column: cookie.column, row: cookie.row)
      
      self.cookieLayer.addChild(sprite)
      
      cookie.sprite = sprite
    }
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else {
      return
    }
    
    let location = touch.location(in: self.cookieLayer)
    let (success, column, row) = self.convertPoint(point: location)
    
    if !success {
      return
    }
    
    if let cookie = self.level.cookieAt(column: column, row: row) {
      self.highlight(cookie: cookie)
      
      self.swipeFromColumn = column
      self.swipeFromRow    = row
    }
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard self.swipeFromColumn != nil else {
      return
    }
    
    guard self.swipeFromRow != nil else {
      return
    }
    
    guard let touch = touches.first else {
      return
    }
    
    let location = touch.location(in: self.cookieLayer)
    let (success, column, row) = self.convertPoint(point: location)
    
    if !success {
      return
    }
    
    var horizontalDelta = 0
    var verticalDelta   = 0
    
    if column < self.swipeFromColumn! {
      horizontalDelta = -1
    } else if column > self.swipeFromColumn! {
      horizontalDelta = 1
    } else if row < self.swipeFromRow! {
      verticalDelta = -1
    } else if row > self.swipeFromRow! {
      verticalDelta = 1
    }
    
    if horizontalDelta == 0 && verticalDelta == 0 {
      return
    }
    
    trySwap(horizontalDelta: horizontalDelta, verticalDelta: verticalDelta)
    
    self.hidelight()
    
    self.swipeFromColumn = nil
    self.swipeFromRow    = nil
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.swipeFromColumn = nil
    self.swipeFromRow    = nil
  }
  
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    self.touchesEnded(touches, with: event)
  }
  
  private func positionForTileAt(column: Int, row: Int) -> CGPoint {
    return CGPoint(x: CGFloat(column)*self.tileWidth, y: CGFloat(row)*self.tileHeight)
  }
  
  private func positionForCookieAt(column: Int, row: Int) -> CGPoint {
    return CGPoint(x: CGFloat(column)*self.tileWidth+self.tileWidth/2.0, y: CGFloat(row)*self.tileHeight+self.tileHeight/2.0)
  }
  
  private func convertPoint(point: CGPoint) -> (success: Bool, column: Int, row: Int) {
    if 0 <= point.x && point.x < CGFloat(numColumns)*self.tileWidth && 0 <= point.y && point.y < CGFloat(numRows)*self.tileHeight {
      return (true, Int(point.x/self.tileWidth), Int(point.y/self.tileHeight))
    } else {
      return (false, 0, 0)
    }
  }
  
  private func trySwap(horizontalDelta: Int, verticalDelta: Int) {
    let toColumn = self.swipeFromColumn! + horizontalDelta
    let toRow    = self.swipeFromRow!    + verticalDelta
    
    guard 0 <= toColumn && toColumn < numColumns else {
      return
    }
    
    guard 0 <= toRow && toRow < numRows else {
      return
    }
    
    if let toCookie = self.level.cookieAt(column: toColumn, row: toRow), let fromCookie = self.level.cookieAt(column: self.swipeFromColumn!, row: self.swipeFromRow!) {
      if let handler = self.swipeHandler {
        let swap = Swap(cookieOne: fromCookie, cookieAnother: toCookie)
        handler(swap)
      }
    }
  }
  
  func animate(swap: Swap, completion: @escaping() -> Void) {
    let spriteOne     = swap.cookieOne.sprite!
    let spriteAnother = swap.cookieAnother.sprite!
    
    spriteOne.zPosition     = 100
    spriteAnother.zPosition = 90
    
    let duration: TimeInterval = 0.3
    
    let moveOne = SKAction.move(to: spriteAnother.position, duration: duration)
    moveOne.timingMode = .easeOut
    spriteOne.run(moveOne, completion: completion)
    
    let moveAnother = SKAction.move(to: spriteOne.position, duration: duration)
    moveAnother.timingMode = .easeOut
    spriteAnother.run(moveAnother, completion: completion)
    
    self.run(swapSound)
  }
  
  func animateInvalid(swap: Swap, completion: @escaping() -> Void) {
    let spriteOne     = swap.cookieOne.sprite!
    let spriteAnother = swap.cookieAnother.sprite!
    
    spriteOne.zPosition     = 100
    spriteAnother.zPosition = 90
    
    let duration: TimeInterval = 0.2
    
    let moveOne = SKAction.move(to: spriteAnother.position, duration: duration)
    moveOne.timingMode = .easeOut
    
    let moveAnother = SKAction.move(to: spriteOne.position, duration: duration)
    moveAnother.timingMode = .easeOut
    
    spriteOne.run(SKAction.sequence([moveOne, moveAnother]), completion: completion)
    spriteAnother.run(SKAction.sequence([moveAnother, moveOne]))
    
    self.run(invalidSwapSound)
  }
}


