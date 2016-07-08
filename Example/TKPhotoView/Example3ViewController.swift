//
//  Example3ViewController.swift
//  TKPhotoView
//
//  Created by Eddie Hiu-Fung Lau on 6/7/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import TKPhotoView

class Example3ViewController: UIViewController {

    @IBOutlet weak var thumbnail1 : UIImageView!
    @IBOutlet weak var thumbnail2 : UIImageView!
    
    var thumbnails : [UIImageView] {
        return [thumbnail1,thumbnail2]
    }
    
    var photos : [UIImage] {
        return [UIImage(named:"SampleImage1")!, UIImage(named:"SampleImage2")!]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        thumbnails.forEach { thumbnail in
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(Example3ViewController.didTapThumbnail))
            thumbnail.addGestureRecognizer(tapGesture)
        }
    }
}

// MARK: Event Handlers
extension Example3ViewController {
    
    func didTapThumbnail(gesture:UIGestureRecognizer) {
        
        let index = thumbnails.indexOf(gesture.view as! UIImageView)!
        
        let photoViewController = TKPhotoViewController()
        photoViewController.dataSource = self
        photoViewController.indexOfCurrentPhoto = index
        navigationController?.pushPhotoViewController(photoViewController, animated: true)
        
    }
    
}

// MARK: Photo View Controller DataSource
extension Example3ViewController : TKPhotoViewControllerDataSource {
    
    func numberOfPhotoInPhotoViewController(controller: TKPhotoViewController) -> Int {
        return thumbnails.count
    }
    
    func photoViewController(controller: TKPhotoViewController, photoToShowAtIndex index: Int) -> UIImage? {
        return photos[index]
    }

    func photoViewController(controller: TKPhotoViewController, placeHolderImageAtIndex index: Int) -> UIImage? {
        return thumbnails[index].image
    }
    
    func photoViewController(controller: TKPhotoViewController, transitionFromViewAtIndex index: Int) -> UIView? {
        return thumbnails[index]
    }
    
    func photoViewController(controller: TKPhotoViewController, transitionFromImageAtIndex index: Int) -> UIImage? {
        return thumbnails[index].image
    }
    
}
