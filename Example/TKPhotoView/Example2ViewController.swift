//
//  Example2ViewController.swift
//  TKPhotoView
//
//  Created by Eddie Hiu-Fung Lau on 6/7/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import TKPhotoView

class Example2ViewController: UIViewController {
    
    @IBOutlet weak var thumbnail1 : UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(Example2ViewController.didTapThumbnail))
        thumbnail1.addGestureRecognizer(tapGesture)
    }
}

// MARK: Event Handlers
extension Example2ViewController {
    
    func didTapThumbnail(gesture:UIGestureRecognizer) {
        
        let photoViewController = TKPhotoViewController()
        photoViewController.setup(UIImage(named: "SampleImage1")!, transitionFromView: thumbnail1)
        navigationController?.pushPhotoViewController(photoViewController, animated: true)
        
    }
}
