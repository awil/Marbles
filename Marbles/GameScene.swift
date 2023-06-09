//
//  GameScene.swift
//  Marbles
//
//  Created by Aaron Williams on 6/8/23.
//

import CoreMotion
import SpriteKit
//import GameplayKit


// Marbles - This class sets up the ball/marble object
class Ball: SKSpriteNode {
    let radius: CGFloat
    let ballColor: UIColor
    
    init(radius: CGFloat, color: UIColor) {
        self.radius = radius
        ballColor = color
        let size = CGSize(width: radius * 2, height: radius * 2)
        super.init(texture: nil, color: .clear, size: size)
        
        draw()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func draw() {
        let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: radius)
        
        let shapeNode = SKShapeNode(path: path.cgPath)
        shapeNode.fillColor = ballColor
        shapeNode.strokeColor = .clear
        
        addChild(shapeNode)
    }
}

// This class draws the scene
class GameScene: SKScene {
    // Setup the colors for the marbles
    var balls: [UIColor] = [.blue, .red, .orange, .yellow, .green, .purple]
    // Motion manager to determine tilt of device
    var motionManager: CMMotionManager?
    // Score label
    let scoreLabel = SKLabelNode(fontNamed: "AvenirNextCondensed-Medium")
    // Set to hold matches
    var matchedBalls = Set<Ball>()
    
    // Setup score
    var score = 0 {
        didSet {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            let formattedScore = formatter.string(from: score as NSNumber) ?? "0"
            scoreLabel.text = "SCORE: \(formattedScore)"
        }
    }
    
    // Main function that sets up the scene
    override func didMove(to view: SKView) {
        // Place the label/format it
        scoreLabel.fontSize = 72
        scoreLabel.position = CGPoint(x: 20, y: 40)
        scoreLabel.text = "SCORE: 0"
        scoreLabel.zPosition = 100
        scoreLabel.horizontalAlignmentMode = .left
        addChild(scoreLabel)
        
        // Setup ball to fit 8 on the screen
        let ballRadius = (view.bounds.width/8.0) / 2.0
        let ball = Ball(radius: ballRadius, color: .blue)
        
        print(view.frame.width)
        
        print(view.safeAreaInsets.left)
        print(view.safeAreaInsets.right)
        
        // Draw the marbles
        for i in stride(from: 0, to: view.bounds.width - ballRadius*3.0, by: ball.frame.width) {
            for j in stride(from: 100, to: view.bounds.height - ballRadius * 4.0, by: ball.frame.height) {
                let ballType = balls.randomElement()!
                let ball = Ball(radius: ballRadius, color: ballType)
                ball.position = CGPoint(x: i, y: j)
                ball.name = "\(ballType)"
                
                ball.physicsBody = SKPhysicsBody(circleOfRadius: ballRadius)
                ball.physicsBody?.allowsRotation = false
                ball.physicsBody?.restitution = 0
                ball.physicsBody?.friction = 0
                
                addChild(ball)
                
            }
        }
        
        // Setup physics for the game
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame.inset(by: UIEdgeInsets(top: 100, left: 0, bottom: 0, right: ballRadius * 2.0)))
        
        motionManager = CMMotionManager()
        motionManager?.startAccelerometerUpdates()
        

    }
    
    // Updates the scene physics
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        if let accelerometerData = motionManager?.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.x * 50, dy: accelerometerData.acceleration.y * 50)
        }
    }
    
//    func getMatches(from node: Ball) {
//        for body in node.physicsBody!.allContactedBodies() {
//            guard let ball = body.node as? Ball else { continue }
//            guard ball.name == node.name else { continue }
//            
//            if !matchedBalls.contains(ball) {
//                matchedBalls.insert(ball)
//                getMatches(from: ball)
//            }
//        }
//    }
    
    // Find the matches that are available based on proximity
    func getMatches(from startBall: Ball) {
        let matchWidth = startBall.frame.width * startBall.frame.width * 2.1
        
        for node in children {
            guard let ball = node as? Ball else { continue }
            guard ball.name == startBall.name else { continue }
            
            let dist = distance(from: startBall, to: ball)
            
            guard dist < matchWidth else { continue }
            
            if !matchedBalls.contains(ball) {
                matchedBalls.insert(ball)
                getMatches(from: ball)
            }
        }
    }
    
    // Determine distance
    func distance(from: Ball, to: Ball) -> CGFloat {
        return (from.position.x - to.position.x) * (from.position.x - to.position.x) + (from.position.y - to.position.y) * (from.position.y - to.position.y)
    }
    
    // Handle marble touches
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard let position = touches.first?.location(in: self) else { return }
        
        guard let tappedBall = nodes(at: position).first(where: { $0 is Ball }) as? Ball else { return }
        
        matchedBalls.removeAll(keepingCapacity: true)
        
        getMatches(from: tappedBall)
        
        if matchedBalls.count >= 2 {
            score += Int(pow(2, Double(min(matchedBalls.count, 16))))
            for ball in matchedBalls {
                if let particles = SKEmitterNode(fileNamed: "Spark") {
                    particles.position = ball.position
                    addChild(particles)
                    
                    let removeAfterDead = SKAction.sequence([SKAction.wait(forDuration: 3), SKAction.removeFromParent()])
                    particles.run(removeAfterDead)
                }
                ball.removeFromParent()
            }
        }
    }
}
