//
//  ViewController.swift
//  TKPhotoView
//
//  Created by Eddie Lau on 07/05/2016.
//  Copyright (c) 2016 Eddie Lau. All rights reserved.
//

import UIKit
import TKPhotoView

class ViewController: UIViewController {
    
    @IBOutlet weak var tableView : UITableView!
    
    let sampleNames = ["Example 1", "Example 2", "Example 3"]
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: animated)
        }
    }

}

// MARK: - UITableView
extension ViewController : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sampleNames.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("ExampleCell", forIndexPath: indexPath)
        cell.textLabel?.text = sampleNames[indexPath.row]
        return cell
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if indexPath.row == 0 {
            
            let photoViewController = TKPhotoViewController()
            
            photoViewController.title = "Example 1"
            photoViewController.setup(UIImage(named: "SampleImage1")!, transitionFromView: nil)
            navigationController?.pushPhotoViewController(photoViewController, animated: true)
            
        } else if indexPath.row == 1 {
            
            performSegueWithIdentifier("Example2", sender: self)
            
        } else if indexPath.row == 2 {
            
            performSegueWithIdentifier("Example3", sender: self)
        }
        
    }
    
}

