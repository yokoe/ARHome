//
//  MarkerNode.swift
//

import UIKit
import ARKit
import SceneKit

class MarkerNode: SCNNode {
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not supported")
    }
    
    private var coverNode: SCNNode? {
        return childNode(withName: "menuCapHighlight", recursively: true)
    }
    
    private var whiteOverlay: SCNNode? {
        return childNode(withName: "innerRing", recursively: true)
    }
    private var menuNodes = [SCNNode]()
    private var menuParentNode: SCNNode?
    private var imageAnchor: ARImageAnchor?
    
    private var boundingNode: SCNNode?
    
    var isMenuOpen: Bool = false {
        didSet {
            if oldValue != isMenuOpen {
                if isMenuOpen {
                    whiteOverlay?.runAction(.group([
                        .fadeOpacity(to: 1, duration: 0.2),
                        .scale(to: 1, duration: 0.2),
                        ]))
                    startMenuParentNodeAnim(duration: 0.15)
                } else {
                    whiteOverlay?.runAction(.group([
                        .fadeOpacity(to: 0, duration: 0.2),
                        .scale(to: 1.2, duration: 0.2),
                        ]))
                    
                    startMenuParentNodeAnim(reversed: true, duration: 0.3)
                }
                
                if let boundingNode = self.boundingNode {
                    let opacityAnim = CAKeyframeAnimation(keyPath: "opacity")
                    opacityAnim.keyTimes = [0, 0.5, 1]
                    opacityAnim.values = [0.6, 0.6, 0]
                    opacityAnim.duration = 1.2
                    boundingNode.addAnimation(opacityAnim, forKey: "opacityAnim")
                }
            }
        }
    }
    
    private func startMenuParentNodeAnim(reversed: Bool = false, duration: TimeInterval) {
        let target: CGFloat = reversed ? 0 : 1
        menuParentNode?.runAction(.fadeOpacity(to: target, duration: duration))
        for (i, menuItemNode) in menuNodes.enumerated() {
            let boxHeight = -0.06 * Float(i)
            menuItemNode.runAction(.move(to: SCNVector3(0, 0.001 * Float(i), -boxHeight * Float(target)), duration: duration))
        }
    }
    
    
    func addTouchAnimation() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.01
        animation.duration = 0.5
        coverNode?.addAnimation(animation, forKey: "opacityAnimation")
    }
    
    func runRippleAnimation() {
        guard let imageAnchor = self.imageAnchor else {
            debugPrint("No imageAnchor")
            return
        }
        for i in 0...2 {
            let node = fxRingNode(image: UIImage(named: "effect-ring\(i + 1)")!, radius: imageAnchor.referenceImage.physicalSize.width * 0.5, z: 0.011 + 0.001 * CGFloat(i))
            self.addChildNode(node)
            
            node.runAction(
                .sequence([
                    .unhide(),
                    .group([
                        .fadeOut(duration: 2),
                        .scale(to: 2, duration: 2),
                        .rotate(by: .pi * CGFloat(i % 2 == 0 ? 1: -1) * CGFloat(i % 3 == 0 ? 1.3 : 1), around: SCNVector3(0, 1, 0), duration: 2),
                        ]),
                    .removeFromParentNode()
                    ])
            )
        }
    }
    
    init(imageAnchor: ARImageAnchor, menus: [MenuItem]) {
        super.init()
        self.imageAnchor = imageAnchor
        self.name = imageAnchor.name
        
        let markerScene = SCNScene(named: "art.scnassets/marker.scn")!
        guard let overlays = markerScene.rootNode.childNode(withName: "markerOverlay", recursively: true) else {
            fatalError("no overlay")
        }
        overlays.scale = SCNVector3(x: Float(imageAnchor.referenceImage.physicalSize.width) + 0.1, y: Float(imageAnchor.referenceImage.physicalSize.width) + 0.1, z: Float(imageAnchor.referenceImage.physicalSize.width) + 0.1)
        addChildNode(overlays)
        
        whiteOverlay?.opacity = 0
        whiteOverlay?.scale = SCNVector3(1.2, 1.2, 1.2)
        
        coverNode?.opacity = 0
        
        guard let planeNode = markerScene.rootNode.childNode(withName: "marker", recursively: true) else {
            fatalError("No child node found")
        }
        
        guard let captionNode = planeNode.childNode(withName: "captionText", recursively: false) else {
            fatalError("No caption node")
        }
        
        guard let textGeometry = captionNode.geometry as? SCNText else {
            fatalError("No text node")
        }
        textGeometry.string = imageAnchor.name
        center(node: captionNode)
        captionNode.position = SCNVector3(0, 0, imageAnchor.referenceImage.physicalSize.height * 0.5 + 0.1)
        
        
        self.addChildNode(captionNode)
        
        setupMenuNode(menus: menus)
    }
    
    private func setupMenuNode(menus: [MenuItem]) {
        guard let imageAnchor = self.imageAnchor else { return }
        let menuParentNode = SCNNode(geometry: nil)
        for menu in menus {
            let menuNode = MenuItemNode(marker: self, menu: menu)
            menuNodes.append(menuNode)
            menuParentNode.addChildNode(menuNode)
        }
        self.menuParentNode = menuParentNode
        menuParentNode.opacity = 0
        menuParentNode.position = SCNVector3(imageAnchor.referenceImage.physicalSize.width + 0.13, 0, 0.02)
        self.addChildNode(menuParentNode)
    }
    
    private func fxRingNode(image: UIImage, radius: CGFloat, z: CGFloat) -> SCNNode {
        let fxRingContainerNode1 = SCNNode(geometry: nil)
        let fxRingNode1 = makeFocusRingNode(width: radius * 2, height: radius * 2, z: z, margin: 0.05, image: image)
        fxRingNode1.geometry?.materials.first?.blendMode = .add
        fxRingContainerNode1.addChildNode(fxRingNode1)
        return fxRingContainerNode1
    }
    
    func center(node: SCNNode) {
        let (min, max) = node.boundingBox
        
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        let dz = min.z + 0.5 * (max.z - min.z)
        node.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
    }
    
    func setBoundingBox(_ boundingBox: BoundingBox, texture: UIImage) {
        let boundingNode = SCNNode(geometry: nil)
        
        let plane = SCNPlane(width: CGFloat(boundingBox.scale.x), height: CGFloat(boundingBox.scale.y))
        plane.materials.first?.diffuse.contents = texture
        
        let boxNode = SCNNode(geometry: plane)
        boxNode.transform = SCNMatrix4Rotate(SCNMatrix4MakeTranslation(boundingBox.position.x, boundingBox.position.y, boundingBox.position.z), -.pi / 2, 1, 0, 0)
        boundingNode.addChildNode(boxNode)
        
        let plane2 = SCNPlane(width: CGFloat(boundingBox.scale.x), height: CGFloat(boundingBox.scale.y))
        plane2.materials.first?.diffuse.contents = texture
        
        let boxNode2 = SCNNode(geometry: plane2)
        boxNode2.transform = SCNMatrix4Rotate(SCNMatrix4MakeTranslation(boundingBox.position.x, boundingBox.position.y, boundingBox.position.z + boundingBox.scale.z), -.pi / 2, 1, 0, 0)
        boundingNode.addChildNode(boxNode2)
        
        boundingNode.opacity = 0
        self.addChildNode(boundingNode)
        
        self.boundingNode = boundingNode
    }
    
    private func makeFocusRingNode(width: CGFloat, height: CGFloat, z: CGFloat, margin: CGFloat, image: UIImage) -> SCNNode {
        let plane = SCNPlane(width: width + margin * 2, height: height + margin * 2)
        plane.firstMaterial?.diffuse.contents = image
        let planeNode = SCNNode(geometry: plane)
        planeNode.transform = SCNMatrix4Rotate(SCNMatrix4MakeTranslation(0, 0, Float(z)), -.pi / 2, 1, 0, 0)
        return planeNode
    }
}
