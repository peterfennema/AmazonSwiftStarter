//
//  WelcomeViewController.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 12/02/16.
//  Copyright © 2016 Peter Fennema. All rights reserved.
//

import UIKit

protocol WelcomeViewControllerDelegate: class {
    
    func welcomeViewControllerDidFinish(controller: WelcomeViewController)
    
}

class WelcomeViewController: UIViewController {
    
    weak var delegate: WelcomeViewControllerDelegate?
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "startSegue" {
            let destVC = segue.destinationViewController as! EditProfileViewController
            destVC.delegate = self
        }
    }

}

// MARK: - EditProfileViewControllerDelegate

extension WelcomeViewController: EditProfileViewControllerDelegate {
    
    func editProfileViewControllerDidFinishEditing(controller: EditProfileViewController) {
        self.view.hidden = true
        controller.dismissViewControllerAnimated(true) { () -> Void in
            if let delegate = self.delegate {
                delegate.welcomeViewControllerDidFinish(self)
            }
        }
    }
    
}

