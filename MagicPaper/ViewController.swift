//
//  ViewController.swift
//  MagicPaper
//
//  Created by Cássio Marcos Goulart on 05/07/19.
//  Copyright © 2019 CMG Solutions. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    // TODO: Create array of Video Players?
    private var videoPlayer = AVPlayer()
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()

        if let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "PaperImages", bundle: Bundle.main) {
            configuration.trackingImages = trackingImages
            configuration.maximumNumberOfTrackedImages = 1
        }
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        let nodeForAnchor = SCNNode()
        
        if let imageAnchor = anchor as? ARImageAnchor,
            let resourceName = imageAnchor.referenceImage.name {

            videoPlayer.pause()
            
            let videoScene = SKScene(size: CGSize(width: 640, height: 360))
            
            let videoNode: SKVideoNode? = {
                guard let urlString = Bundle.main.path(forResource: resourceName, ofType: "mp4") else { return nil }
                let url = URL(fileURLWithPath: urlString)
                let item = AVPlayerItem(url: url)
                videoPlayer = AVPlayer(playerItem: item)
                return SKVideoNode(avPlayer: videoPlayer)
            }()
            
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: videoPlayer.currentItem, queue: nil) { _ in
                self.videoPlayer.seek(to: CMTime.zero)
                // self.videoPlayer.play()   // Uncomment this for infinite playing
            }
            
            videoNode?.position = CGPoint(x: videoScene.size.width / 2, y: videoScene.size.height / 2)
            videoNode?.yScale = -1.0
            videoScene.addChild(videoNode!)
            
            videoPlayer.volume = 1.0
            videoPlayer.play()
            
            let imagePlane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            imagePlane.firstMaterial?.diffuse.contents = videoScene
            
            let imageNode = SCNNode(geometry: imagePlane)
            imageNode.eulerAngles.x = -.pi/2.0
            
            nodeForAnchor.name = resourceName
            nodeForAnchor.addChildNode(imageNode)
        }
        
        return nodeForAnchor
    }
    
    // Try to manage multiple video players by stopping all the others but the one focused in front of the camera.
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        for cNode1 in sceneView.scene.rootNode.childNodes {
            
            for cNode2 in cNode1.childNodes {
                
                if let videoScene = cNode2.geometry?.firstMaterial?.diffuse.contents as? SKScene {
                    
                    for cNode3 in videoScene.children {
                        
                        if let videoNode = cNode3 as? SKVideoNode {
                            
                            if cNode1.name == node.name {
                                
                                if videoNode.isPaused {
                                    
                                    // TODO: access array of video player to seek playback time to CMTime.zero
                                    DispatchQueue.main.async {
                                        videoNode.play()
                                    }
                                }
                                
                            } else if !videoNode.isPaused {
                                
                                DispatchQueue.main.async {
                                    videoNode.pause()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
}
