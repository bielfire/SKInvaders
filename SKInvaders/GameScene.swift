/**
 * Copyright (c) 2016 Razeware LLC
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
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import SpriteKit
import CoreMotion

let motionManager = CMMotionManager()
var tapQueue = [Int]()

class GameScene: SKScene {
    
    enum BulletType {
        case shipFired
        case invaderFired
    }
    
    // Private GameScene Properties
    enum InvaderMovementDirection {
        case right
        case left
        case downThenRight
        case downThenLeft
        case none
    }
    
    var contentCreated = false
    
    // Invaders begin by moving to the right.
    var invaderMovementDirection: InvaderMovementDirection = .right
    
    // Invaders haven't moved yet, so set the time to zero.
    var timeOfLastMove: CFTimeInterval = 0.0
    
    // Invaders take 1 second for each move. Each step left, right or down takes 1 second.
    let timePerMove: CFTimeInterval = 1.0
    
    enum InvaderType {
        case a
        case b
        case c
        
        static var size: CGSize {
            return CGSize(width: 24, height: 16)
        }
        
        static var name: String {
            return "invader"
        }
    }
    
    let kInvaderGridSpacing = CGSize(width: 12, height: 12)
    let kInvaderRowCount = 6
    let kInvaderColCount = 6
    // O kShipSize armazena o tamanho da nave
    let kShipSize = CGSize(width: 30, height: 16)
    // kShipName armazena o nome que você definirá no nó do sprite
    let kShipName = "ship"
    // pontuação
    let kScoreHudName = "scoreHud"
    // saúde
    let kHealthHudName = "healthHud"
    
    let kShipFiredBulletName = "shipFiredBullet"
    let kInvaderFiredBulletName = "invaderFiredBullet"
    let kBulletSize = CGSize(width:4, height: 8)
    
    // Object Lifecycle Management
    
    // Scene Setup and Content Creation
    override func didMove(to view: SKView) {
        
        if (self.contentCreated == false) {
            self.createContent()
            self.contentCreated = true
            motionManager.startAccelerometerUpdates()
        }
    }
    
    func createContent() {
        
        setupInvaders()
        setupShip()
        setupHud()
        
        // black space color
        self.backgroundColor = SKColor.black
    }
    
    func makeInvader(ofType invaderType: InvaderType) -> SKNode {
        
        // 1
        var invaderColor: SKColor
        
        switch(invaderType) {
        case .a:
            invaderColor = SKColor.red
        case .b:
            invaderColor = SKColor.green
        case .c:
            invaderColor = SKColor.blue
        }
        
        // 2
        let invader = SKSpriteNode(color: invaderColor, size: InvaderType.size)
        invader.name = InvaderType.name
        
        
        return invader
    }
    
    func setupInvaders() {
        // 1
        let baseOrigin = CGPoint(x: size.width / 3, y: size.height / 2)
        
        for row in 0..<kInvaderRowCount {
            // 2
            var invaderType: InvaderType
            
            if row % 3 == 0 {
                invaderType = .a
            } else if row % 3 == 1 {
                invaderType = .b
            } else {
                invaderType = .c
            }
            
            // 3
            let invaderPositionY = CGFloat(row) * (InvaderType.size.height * 2) + baseOrigin.y
            
            var invaderPosition = CGPoint(x: baseOrigin.x, y: invaderPositionY)
            
            // 4
            for _ in 1..<kInvaderColCount {
                // 5
                let invader = makeInvader(ofType: invaderType)
                invader.position = invaderPosition
                
                addChild(invader)
                
                invaderPosition = CGPoint(
                    x: invaderPosition.x + InvaderType.size.width + kInvaderGridSpacing.width,
                    y: invaderPositionY
                )
            }
        }
    }
    
    func setupShip() {
        // 1
        let ship = makeShip()
        
        // 2
        ship.position = CGPoint(x: size.width / 2.0, y: kShipSize.height / 2.0)
        addChild(ship)
    }
    
    func makeShip() -> SKNode {
        let ship = SKSpriteNode(color: SKColor.green, size: kShipSize)
        ship.name = kShipName
        // 1
        ship.physicsBody = SKPhysicsBody(rectangleOf: ship.frame.size)
        
        // 2
        ship.physicsBody!.isDynamic = true
        
        // 3
        ship.physicsBody!.affectedByGravity = false
        
        // 4
        ship.physicsBody!.mass = 0.02
        return ship
    }
    
    func setupHud() {
        // Give the score label a name
        let scoreLabel = SKLabelNode(fontNamed: "Courier")
        scoreLabel.name = kScoreHudName
        scoreLabel.fontSize = 25
        
        // Color the score label green.
        scoreLabel.fontColor = SKColor.green
        scoreLabel.text = String(format: "Score: %04u", 0)
        
        // Position the score label.
        scoreLabel.position = CGPoint(
            x: frame.size.width / 2,
            y: size.height - (40 + scoreLabel.frame.size.height/2)
        )
        addChild(scoreLabel)
        
        // Give the health label a name
        let healthLabel = SKLabelNode(fontNamed: "Courier")
        healthLabel.name = kHealthHudName
        healthLabel.fontSize = 25
        
        // Color the health label red
        healthLabel.fontColor = SKColor.red
        healthLabel.text = String(format: "Health: %.1f%%", 100.0)
        
        // Position the health below the score label.
        healthLabel.position = CGPoint(
            x: frame.size.width / 2,
            y: size.height - (80 + healthLabel.frame.size.height/2)
        )
        addChild(healthLabel)
    }
    
    func makeBullet(ofType bulletType: BulletType) -> SKNode {
        var bullet: SKNode
        
        switch bulletType {
        case .shipFired:
            bullet = SKSpriteNode(color: SKColor.green, size: kBulletSize)
            bullet.name = kShipFiredBulletName
        case .invaderFired:
            bullet = SKSpriteNode(color: SKColor.magenta, size: kBulletSize)
            bullet.name = kInvaderFiredBulletName
            break
        }
        
        return bullet
    }
    
    // Scene Update
    func moveInvaders(forUpdate currentTime: CFTimeInterval) {
        processUserMotion(forUpdate: currentTime)
        // 1
        if (currentTime - timeOfLastMove < timePerMove) {
            return
        }
        
        // 2
        enumerateChildNodes(withName: InvaderType.name) { node, stop in
            switch self.invaderMovementDirection {
            case .right:
                node.position = CGPoint(x: node.position.x + 10, y: node.position.y)
            case .left:
                node.position = CGPoint(x: node.position.x - 10, y: node.position.y)
            case .downThenLeft, .downThenRight:
                node.position = CGPoint(x: node.position.x, y: node.position.y - 10)
            case .none:
                break
            }
            
            // 3
            self.timeOfLastMove = currentTime
        }
    }
    
    func processUserMotion(forUpdate currentTime: CFTimeInterval) {
        // 1
        if let ship = childNode(withName: kShipName) as? SKSpriteNode {
            // 2
            if let data = motionManager.accelerometerData {
                // 3
                if fabs(data.acceleration.x) > 0.2 {
                    // 4 How do you move the ship?
                    ship.physicsBody!.applyForce(CGVector(dx: 40 * CGFloat(data.acceleration.x), dy: 0))                }
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // move invaders
        moveInvaders(forUpdate: currentTime)
        determineInvaderMovementDirection()
        /* Called before each frame is rendered */
    }
    
    // Scene Update Helpers
    
    // Invader Movement Helpers
    
    func determineInvaderMovementDirection() {
        // 1
        var proposedMovementDirection: InvaderMovementDirection = invaderMovementDirection
        
        // 2
        enumerateChildNodes(withName: InvaderType.name) { node, stop in
            
            switch self.invaderMovementDirection {
            case .right:
                //3
                if (node.frame.maxX >= node.scene!.size.width - 1.0) {
                    proposedMovementDirection = .downThenLeft
                    
                    stop.pointee = true
                }
            case .left:
                //4
                if (node.frame.minX <= 1.0) {
                    proposedMovementDirection = .downThenRight
                    
                    stop.pointee = true
                }
                
            case .downThenLeft:
                proposedMovementDirection = .left
                
                stop.pointee = true
                
            case .downThenRight:
                proposedMovementDirection = .right
                
                stop.pointee = true
                
            default:
                break
            }
            
        }
        
        //7
        if (proposedMovementDirection != invaderMovementDirection) {
            invaderMovementDirection = proposedMovementDirection
        }
    }
    
    // Bullet Helpers
    func fireBullet(bullet: SKNode, toDestination destination: CGPoint, withDuration duration: CFTimeInterval, andSoundFileName soundName: String) {
        // 1
        let bulletAction = SKAction.sequence([
            SKAction.move(to: destination, duration: duration),
            SKAction.wait(forDuration: 3.0 / 60.0),
            SKAction.removeFromParent()
        ])
        
        // 2
        let soundAction = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        
        // 3
        bullet.run(SKAction.group([bulletAction, soundAction]))
        
        // 4
        addChild(bullet)
    }
    
    func fireShipBullets() {
        let existingBullet = childNode(withName: kShipFiredBulletName)
        
        // 1
        if existingBullet == nil {
            if let ship = childNode(withName: kShipName) {
                let bullet = makeBullet(ofType: .shipFired)
                // 2
                bullet.position = CGPoint(
                    x: ship.position.x,
                    y: ship.position.y + ship.frame.size.height - bullet.frame.size.height / 2
                )
                // 3
                let bulletDestination = CGPoint(
                    x: ship.position.x,
                    y: frame.size.height + bullet.frame.size.height / 2
                )
                // 4
                fireBullet(
                    bullet: bullet,
                    toDestination: bulletDestination,
                    withDuration: 1.0,
                    andSoundFileName: "ShipBullet.wav"
                )
            }
        }
    }
    
    // User Tap Helpers
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if (touch.tapCount == 1) {
                tapQueue.append(1)
            }
        }
    }
    
    // HUD Helpers
    
    // Physics Contact Helpers
    
    // Game End Helpers
    
}
