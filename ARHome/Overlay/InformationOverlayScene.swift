import SpriteKit

private class MessageNode: SKNode {
    var y: CGFloat = 0
    private var lineHeight: CGFloat = 0
    
    private var labelNode: SKLabelNode!
    private var coverNode: SKNode!
    private var cropNode: SKCropNode!
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
    
    override init() {
        super.init()
    }
    
    init(text: String?, atPoint pos: CGPoint, lineHeight: CGFloat = 16) {
        super.init()
        
        let cropNode = SKCropNode()
        
        let labelNode = SKLabelNode(fontNamed: "Michroma")
        labelNode.fontSize = 12
        labelNode.text = text
        labelNode.color = UIColor.white
        labelNode.horizontalAlignmentMode = .left
        labelNode.verticalAlignmentMode = .bottom
        self.labelNode = labelNode
        
        let maskNode = SKShapeNode(rectOf: labelNode.frame.size)
        maskNode.fillColor = UIColor.white
        maskNode.xScale = 0
        maskNode.position = CGPoint(x: 0, y: labelNode.frame.size.height * 0.5)
        cropNode.maskNode = maskNode
        
        cropNode.addChild(labelNode)
        self.addChild(cropNode)
        self.cropNode = cropNode
        
        let coverNode = SKShapeNode(rectOf: labelNode.frame.size)
        coverNode.fillColor = UIColor.white
        coverNode.position = CGPoint(x: 0, y: labelNode.frame.size.height * 0.5)
        coverNode.xScale = 0
        self.coverNode = coverNode
        
        self.addChild(coverNode)
        
        self.position = pos
        self.y = self.frame.origin.y
        self.lineHeight = lineHeight
    }
    
    func runCoverAction(intro introDuration: TimeInterval, outro outroDuration: TimeInterval) {
        guard let labelNode = self.labelNode else { return }
        coverNode.run(
            SKAction.sequence([
                .group([
                    SKAction.moveTo(x: labelNode.frame.size.width * 0.5, duration: introDuration),
                    SKAction.scaleX(to: 1, duration: introDuration),
                    ]),
                .group([
                    SKAction.moveTo(x: labelNode.frame.size.width, duration: outroDuration),
                    SKAction.scaleX(to: 0, duration: outroDuration),
                    ]),
                .removeFromParent()
                ])
        )
        
    }
    
    func runMaskAction(startOffset: TimeInterval, stillDuration: TimeInterval) {
        guard let labelNode = self.labelNode else { return }
        cropNode.maskNode?.run(
            SKAction.sequence([
                .wait(forDuration: startOffset),
                .group([
                    .scaleX(to: 1, duration: 0.2),
                    .moveTo(x: labelNode.frame.size.width * 0.5, duration: 0.2)
                    ]),
                .wait(forDuration: stillDuration),
                .group([
                    .scaleX(to: 0, duration: 0.5),
                    .moveTo(x: labelNode.frame.size.width, duration: 0.5)
                    ])
                ])
        )
    }
    
    func pushUpward(duration: TimeInterval) {
        y += lineHeight
        removeAction(forKey: "pushUpward")
        run(.moveTo(y: y, duration: duration), withKey: "pushUpward")
    }
}

class InformationOverlayScene: SKScene {
    private var messageNodes = [MessageNode]()
    
    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .aspectFit
        
        let hov = SKSpriteNode(imageNamed: "head-overlay")
        hov.size = CGSize(width: size.width, height: size.width / hov.frame.size.width * hov.frame.size.height)
        hov.position = CGPoint(x: size.width * 0.5, y: size.height - hov.size.height * 0.5)
        addChild(hov)
        
        let df = DateFormatter()
        df.dateFormat = "HH:mm"
        let node = SKLabelNode(text: df.string(from: Date()))
        node.color = UIColor.white
        node.fontSize = 16
        node.fontName = "Michroma"
        node.horizontalAlignmentMode = .center
        node.verticalAlignmentMode = .center
        node.position = hov.position
        addChild(node)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func touchedAt(x: CGFloat, y: CGFloat) {
        let node = SKShapeNode(circleOfRadius: 25.0)
        node.position.x = x
        node.position.y = y
        node.fillColor = UIColor.yellow
        self.addChild(node)
        node.run(SKAction.scale(to: 2, duration: 0.4))
        node.run(SKAction.fadeOut(withDuration: 0.5), completion: {
            node.removeFromParent()
        })
    }
    
    func pushMessage(_ message: String) {
        addTextNode(message, atPoint: CGPoint(x: 10, y: 30))
    }
    
    private func addTextNode(_ text: String, atPoint pos: CGPoint) {
        for messageNode in messageNodes {
            messageNode.pushUpward(duration: 0.1)
        }
        
        let node = MessageNode(text: text, atPoint: pos)
        addChild(node)
        
        node.runCoverAction(intro: 0.2, outro: 0.2)
        node.runMaskAction(startOffset: 0.2, stillDuration: 4)
        
        node.run(SKAction.sequence([
            .wait(forDuration: 5.5),
            .removeFromParent(),
            ]), completion: {
                self.messageNodes = self.messageNodes.filter({ (tn) -> Bool in
                    tn != node
                })
        })
        
        messageNodes.append(node)
    }
}
