//
//  ViewController.swift
//

import UIKit
import SceneKit
import ARKit


struct MenuItem {
    var caption: String
    var id: String
}

struct MenuAction {
    var dictionary: NSDictionary
    
    var type: String {
        return dictionary["Type"] as? String ?? "Unknown"
    }
    
    var signalID: String? {
        return dictionary["SignalID"] as? String
    }
    
    var applianceID: String? {
        return dictionary["ApplianceID"] as? String
    }
    
    var button: String? {
        return dictionary["Button"] as? String
    }
    
    var temperature: Int? {
        return dictionary["Temperature"] as? Int
    }
    
    init(dictionary: NSDictionary) {
        self.dictionary = dictionary
    }
}

struct BoundingBox {
    var dictionary: NSDictionary
    
    var position: SCNVector3 {
        return vector3(for: "Position")
    }
    
    var scale: SCNVector3 {
        return vector3(for: "Scale")
    }
    
    private func vector3(for key: String) -> SCNVector3 {
        guard let dic = self.dictionary[key] as? NSDictionary else {
            fatalError("No dictionary for key: \(key)")
        }
        guard let x = dic["x"] as? NSNumber, let y = dic["y"] as? NSNumber, let z = dic["z"] as? NSNumber else {
            fatalError("Failed to parse \(key) dictionary: \(dic)")
        }
        return SCNVector3(x: x.floatValue, y: y.floatValue, z: z.floatValue)
    }
    
    init(dictionary: NSDictionary) {
        self.dictionary = dictionary
    }
}

class ViewController: UIViewController, ARSCNViewDelegate {
    
    let accessToken = ""
    
    @IBOutlet var sceneView: ARSCNView!
    private var menuItems: [String: [MenuItem]]?
    private var menuActions: [String: MenuAction]?
    private var boundingBoxes: [String: BoundingBox]?
    
    private var remoAPI: RemoAPI?
    
    private let ciContext = CIContext()
    private let gammaAdjustFilter = CIFilter(name: "CIGammaAdjust")!
    private var backgroundDarkened: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadApplianceList()
        
        remoAPI = RemoAPI(accessToken: accessToken)
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false
        sceneView.debugOptions = []
        
        // Create a new scene
        
        //        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        //
        //        // Set the scene to the view
        //        sceneView.scene = scene
        let overlayScene = InformationOverlayScene(size: sceneView.frame.size)
        overlayScene.isUserInteractionEnabled = false
        sceneView.overlaySKScene = overlayScene
    }
    
    private func loadApplianceList() {
        guard let url = Bundle.main.url(forResource: "Appliances", withExtension: "plist") else {
            fatalError("Appliances.plist not found.")
        }
        guard let appliances = NSArray(contentsOf: url) else {
            fatalError("invalid format: Appliances.plist")
        }
        
        var menuItems = [String: [MenuItem]]()
        var menuActions = [String: MenuAction]()
        var boundingBoxes = [String: BoundingBox]()
        for appliance in appliances {
            var applianceMenuItems = [MenuItem]()
            guard let dic = appliance as? NSDictionary else {
                fatalError("Unexpected object in root array \(appliance)")
            }
            guard let applianceKey = dic["Key"] as? String else {
                fatalError("No appliance key or unexpected object \(appliance)")
            }
            guard let menuArray = dic["MenuItems"] as? NSArray else {
                fatalError("No menu items or non-array object in \(applianceKey)")
            }
            for menuObject in menuArray {
                let menuID = UUID().uuidString
                guard let menuDic = menuObject as? NSDictionary else {
                    fatalError("Unexpected object in MenuItems of \(applianceKey)")
                }
                guard let menuCaption = menuDic["Caption"] as? String else {
                    fatalError("No caption in menu \(menuDic)")
                }
                guard let menuActionDic = menuDic["Action"] as? NSDictionary else {
                    fatalError("No action in menu \(menuDic)")
                }
                let menuAction = MenuAction(dictionary: menuActionDic)
                
                applianceMenuItems.append(MenuItem(caption: menuCaption, id: menuID))
                menuActions[menuID] = menuAction
            }
            if let boundingBoxDic = dic["BoundingBox"] as? NSDictionary {
                boundingBoxes[applianceKey] = BoundingBox(dictionary: boundingBoxDic)
            }
            menuItems[applianceKey] = applianceMenuItems
        }
        self.menuItems = menuItems
        self.menuActions = menuActions
        self.boundingBoxes = boundingBoxes
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil)!
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let location = touches.first?.location(in: sceneView) else {
            return
        }
        if let overlay = sceneView.overlaySKScene as? InformationOverlayScene {
            overlay.touchedAt(x: location.x, y: overlay.size.height - location.y)
        }
        
        guard let result = sceneView.hitTest(location, options: nil).first else {
            return
        }
        
        var currentNode: SCNNode? = result.node
        while true {
            guard let node = currentNode else {
                break
            }
            
            if node is MarkerNode || node is MenuItemNode {
                break
            }
            
            currentNode = node.parent
        }
        
        switch currentNode {
        case let node as MarkerNode:
            toggleMenu(markerNode: node)
        case let menuNode as MenuItemNode:
            onMenuNodeTouched(menuNode)
        default:
            debugPrint("No action with touched node")
        }
    }
    
    private func onMenuNodeTouched(_ menuNode: MenuItemNode) {
        guard let menuNodeID = menuNode.id else {
            debugMessage("ERROR: Touched menu node has no ID.")
            return
        }
        menuNode.flash(duration: 0.3)
        debugMessage("TAPPED MENU ITEM: \(menuNodeID)")
        performMenuAction(uuid: menuNodeID)
        menuNode.marker.isMenuOpen = false
        menuNode.marker.runRippleAnimation()
    }
    
    private func performMenuAction(uuid: String) {
        guard let menuAction = self.menuActions?[uuid] else {
            debugMessage("No menu action for \(uuid)")
            return
        }
        debugMessage("\(menuAction.type)")
        
        switch menuAction.type {
        case "Signal":
            guard let signalID = menuAction.signalID else {
                debugMessage("ERROR: NO SIGNAL ID")
                return
            }
            sendSignal(signalID: signalID)
        case "ACSettings":
            guard let applianceID = menuAction.applianceID else {
                debugMessage("ERROR: NO APPLIANCE ID")
                return
            }
            sendACSignal(signalID: applianceID, temperature: menuAction.temperature, button: menuAction.button ?? "")
        default:
            debugMessage("Unknown action: \(menuAction.type)")
        }
    }
    
    private func debugMessage(_ message: String) {
        (sceneView.overlaySKScene as? InformationOverlayScene)?.pushMessage(message)
    }
    
    private func sendSignal(signalID: String) {
        let signalDigest = signalID.prefix(7)
        debugMessage("SIGNAL \(signalDigest)")
        remoAPI?.sendSignal(signalID) { (response, error) in
            if let response = response {
                self.debugMessage("\(signalDigest) RESPONSE: \(response)")
            }
            if let error = error {
                self.debugMessage("\(signalDigest) ERROR: \(error.localizedDescription)")
            }
        }
    }
    
    private func sendACSignal(signalID: String, temperature: Int?, button: String) {
        let applianceDigest = signalID.prefix(7)
        debugMessage("APPLIANCE \(applianceDigest)")
        remoAPI?.sendACSettings(applianceID: signalID, temperature: temperature, button: button) { (response, error) in
            if let response = response {
                self.debugMessage("\(applianceDigest) RESPONSE: \(response)")
            }
            if let error = error {
                self.debugMessage("\(applianceDigest) ERROR: \(error.localizedDescription)")
            }
        }
    }
    
    private func toggleMenu(markerNode: MarkerNode) {
        markerNode.isMenuOpen = !markerNode.isMenuOpen
        backgroundDarkened = markerNode.isMenuOpen // TODO: 複数メニューがオープンされた時のケースを考慮する
        if markerNode.isMenuOpen {
            debugMessage("OPEN MENU: \(markerNode.name!)")
        } else {
            debugMessage("DISMISS MENU: \(markerNode.name!)")
        }
        markerNode.addTouchAnimation()
    }
    
    // MARK: - ARSCNViewDelegate
    
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let imageAnchor = anchor as? ARImageAnchor else {
            return nil
        }
        guard let anchorName = imageAnchor.name else {
            debugMessage("Image anchor with no name.")
            return nil
        }
        
        guard let menuItems = self.menuItems?[anchorName] else {
            debugMessage("No menus available for \(anchorName)")
            return nil
        }
        
        let node = MarkerNode(imageAnchor: imageAnchor, menus: menuItems)
        
        if let boundingBox = self.boundingBoxes?[anchorName] {
            node.setBoundingBox(boundingBox, texture: UIImage(named: "2dmesh")!)
        }
        
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let currentFrame = sceneView.session.currentFrame else { return }
        
        let ciImage = CIImage(cvPixelBuffer: currentFrame.capturedImage)
        gammaAdjustFilter.setValue(ciImage, forKey: kCIInputImageKey)
        gammaAdjustFilter.setValue(backgroundDarkened ? 3 : 1, forKey: "inputPower")
        
        let screenSize = UIScreen.main.bounds.size
        let scaleW = ciImage.extent.width / screenSize.width
        let scaleH = ciImage.extent.height / screenSize.height
        let scale = min(scaleW, scaleH)
        let cropWidth = screenSize.width * scale
        let cropHeight = screenSize.height * scale
        
        if let gammaAdjusted = gammaAdjustFilter.outputImage,
            let cgImage = ciContext.createCGImage(gammaAdjusted, from: CGRect(x: (ciImage.extent.width - cropWidth) * 0.5, y: (ciImage.extent.height - cropHeight) * 0.5, width: cropWidth, height: cropHeight)) {
            sceneView.scene.background.contents = cgImage
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
