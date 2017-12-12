//
//  ViewController.swift
//  ARKitBasics
//
//  Created by Jared Davidson on 7/26/17.
//  Copyright © 2017 Archetapp. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
//
class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var dict = [String: Float]()
    let defaults = UserDefaults.standard
    var points: [[String: Float]] = []
    var anchors: [[String: Float]] = []
    var locations: [[String: Float]] = []
    var deviceNumber: Float = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // If ARAnchors are cached, recreate them
        if let anchorsCached = defaults.array(forKey: "anchors") as! [[String: Float]]?{
            print("recreating scenario with \(anchorsCached.count) anchors")
            recreateAnchors(anchors: anchorsCached)
        }
        
        // If Virtual objects are cached, recreate them
        if let array = defaults.array(forKey: "points") as! [[String: Float]]?{
            print("recreating scenario with \(array.count) nodes")
            recreateVirtualObjects(points: array)
        }
        
        //If positions from other ARSessions are cached, bring them back to memory and increment device number
        if let locationsFromCache = defaults.array(forKey: "locations") as! [[String: Float]]?{
            locations = locationsFromCache
            let lastItem = locations[locations.count-1]
            deviceNumber = lastItem["device"]!
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // Function to create balls at the touch of the screen.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let results = sceneView.hitTest(touch.location(in: sceneView), types: [ARHitTestResult.ResultType.featurePoint])
        guard let hitFeature = results.last else { return }
        let hitTransform = SCNMatrix4(hitFeature.worldTransform)
        saveMatrix(transform: hitTransform)
        let hitPosition = SCNVector3Make(hitTransform.m41,
                                         hitTransform.m42,
                                         hitTransform.m43)
        createBall(hitPosition: hitPosition)
    }
    
    // Help method to actually create virtual ball
    func createBall(hitPosition : SCNVector3) {
        let newBall = SCNSphere(radius: 0.01)
        let newBallNode = SCNNode(geometry: newBall)
        newBallNode.position = hitPosition
        print(newBallNode.position)
        self.sceneView.scene.rootNode.addChildNode(newBallNode)
        saveToCache(hitPosition: hitPosition)
    }
    
    func recreateVirtualObjects(points: [[String: Float]]) {
        for elem in points {
            let hitPosition = SCNVector3Make(elem["x"]!, elem["y"]!, elem["z"]!)
            createBall(hitPosition: hitPosition)
        }
    }
    
    func recreateAnchors(anchors: [[String: Float]]){
        for anchor in anchors{
            let transform = createTransform(dict: anchor)
            let matrix = simd_float4x4(transform)
            let anchor = ARAnchor(transform: matrix)
            sceneView.session.add(anchor: anchor)
        }
    }
    
    // Helping method for recreate anchors
    func createTransform(dict: [String: Float]) -> SCNMatrix4{
        var transform = SCNMatrix4()
        transform.m11 = dict["m11"]!
        transform.m12 = dict["m12"]!
        transform.m13 = dict["m13"]!
        transform.m14 = dict["m14"]!
        transform.m21 = dict["m21"]!
        transform.m22 = dict["m22"]!
        transform.m23 = dict["m23"]!
        transform.m24 = dict["m24"]!
        transform.m31 = dict["m31"]!
        transform.m32 = dict["m32"]!
        transform.m33 = dict["m33"]!
        transform.m34 = dict["m34"]!
        transform.m41 = dict["m41"]!
        transform.m42 = dict["m42"]!
        transform.m43 = dict["m43"]!
        transform.m44 = dict["m44"]!
        return transform
    }

    struct pointCoordinates {
        var x = Float()
        var y = Float()
        var z = Float()
    }
    
    func saveToCache(hitPosition: SCNVector3) {
        print("SAVING POINT")
        let pointForCache = ["x": hitPosition.x, "y": hitPosition.y, "z": hitPosition.z]
        points.append(pointForCache)
        defaults.set(points, forKey: "points")
        print("Point set")
    }
    
    @IBAction func getDefaultsButton(_ sender: Any) {
            defaults.set([:], forKey: "anchors")
            defaults.set([:], forKey: "points")
            defaults.set([:], forKey: "locations")
    }
    
    @IBAction func sendLocationButton(_ sender: Any) {
        let location = getCameraCoordinates(sceneView: sceneView)
        let dictToSave = ["x": location?.x, "y": location?.y, "z": location?.z, "device": deviceNumber]
        locations.append(dictToSave as! [String : Float])
        defaults.set(locations, forKey: "locations")
    }
    
    @IBAction func newDeviceButton(_ sender: Any) {
        deviceNumber += 1
    }

    @IBAction func printLocationButton(_ sender: Any) {
        if let positionsCached = defaults.array(forKey: "locations") as! [[String: Float]]?{
            for position in positionsCached{
                print("Posisjon: \(position)")
            }
        }
    }
    
    func saveMatrix(transform: SCNMatrix4) {
        var dict: [String: Float] = [:]
        let mirrored_object = Mirror(reflecting: transform)
        for (index, attr) in mirrored_object.children.enumerated() {
            if let property_name = attr.label as String! {
                dict[property_name] = attr.value as! Float
            }
        }
        anchors.append(dict)
        defaults.set(dict, forKey: "anchors")
    }
    
    func getCameraCoordinates(sceneView: ARSCNView) -> pointCoordinates? {
        if let currentFrame = sceneView.session.currentFrame {
            let transform = SCNMatrix4(currentFrame.camera.transform)
            var cc = pointCoordinates()
            cc.x = transform.m41
            cc.y = transform.m42
            cc.z = transform.m43
            return cc
        }
        return nil
    }
    
    //*************
    //Old functions
    //*************
 
    func findPosition() -> [Float] {
        var array = [Float]()
        let cameraPosition = getCameraCoordinates(sceneView: sceneView)
        var counter = 0
        for node in sceneView.scene.rootNode.childNodes {
            if let geo = node.geometry as? SCNSphere {
                let nodePosition = SCNVector3Make(node.transform.m41, node.transform.m42, node.transform.m43)
                //let dist = calculateDistanceFromSphereToCamera(sphereNode: nodePosition, cameraCoordinates:  cameraPosition)
                //array.append(dist)
                print("Coordinate \(counter): \(nodePosition.x), \(nodePosition.y), \(nodePosition.z)")
                counter += 1
            }
        }
        print("CameraCoordinate: \(cameraPosition?.x), \(cameraPosition?.y), \(cameraPosition?.z)")
        //print(array)
        return array
    }
    
    
    func calculateDistanceFromSphereToCamera(sphereNode: SCNVector3, cameraCoordinates: pointCoordinates) -> Float {
        let newx = sphereNode.x - cameraCoordinates.x
        let newy = sphereNode.y - cameraCoordinates.y
        let newz = sphereNode.z - cameraCoordinates.z
        let dist = sqrt(pow(newx, 2) + pow(newy, 2) + pow(newz, 2))
        return dist
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
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
