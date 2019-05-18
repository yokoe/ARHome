import UIKit
import SceneKit

class MenuItemNode: SCNNode {
    var id: String!
    var marker: MarkerNode!
    
    var highlightNode: SCNNode {
        return childNode(withName: "highlight", recursively: true)!
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("Not supported")
    }
    
    init(marker: MarkerNode, menu: MenuItem) {
        super.init()
        let markerScene = SCNScene(named: "art.scnassets/marker.scn")!
        self.marker = marker
        
        guard let menuRootNode = markerScene.rootNode.childNode(withName: "menuItem", recursively: true) else {
            fatalError("No menuItem node in scene")
        }
        menuRootNode.position = SCNVector3Zero
        addChildNode(menuRootNode)
        
        highlightNode.opacity = 0
        
        guard let captionNode = menuRootNode.childNode(withName: "caption", recursively: false) else {
            fatalError("No caption node")
        }
        guard let textGeometry = captionNode.geometry as? SCNText else {
            fatalError("No text node")
        }
        
        textGeometry.string = menu.caption
        
        self.id = menu.id
    }
    
    func flash(duration: TimeInterval) {
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.fromValue = 1
        anim.toValue = 0
        anim.duration = duration
        highlightNode.addAnimation(anim, forKey: "hlAnim")
    }
}
