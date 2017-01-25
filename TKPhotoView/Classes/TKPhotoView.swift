//
//  TKPhotoView.swift
//
//  Created by Eddie Hiu-Fung Lau on 26/10/2015.
//

import Foundation
import AlamofireImage

protocol TKPhotoViewDownloadProgressDelegate: class {
    
    func photoViewDidStartDownload(photoView:TKPhotoView)
    func photoView(photoView:TKPhotoView, didDownloadWithProgress progress:CGFloat)
    func photoViewDidStopDownload(photoView:TKPhotoView, success:Bool)
    
}

class TKPhotoView : UIScrollView {
    
    var topInset = CGFloat(0) {
        didSet {
            updateContentInset()
        }
    }
    
    lazy var imageView : UIImageView = {
        let v = UIImageView()
        v.contentMode = .ScaleAspectFill
        return v
    }()
    
    var image : UIImage? {
        get {
            return imageView.image
        }
        set(image) {
            imageView.image = image
            relayout()
        }
    }
    
    weak var downloadProgressDelegate : TKPhotoViewDownloadProgressDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        bouncesZoom = true
        decelerationRate = UIScrollViewDecelerationRateFast
        delegate = self
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(TKPhotoView.didDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTap)
        
        userInteractionEnabled = true
        
        addSubview(imageView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func relayout() {
        
        if let image = imageView.image {
            
            let (min,max,current) = computeZoomScales(image.size)
            
            if minimumZoomScale != min || maximumZoomScale != max || zoomScale != current {
                minimumZoomScale = min
                maximumZoomScale = max
                zoomScale = current
            }
            
            let imageWidth = image.size.width * zoomScale
            let imageHeight = image.size.height * zoomScale
            imageView.frame = CGRectMake(0,0,imageWidth,imageHeight)
            
            updateContentInset()
            
        } else {
            
            contentSize = bounds.size
            
            minimumZoomScale = 1.0
            maximumZoomScale = 1.0
            zoomScale = 1.0
        }
        
    }
    
    func updateContentInset() {
        
        if let image = imageView.image {
            
            let boundsHeight = bounds.size.height
            let boundsWidth = bounds.size.width
            let imageWidth = image.size.width * zoomScale
            let imageHeight = image.size.height * zoomScale
            
            var x = CGFloat(0)
            var y = CGFloat(0)
            if imageHeight < (boundsHeight - topInset) {
                y = (boundsHeight - topInset - imageHeight)/2.0
            }
            if imageWidth < bounds.size.width {
                x = (boundsWidth - imageWidth)/2.0
            }
            
            if y < 0 {
                y = 0
            }
            if x < 0 {
                x = 0
            }
            
            contentInset = UIEdgeInsets(top: y + topInset, left: x, bottom: 0, right: 0)
            scrollIndicatorInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
            
        } else {
            
            contentInset = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
            scrollIndicatorInsets = UIEdgeInsets(top: topInset, left: 0, bottom: 0, right: 0)
            
        }
    }
    
    func setImageURL(url:NSURL, placeholder:UIImage?) {
        
        let req = NSURLRequest(URL: url)
        userInteractionEnabled = false
        
        var cached = false
        
        imageView.af_setImageWithURLRequest(req, placeholderImage: placeholder, filter: nil, progress: { (bytesRead, totalBytesRead, totalExpectedBytesToRead) in
            
            let progress = CGFloat(totalBytesRead) / CGFloat(totalExpectedBytesToRead)
            self.downloadProgressDelegate?.photoView(self, didDownloadWithProgress: progress)
            
        }, progressQueue: dispatch_get_main_queue(), imageTransition: .None, runImageTransitionIfCached: false) { (response) in

            self.userInteractionEnabled = true
            if response.result.isSuccess {
                self.downloadProgressDelegate?.photoViewDidStopDownload(self, success: true)
            } else {
                self.downloadProgressDelegate?.photoViewDidStopDownload(self, success: false)
            }
            
        }
        downloadProgressDelegate?.photoViewDidStartDownload(self)
        relayout()
        
    }
    
    func computeZoomScales(imageSize: CGSize) -> (min: CGFloat, max: CGFloat, current: CGFloat) {
        
        let boundSize = self.bounds.size
        
        let xScale = boundSize.width / imageSize.width
        let yScale = (boundSize.height - topInset) / imageSize.height
        var minScale = min(xScale, yScale)
        
        let maxScale = UIScreen.mainScreen().scale
        
        if minScale > maxScale {
            return (min:1.0, max:minScale, current:minScale)
        } else {
            if minScale < 0.1 {
                minScale = 0.1
            }
            return (min:minScale, max:maxScale, current:minScale)
        }
        
    }
    
    func didDoubleTap(gestureRecognizer:UITapGestureRecognizer) {
        
        let touchPoint = gestureRecognizer.locationInView(self)
        
        if fabs(zoomScale - maximumZoomScale) < 0.0001 {
            UIView.animateWithDuration(0.3, delay: 0.0, options: .BeginFromCurrentState, animations: { () -> Void in
                self.zoomScale = self.minimumZoomScale
                self.updateContentInset()
            }) { (fiished) -> Void in
            }
            
        } else {
            zoomToPoint(touchPoint, scale: maximumZoomScale, animated: true)
        }
        
    }
    
    func zoomToPoint(zoomPoint:CGPoint, scale:CGFloat, animated:Bool) {
        
        let actualScale = scale / zoomScale
        
        var bounds = self.bounds
        bounds.size.width -= contentInset.left + contentInset.right
        bounds.size.height -= contentInset.top + contentInset.bottom
        
        var zoomSize = CGSizeZero
        zoomSize.width = bounds.size.width / actualScale
        zoomSize.height = bounds.size.height / actualScale
        
        var zoomRect = CGRectZero
        zoomRect.size.width = zoomSize.width
        zoomRect.size.height = zoomSize.height
        zoomRect.origin.x = zoomPoint.x - zoomRect.size.width / 2.0
        zoomRect.origin.y = zoomPoint.y - zoomRect.size.height / 2.0
        
        zoomRect = convertRect(zoomRect, toView:imageView)
        
        UIView.animateWithDuration(0.3, delay: 0.0, options: .BeginFromCurrentState, animations: {
            self.zoomToRect(zoomRect, animated: false)
            self.updateContentInset()
        }) { finished -> Void in
        }
        
    }
    
    func logRect(name:String, rect:CGRect) {
        NSLog("\(name) = \(rect.origin.x),\(rect.origin.y),\(rect.size.width),\(rect.size.height)")
    }
    
    func logSize(name:String, size:CGSize) {
        NSLog("\(name) = \(size.width),\(size.height)")
    }
    
    func logInsets(name:String, insets:UIEdgeInsets) {
        NSLog("\(name) = left:\(insets.left), top:\(insets.top), right:\(insets.right), bottom:\(insets.bottom)")
    }
    
    func logPoint(name:String, point:CGPoint) {
        NSLog("\(name) = x:\(point.x), top:\(point.y)")
    }
    
    func debugLog() {
        
        NSLog ("----------------------------------------------")
        logRect("imageView.frame", rect: imageView.frame)
        NSLog("scrollView.zommScale = %lf", zoomScale)
        logRect("scrollView.bounds", rect: bounds)
        logSize("scrollView.contentSize", size: contentSize)
        logInsets("scrollView.contentInsets", insets: contentInset)
        logPoint("scrollView.contentOffset", point: contentOffset)
        
    }
    
}

// MARK: UIScrollViewDelegate

extension TKPhotoView : UIScrollViewDelegate {
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewWillBeginZooming(scrollView: UIScrollView, withView view: UIView?) {
        
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        updateContentInset()
    }
    
    func scrollViewDidEndZooming(scrollView: UIScrollView, withView view: UIView?, atScale scale: CGFloat) {
    }
    
}
