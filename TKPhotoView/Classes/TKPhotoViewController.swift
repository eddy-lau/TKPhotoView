//
//  TKPhotoViewController.swift
//
//  Created by Eddie Hiu-Fung Lau on 22/10/2015.
//

import Foundation

extension UINavigationController {
    
    public func pushPhotoViewController(photoViewController:TKPhotoViewController, animated:Bool) {
        
        photoViewController.originalNavigationDelegate = self.delegate
        self.delegate = photoViewController
        self.pushViewController(photoViewController, animated: animated)
        
    }
    
}

// MARK: - protocol TKPhotoViewControllerDataSource

@objc public protocol TKPhotoViewControllerDataSource {

    func numberOfPhotoInPhotoViewController(controller:TKPhotoViewController) -> Int
    optional func photoViewController(controller: TKPhotoViewController, transitionFromImageAtIndex index:Int) -> UIImage?
    optional func photoViewController(controller: TKPhotoViewController, transitionFromViewAtIndex index:Int) -> UIView?
    
    optional func photoViewController(controller: TKPhotoViewController, photoToShowAtIndex index:Int) -> UIImage?
    optional func photoViewController(controller: TKPhotoViewController, photoURLToShowAtIndex index:Int) -> NSURL?
    optional func photoViewController(controller: TKPhotoViewController, placeHolderImageAtIndex index:Int) -> UIImage?
    
}

// MARK: -

public class TKPhotoViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    
    public var originalNavigationDelegate : UINavigationControllerDelegate?
    public var fromController : UIViewController?
    
    private var collectionViewFrame : CGRect {
        return self.view.bounds
    }
    
    private lazy var collectionViewLayout : UICollectionViewFlowLayout  = {
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .Horizontal
        layout.minimumInteritemSpacing = 0.0
        layout.minimumLineSpacing = 0.0
        return layout
        
    }()
    

    lazy var collectionView : UICollectionView = {

        assert(self.isViewLoaded())
        let collectionView = UICollectionView(frame: self.collectionViewFrame, collectionViewLayout: self.collectionViewLayout)
        collectionView.autoresizingMask = [.FlexibleWidth,.FlexibleHeight]
        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView.pagingEnabled = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerClass(TKPhotoViewerCell.self, forCellWithReuseIdentifier: "photoViewer")
        collectionView.showsHorizontalScrollIndicator = false
        if self.numberOfPhotos > 0 {
            collectionView.scrollToItemAtIndexPath( NSIndexPath(forItem:self.currentPhotoIndex, inSection: 0), atScrollPosition:.None, animated:false)
        }
        
        return collectionView
    }()
    
    private var photoHolders : [PhotoHolder] = [] {
        didSet {
            if isViewLoaded() {
                collectionView.reloadData()
            }
        }
    }
    
    // MARK: - Public properties
    
    public var indexOfCurrentPhoto : Int {
        
        get {
            if isViewLoaded() {
                let bounds = collectionView.bounds
                let i = floor( (bounds.origin.x + (bounds.size.width) / 2) / bounds.size.width )
                return Int(i)
            } else {
                return currentPhotoIndex
            }
        }
        
        set(index) {
            
            if isViewLoaded() {
                collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0), atScrollPosition: .None, animated: false)
            } else {
                currentPhotoIndex = index
            }
            
        }
    }
    
    public weak var dataSource : TKPhotoViewControllerDataSource? {
        didSet {
            if isViewLoaded() {
                collectionView.reloadData()
            }
        }
    }
    
    public func setup(photoURLToView:NSURL, placeholderImage:UIImage?, transitionFromView:UIView?) {
        
        let holder = PhotoHolder()
        holder.imageURL = photoURLToView
        holder.placeholder = placeholderImage
        holder.transitionFromImage = placeholderImage
        holder.transitionFromView = transitionFromView
        
        photoHolders = [holder]
    }
    
    public func setup(photoToView:UIImage, transitionFromView:UIView?) {
        
        let holder = PhotoHolder()
        holder.image = photoToView
        holder.placeholder = photoToView
        holder.transitionFromImage = photoToView
        holder.transitionFromView = transitionFromView
        
        photoHolders = [holder]
    }
    
    
    // MARK: - Private properties
    
    private var currentPhotoIndex = 0 {
        didSet {
            title = NSLocalizedString(String(format:"%ld of %ld", currentPhotoIndex + 1, numberOfPhotos), comment:"")
        }
    }
    
    private var transitionFromView : UIView? {
        
        if let holder = self.photoHolderAtIndex(indexOfCurrentPhoto) {
            return holder.transitionFromView
        } else {
            return nil
        }
    
    }
    
    private var transitionFromImage : UIImage? {
        
        if let holder = self.photoHolderAtIndex(indexOfCurrentPhoto) {
            return holder.transitionFromImage
        } else {
            return nil
        }
        
    }
    
    private func photoHolderAtIndex(index: Int) -> PhotoHolder? {
        
        if let dataSource = self.dataSource {
            
            let holder = PhotoHolder()
            holder.imageURL = dataSource.photoViewController?(self, photoURLToShowAtIndex: index)
            holder.image = dataSource.photoViewController?(self, photoToShowAtIndex: index)
            holder.placeholder = dataSource.photoViewController?(self, placeHolderImageAtIndex: index)
            holder.transitionFromImage = dataSource.photoViewController?(self, transitionFromImageAtIndex: index)
            holder.transitionFromView = dataSource.photoViewController?(self, transitionFromViewAtIndex: index)
            
            return holder
            
        } else {
            
            if index < photoHolders.count {
                return photoHolders[index]
            } else {
                // The datasource is freed.
                return nil
            }
        }
        
    }
    
    private var numberOfPhotos : Int {
        
        if let dataSource = self.dataSource {
            return dataSource.numberOfPhotoInPhotoViewController(self)
        } else {
            return photoHolders.count
        }
        
    }
    
    private class func centeredFrameForImageSize(size:CGSize, inBounds bounds:CGRect) -> CGRect {
    
        let thumbnailAspectRatio = size.width / size.height
        let scrollViewAspectRatio = bounds.size.width / bounds.size.height
        
        var scale = CGFloat(1)
        if thumbnailAspectRatio > scrollViewAspectRatio {
            scale = bounds.size.width / size.width
        } else {
            scale = bounds.size.height / size.height
        }
        
        let w = scale * size.width
        let h = scale * size.height
        let x = bounds.origin.x + (bounds.size.width - w) / 2
        let y = bounds.origin.y + (bounds.size.height - h) / 2
        
        return CGRectMake(x, y, w, h)
        
    }
    
    private func centeredFrameForImageSize(size:CGSize) -> CGRect {
        
        var bounds = view.bounds
        
        if isViewLoaded() {
            bounds.origin.y = topLayoutGuide.length
            bounds.size.height -= topLayoutGuide.length
        }
        
        return TKPhotoViewController.self.centeredFrameForImageSize(size, inBounds: bounds)
    }
    
    private var rectOfCurrentPhoto : CGRect {
        
        if isViewLoaded() {
            
            let i = indexOfCurrentPhoto
            if let cell = collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: i, inSection: 0)) as? TKPhotoViewerCell {
                
                return view.convertRect(cell.imageView.imageView.frame, fromView: cell.imageView)
            
            }
        }
        
        if let image = transitionFromImage {
            
            return centeredFrameForImageSize(image.size)
            
        } else {
            
            return CGRectZero
            
        }
        
    }
    
    private var currentCell : TKPhotoViewerCell? {
        
        if isViewLoaded() {
            return collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: indexOfCurrentPhoto, inSection: 0)) as? TKPhotoViewerCell
        } else {
            return nil
        }
        
    }
    
    private var currentPhoto : UIImage? {
        
        if isViewLoaded() {
            
            let i = indexOfCurrentPhoto
            if let cell = collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: i, inSection: 0)) as? TKPhotoViewerCell {
                return cell.imageView.imageView.image
            }
        
        }
        return nil
        
    }
    
    private var imageIsCentered : Bool {
        
        if isViewLoaded() {
            
            let i = indexOfCurrentPhoto
            if let cell = collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: i, inSection: 0)) as? TKPhotoViewerCell {

                let imageView = cell.imageView.imageView
                if let image = cell.imageView.imageView.image {
                    let s1 = imageView.frame.size
                    let s2 = centeredFrameForImageSize(image.size).size
                    let dw = abs(s1.width-s2.width)
                    let dh = abs(s1.height-s2.height)
                    return dw < 1.0 && dh < 1.0
                }
                
            }
            
        }
        return false
        
    }
    
    private func progressBarAlpha(x:CGFloat, width:CGFloat) -> CGFloat {
        
        var x = x
        let w = width
        
        if w > 0 {
            x = (x - floor(x/w)*w)/w // normalized to range from 0 to 1
            return 1 - sqrt( 0.5 * 0.5 - (x - 0.5)*(x-0.5) ) * 2
        } else {
            return 0
        }
        
    }
    
    private var progressBar : UIView? {
        
        didSet {
            
            oldValue?.removeFromSuperview()
            
            if let progressBar = self.progressBar {
                
                if let navBar = navigationController?.navigationBar {
                    let h = CGFloat(2)
                    progressBar.frame = CGRectMake(0,navBar.bounds.size.height - h, navBar.bounds.size.width, h)
                    progressBar.alpha = progressBarAlpha(collectionView.bounds.origin.x, width: collectionView.bounds.size.width)
                    navBar.addSubview(progressBar)
                }
                
            }
        }
    }
    
    // MARK: - UIViewController
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        
        view.backgroundColor = UIColor.whiteColor()
        view.addSubview(collectionView)
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(TKPhotoViewController.handlePan(_:)))
        gesture.delegate = self
        view.addGestureRecognizer(gesture)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let progressBar = self.progressBar {
            progressBar.removeFromSuperview()
            self.progressBar = nil
        }
        
    }
    
    public override func viewDidAppear(animated: Bool) {
        self.progressBar = currentCell?.progressBar
    }
    
    // MARK: - UICollectionView
    
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfPhotos
    }
    
    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoViewer", forIndexPath: indexPath) as! TKPhotoViewerCell
        cell.photoHolder = photoHolderAtIndex(indexPath.item)
        cell.didStartHandler = cellDidStartDownload
        cell.didStopHandler = cellDidStopDownload
        cell.imageView.topInset = topLayoutGuide.length
        return cell
        
    }
    
    public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        
        if isViewLoaded() {
            
            let bounds = scrollView.bounds
            let i = Int(floor( (bounds.origin.x + (bounds.size.width) / 2) / bounds.size.width ))
            
            if i != currentPhotoIndex {
                currentPhotoIndex = i
                progressBar = (collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: currentPhotoIndex, inSection: 0)) as? TKPhotoViewerCell)?.progressBar
            }
            
            let alpha = progressBarAlpha(scrollView.bounds.origin.x, width: scrollView.bounds.size.width)
            progressBar?.alpha = alpha
            
        }
        
    }
    
    // MARK: - Private methods
    
    private func cellDidStartDownload(cell:TKPhotoViewerCell) {
    }
    
    private func cellDidStopDownload(cell:TKPhotoViewerCell, success:Bool) {
    }
    
    // MARK: - Inner Class - Collection Cell
    
    private class PhotoHolder {
        
        var transitionFromView  : UIView?
        var transitionFromImage : UIImage?
        
        var placeholder : UIImage?
        var image : UIImage?
        var imageURL : NSURL?
    }
    
    private class TKPhotoViewerCell : UICollectionViewCell, TKPhotoViewDownloadProgressDelegate {
        
        var photoHolder : PhotoHolder? {
            didSet {
                updatePhoto()
            }
        }
        
        var image : UIImage? {
            didSet {
                updatePhoto()
            }
        }
        
        var downloadProgress : CGFloat?
        var progressBar : ProgressBar?
        
        var didStartHandler : ((TKPhotoViewerCell)->Void)?
        var didStopHandler  : ((TKPhotoViewerCell,success:Bool)->Void)?
        
        lazy var imageView: TKPhotoView = {
            let v = TKPhotoView(frame:self.bounds)
            v.downloadProgressDelegate = self
            return v
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            contentView.addSubview(imageView)
            updatePhoto()
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            imageView.frame = bounds
        }
        
        func updatePhoto() {
            if let image = self.photoHolder?.image {
                imageView.image = image
            } else if let url = self.photoHolder?.imageURL {
                imageView.setImageURL(url, placeholder: photoHolder?.placeholder)
            } else {
                imageView.image = nil
            }
        }
        
        func photoViewDidStartDownload(photoView:TKPhotoView) {
            
            if progressBar == nil {
                progressBar = ProgressBar()
            }
            progressBar!.setProgress(0.05, animated: true)
            
            downloadProgress = 0.0
            if let startHandler = self.didStartHandler {
                startHandler(self)
            }
            
        }
        
        func photoViewDidStopDownload(photoView:TKPhotoView, success:Bool) {
            
            if let progressBar = self.progressBar {

                downloadProgress = 1.0
                progressBar.progress = 1.0
                
                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    progressBar.alpha = 0.0
                }, completion: { (completed) -> Void in
                    self.downloadProgress = nil
                    progressBar.removeFromSuperview()
                    self.progressBar = nil
                    
                    if let stopHandler = self.didStopHandler {
                        stopHandler(self, success:success)
                    }
                    
                })
                
            }
            
        }
        
        func photoView(photoView: TKPhotoView, didDownloadWithProgress progress: CGFloat) {
            
            downloadProgress = progress
            if let progressBar = self.progressBar {
                progressBar.setProgress( max(0.05, progress), animated:true)
            }
            
        }
        
        
        private class ProgressBar : UIView {
            
            var progress : CGFloat = 0.0 {
                didSet {
                    setNeedsLayout()
                }
            }
            
            var barFrame : CGRect {
                return CGRectMake(0, 0, CGRectGetWidth(bounds) * progress, CGRectGetHeight(bounds))
            }
            
            lazy var bar : UIView = {
                let v = UIView(frame: self.barFrame)
                v.backgroundColor = self.tintColor
                return v
            }()
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                
                self.backgroundColor = UIColor.clearColor()
                addSubview(bar)
                
            }
            
            required init?(coder aDecoder: NSCoder) {
                fatalError("init(coder:) has not been implemented")
            }
            
            private override func layoutSubviews() {
                super.layoutSubviews()
                bar.frame = barFrame
            }
            
            func setProgress(progress:CGFloat, animated:Bool) {
                
                self.progress = progress
                
                UIView.animateWithDuration(0.2) {
                    self.layoutIfNeeded()
                }
                
            }
            
        }
        
        
    }
    
    // MARK: - Transition
    
    private var fromViewController : UIViewController?
    private var interactivePopTransition : UIPercentDrivenInteractiveTransition?
    
    
    // MARK: Navigation Controller Delegate
    
    public func navigationController(navigationController: UINavigationController, willShowViewController viewController: UIViewController, animated: Bool) {
        
        if viewController === self {
            fromViewController = navigationController.viewControllers[navigationController.viewControllers.count-2]
        }
        
    }
    
    public func navigationController(navigationController: UINavigationController, didShowViewController viewController: UIViewController, animated: Bool) {
        
        if viewController === fromViewController {
            navigationController.delegate = self.originalNavigationDelegate
            self.originalNavigationDelegate = nil
            fromViewController = nil
        }
        
    }
    
    public func navigationController(navigationController: UINavigationController, animationControllerForOperation operation: UINavigationControllerOperation, fromViewController fromVC: UIViewController, toViewController toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if (toVC === self && operation == .Push) {
            
            if let thumbnailView = self.transitionFromView {
                if let thumbnail = self.transitionFromImage {
                    return ZoomInAnimator(thumbnailView:thumbnailView, thumbnail: thumbnail)
                }
            }
            return nil
            
        } else if (fromVC === self && operation == .Pop) {
            
            if let thumbnailView = self.transitionFromView, thumbnail = self.transitionFromImage {
                if self.interactivePopTransition != nil, let draggingImageView = self.draggingImageView {
                    return DragOutAnimator(thumbnailView: thumbnailView, thumbnail: thumbnail, draggingImageView: draggingImageView, cancelledHandler:dragTransitionDidCancel)
                } else {
                    return ZoomOutAnimator(thumbnailView: thumbnailView, thumbnail: thumbnail)
                }
            }
            return nil
            
        } else {
            return nil
        }
        
    }
    
    public func navigationController(navigationController: UINavigationController, interactionControllerForAnimationController animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {

        if animationController as? DragOutAnimator != nil {
            return interactivePopTransition
        } else {
            return nil
        }
        
    }
    
    // MARK: Pan gesture
    
    public func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        return imageIsCentered
    }
    
    private func dragTransitionDidCancel() {
        
        if let draggingImageView = self.draggingImageView {
            draggingImageView.removeFromSuperview()
            self.draggingImageView = nil
        }
        
    }
    
    public func handlePan(recognizer: UIPanGestureRecognizer) {
        
        let thresholdDistance = CGFloat(100)
        
        let draggedDistance = abs(recognizer.translationInView(self.view).y)
 
        var progress = CGFloat(0.0)
        if draggedDistance >= 0 && draggedDistance < thresholdDistance {
            progress = 0.3 * draggedDistance / thresholdDistance
        } else {
            progress = 0.3
        }
        
        if recognizer.state == .Began {
            
            
            interactivePopTransition = UIPercentDrivenInteractiveTransition()
            
            if let containerView = navigationController?.view {
                
                draggingImageView = {
                    
                    let v = UIView(frame: containerView.convertRect(rectOfCurrentPhoto, fromView: view))
                    
                    v.layer.shadowColor = UIColor.blackColor().CGColor
                    v.layer.shadowOpacity = 0.3
                    v.layer.shadowRadius = 20
                    v.layer.shadowOffset = CGSizeMake(0,10)
                    v.clipsToBounds = false
                    v.layer.masksToBounds = false
                    
                    let imageView = UIImageView(image: currentPhoto)
                    imageView.frame = v.bounds
                    imageView.clipsToBounds = true
                    imageView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
                    imageView.contentMode = .ScaleAspectFill
                    v.addSubview(imageView)
                    
                    
                    return v
                    
                }()
                
                containerView.addSubview(draggingImageView!)
                navigationController?.popViewControllerAnimated(true)
            }
            
        }
        else if (recognizer.state == .Changed) {
            // Update the interactive transition's progress
            
            if let draggingImageView = self.draggingImageView, containerView = self.draggingImageView?.superview {
                
                var f = containerView.convertRect(rectOfCurrentPhoto, fromView: view)
                f.origin.y += recognizer.translationInView(view).y
                f.origin.x += recognizer.translationInView(view).x
                draggingImageView.frame = f
                
            }
            
            interactivePopTransition!.updateInteractiveTransition(progress)
        }
        else if (recognizer.state == .Ended || recognizer.state == .Cancelled) {
            
            let velocity = abs(recognizer.velocityInView(self.view).y)
            
            if (progress >= 0.3 || velocity > 1000 ) {
                
                if let fromView = transitionFromView, containerView = draggingImageView?.superview {
                    
                    UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                        
                        self.draggingImageView!.frame = containerView.convertRect(fromView.bounds, fromView: fromView)
                        self.draggingImageView!.layer.shadowOpacity = 0.0
                        
                    }, completion: { finished in
                        
                        self.draggingImageView?.removeFromSuperview()
                        self.draggingImageView = nil
                        
                    })
                    
                }
                
                interactivePopTransition!.finishInteractiveTransition()
                self.interactivePopTransition = nil;
            }
            else {
                
                if let containerView = draggingImageView?.superview {
                    
                    UIView.animateWithDuration(0.3, delay: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
                        
                        self.draggingImageView!.frame = containerView.convertRect(self.rectOfCurrentPhoto, fromView: self.view)
                        self.draggingImageView!.layer.shadowOpacity = 0.0
                        
                    }, completion: { finished in
                        
                        self.interactivePopTransition!.cancelInteractiveTransition()
                        self.interactivePopTransition = nil;
                        
                        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.1 * Double(NSEC_PER_SEC)))
                        dispatch_after(delayTime, dispatch_get_main_queue(), { () -> Void in
                            self.progressBar = self.currentCell?.progressBar
                            
                        })
                        
                    })
                }
                
                
            }
            
        }
        
        
    }
    
    // MARK: Animators
    
    class ZoomInAnimator : NSObject, UIViewControllerAnimatedTransitioning {
        
        let thumbnailView:UIView
        let thumbnail:UIImage
        
        init(thumbnailView:UIView,thumbnail:UIImage) {
            self.thumbnailView = thumbnailView
            self.thumbnail=thumbnail
            super.init()
        }
        
        func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
            
            let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
            let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) as! TKPhotoViewController
            
            fromVC.view.frame = transitionContext.initialFrameForViewController(fromVC)
            transitionContext.containerView()!.addSubview(fromVC.view)
            
            toVC.view.frame = transitionContext.finalFrameForViewController(toVC)
            transitionContext.containerView()!.addSubview(toVC.view)
            
            let snapshotView = UIImageView(image: thumbnail)
            snapshotView.contentMode = .ScaleAspectFill
            snapshotView.clipsToBounds = true
            snapshotView.frame = transitionContext.containerView()!.convertRect(thumbnailView.bounds, fromView: thumbnailView)
            transitionContext.containerView()!.addSubview(snapshotView)
            
            
            fromVC.view.alpha = 1.0
            toVC.view.alpha = 0.0
            
            let imageViewToFrame = transitionContext.containerView()!.convertRect(toVC.centeredFrameForImageSize(thumbnail.size), fromView: toVC.view)
            
            toVC.collectionView.hidden = true
            thumbnailView.hidden = true
            
            UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: {
                
                fromVC.view.alpha = 1.0
                toVC.view.alpha = 1.0
                
            }) { completed -> Void in
                    
            }
            
            UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.0, options: .CurveLinear, animations: {
                
                snapshotView.frame = imageViewToFrame
                
            }, completion: { completed in
                    
                self.thumbnailView.hidden = false
                fromVC.view.alpha = 1.0
                snapshotView.removeFromSuperview()
                toVC.collectionView.hidden = false
                transitionContext.completeTransition(true)
                    
            })
            
        }
        
        func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
            return 0.5
        }
        
    }
    
    class ZoomOutAnimator : NSObject, UIViewControllerAnimatedTransitioning {
        
        let thumbnailView:UIView
        let thumbnail:UIImage
        
        init(thumbnailView:UIView,thumbnail:UIImage) {
            self.thumbnailView = thumbnailView
            self.thumbnail=thumbnail
            super.init()
        }
        
        func animateTransition(transitionContext: UIViewControllerContextTransitioning) {

            let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as! TKPhotoViewController
            let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
            
            
            toVC.view.frame = transitionContext.finalFrameForViewController(toVC)
            transitionContext.containerView()!.addSubview(toVC.view)
            
            fromVC.view.frame = transitionContext.initialFrameForViewController(fromVC)
            transitionContext.containerView()!.addSubview(fromVC.view)
            
            let imageView = UIImageView(image: thumbnail)
            imageView.contentMode = .ScaleAspectFill
            imageView.clipsToBounds = true
            imageView.frame = transitionContext.containerView()!.convertRect(thumbnailView.bounds, fromView: thumbnailView)
            transitionContext.containerView()!.addSubview(imageView)
            
            
            imageView.frame = transitionContext.containerView()!.convertRect(fromVC.rectOfCurrentPhoto, fromView: fromVC.view)
            fromVC.collectionView.alpha = 0.0
            thumbnailView.hidden = true
            
            let imageViewToFrame = transitionContext.containerView()!.convertRect(thumbnailView.bounds, fromView: thumbnailView)
            
            UIView.animateWithDuration(0.2, delay: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: {
                
                fromVC.view.alpha = 0.0
                toVC.view.alpha = 1.0
                imageView.frame = imageViewToFrame
                
            }, completion:  { completed in
                
                imageView.removeFromSuperview()
                fromVC.collectionView.alpha = 1.0
                fromVC.view.alpha = 1.0
                self.thumbnailView.hidden = false
                
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            })
            
        }
        
        func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
            return 0.2
        }
    }
    
    private var draggingImageView : UIView?
    
    class DragOutAnimator : NSObject, UIViewControllerAnimatedTransitioning {
        
        static let duration = NSTimeInterval(0.4)
        
        let thumbnailView:UIView
        let thumbnail:UIImage
        let draggingImageView : UIView
        let cancelledHandler : ()->Void
        
        init(thumbnailView:UIView,thumbnail:UIImage, draggingImageView:UIView, cancelledHandler: ()->Void ) {
            self.thumbnailView = thumbnailView
            self.thumbnail=thumbnail
            self.draggingImageView = draggingImageView
            self.cancelledHandler = cancelledHandler
            super.init()
        }
        
        func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
            
            let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) as! TKPhotoViewController
            let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
            
            
            toVC.view.frame = transitionContext.finalFrameForViewController(toVC)
            transitionContext.containerView()!.addSubview(toVC.view)
            
            fromVC.view.frame = transitionContext.initialFrameForViewController(fromVC)
            transitionContext.containerView()!.addSubview(fromVC.view)
            
            fromVC.collectionView.alpha = 0.0
            thumbnailView.alpha = 0.0
            
            UIView.animateWithDuration(DragOutAnimator.duration, delay: 0.0, options: UIViewAnimationOptions.CurveLinear, animations: {
                
                fromVC.view.alpha = 0.0
                toVC.view.alpha = 1.0
                
            }, completion:  { completed in
                
                fromVC.collectionView.alpha = 1.0
                fromVC.view.alpha = 1.0
                self.thumbnailView.alpha = 1.0
                
                if transitionContext.transitionWasCancelled() {
                    
                    self.cancelledHandler()
                    
                }
                
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            })
            
        }
        
        func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
            return DragOutAnimator.duration
        }
    }
    
}