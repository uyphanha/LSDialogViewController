//
//  LSDialogViewController.swift
//  LSDialogViewController
//
//  Created by Daisuke Hasegawa on 2016/05/15.
//  Copyright © 2016年 Libra Studio, Inc. All rights reserved.
//

import UIKit

let LSSourceViewTag = 997
let LSDialogViewTag = 998
let LSOverlayViewTag = 999

var kDialogViewController = 0
var kDialogBackgroundView = 1

public extension UIViewController {
    var ls_dialogViewController: UIViewController? {
        get {
            return objc_getAssociatedObject(self, &kDialogViewController) as? UIViewController
        }
        set(newValue) {
            objc_setAssociatedObject(self, &kDialogViewController, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var ls_dialogBackgroundView: LSDialogBackgroundView? {
        get {
            return objc_getAssociatedObject(self, &kDialogBackgroundView) as? LSDialogBackgroundView
        }
        set(newValue) {
            objc_setAssociatedObject(self, &kDialogBackgroundView, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func presentDialogViewController(_ dialogViewController: UIViewController, animationPattern: LSAnimationPattern = .fadeInOut, backgroundViewType: LSDialogBackgroundViewType = .solid, dismissButtonEnabled: Bool = true, completion: (() -> Swift.Void)? = nil) {
        // get the view of viewController that called the dialog
        let sourceView = self.getSourceView()
        self.ls_dialogViewController = dialogViewController
        sourceView.tag = LSSourceViewTag
        
        // dialog View
        let dialogView: UIView = ls_dialogViewController!.view
        dialogView.translatesAutoresizingMaskIntoConstraints = false
        // dialogView.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin, .flexibleTopMargin, .flexibleRightMargin]
        dialogView.alpha = 0.0
        dialogView.tag = LSDialogViewTag
        
        if sourceView.subviews.contains(dialogView) {
            return
        }
        registerKeyboarNotificationObservers()
        
        let overlayView: UIView = UIView(frame: sourceView.bounds)
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlayView.backgroundColor = .clear
        overlayView.tag = LSOverlayViewTag
        
        // background View
        self.ls_dialogBackgroundView = LSDialogBackgroundView(frame: sourceView.bounds)
        self.ls_dialogBackgroundView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.ls_dialogBackgroundView!.backgroundColor = .clear
        self.ls_dialogBackgroundView!.backgroundViewType = backgroundViewType
        self.ls_dialogBackgroundView!.alpha = 0.0
        if let _ = self.ls_dialogBackgroundView {
            overlayView.addSubview(self.ls_dialogBackgroundView!)
        }
        
        // dismiss button
        let dismissButton = UIButton(type: .custom)
        dismissButton.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dismissButton.backgroundColor = .clear
        dismissButton.frame = sourceView.bounds
        dismissButton.tag = animationPattern == LSAnimationPattern.fadeInOut ? LSAnimationPattern.fadeInOut.rawValue : animationPattern.rawValue
        dismissButton.addTarget(self, action: #selector(UIViewController.tapLSDialogBackgroundView(_:)), for: .touchUpInside)
        dismissButton.isEnabled = dismissButtonEnabled
        
        // add view
        overlayView.addSubview(dismissButton)
        overlayView.addSubview(dialogView)
        sourceView.addSubview(overlayView)
        
        dialogView.widthAnchor.constraint(lessThanOrEqualTo: overlayView.widthAnchor, multiplier: 0.9).isActive = true
        dialogView.heightAnchor.constraint(lessThanOrEqualTo: overlayView.heightAnchor, multiplier: 0.9).isActive = true
        dialogView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor).isActive = true
        dialogView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor).isActive = true
        
        // set animation pattern and call
        LSAnimationUtils.shared.startAnimation(self, dialogView: dialogView, sourceView: sourceView, overlayView: overlayView, animationPattern: animationPattern)
        
        // called after the dialog display
        completion?()
   }
    
    // close dialog
    func dismissDialogViewController(_ animationPattern: LSAnimationPattern = .fadeInOut) {
        let sourceView = self.getSourceView()
        if let dialogView = sourceView.viewWithTag(LSDialogViewTag) {
            if let overlayView = sourceView.viewWithTag(LSOverlayViewTag) {
                // set animation pattern and call
                LSAnimationUtils.shared.endAnimation(dialogView, sourceView: sourceView, overlayView: overlayView, animationPattern: animationPattern)
                unregisgerKeyboardNotificationObservers()
            }
        }
    }
    
    // Close the dialog by tapping the background
    @objc func tapLSDialogBackgroundView(_ dismissButton: UIButton) {
        let animationPattern: LSAnimationPattern = LSAnimationPattern(rawValue: dismissButton.tag)!
        self.dismissDialogViewController(animationPattern)
    }
    
    func getSourceView() -> UIView {
        var sourceViewController = self
        guard let parent = sourceViewController.parent else { return sourceViewController.view}
        sourceViewController = parent
        
        return sourceViewController.view
    }
    
    func registerKeyboarNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillChangeFrame), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func unregisgerKeyboardNotificationObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillChangeFrame(notification: NSNotification) {
        guard let userInfo = notification.userInfo else {return}
        
        guard let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {return}
        
        let keyboardFrame = keyboardSize.cgRectValue
        
        let sourceView = self.getSourceView()
        if let overlayView = sourceView.viewWithTag(LSOverlayViewTag) {
            overlayView.frame = CGRect(x: 0, y: 0, width: sourceView.frame.width, height: sourceView.frame.height - keyboardFrame.height)
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let sourceView = self.getSourceView()
        if let overlayView = sourceView.viewWithTag(LSOverlayViewTag) {
            overlayView.frame = CGRect(x: 0, y: 0, width: sourceView.frame.width, height: sourceView.frame.height)
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
}
