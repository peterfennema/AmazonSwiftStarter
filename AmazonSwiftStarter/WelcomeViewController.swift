//
//  WelcomeViewController.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 12/02/16.
//  Copyright © 2016 Peter Fennema. All rights reserved.
//

import UIKit
import GSMessages

protocol WelcomeViewControllerDelegate: class {
    
    func welcomeViewControllerDidFinish(controller: WelcomeViewController)
    
}

class WelcomeViewController: UIViewController {
    
    enum State {
        case Welcome
        case Welcomed
        case FetchingUserProfile
        case FetchedUserProfile
    }

    weak var delegate: WelcomeViewControllerDelegate?
    
    private var state: State = .Welcome {
        didSet {
            switch state {
            case .Welcome:
                showMessage("\"Anonymous Sign In\" will call AWS Cognito. The app will receive an identity token from the Cognito Service and will store it on the device.", type: GSMessageType.Info, options: MessageOptions.Info)
                signInButton.hidden = false
                createProfileButton.hidden = true
                continueButton.hidden = true
                orLabel.hidden = true
                activityIndicator.hidden = true
            case .Welcomed:
                showMessage("You are now signed in. An empty user profile with a unique userId has already been created behind the scenes in DynamoDB.", type: GSMessageType.Info, options: MessageOptions.Info)
                signInButton.hidden = true
                createProfileButton.hidden = false
                continueButton.hidden = true
                orLabel.hidden = true
                activityIndicator.hidden = true
            case .FetchingUserProfile:
                signInButton.hidden = true
                createProfileButton.hidden = true
                continueButton.hidden = true
                orLabel.hidden = true
                activityIndicator.hidden = false
                activityIndicator.startAnimating()
            case .FetchedUserProfile:
                showMessage("You are automatically signed in on your existing account. Your user profile data was fetched from AWS on the background.", type: GSMessageType.Info, options: MessageOptions.Info)
                signInButton.hidden = true
                createProfileButton.setTitle("Edit Profile", forState: UIControlState.Normal)
                createProfileButton.hidden = false
                continueButton.hidden = false
                orLabel.hidden = false
                activityIndicator.hidden = true
                activityIndicator.stopAnimating()
            }
        }
    }
    
    @IBOutlet weak var signInButton: ButtonWithActivityIndicator!
    
    @IBOutlet weak var createProfileButton: UIButton!
    
    @IBOutlet weak var continueButton: ButtonWithActivityIndicator!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var orLabel: UILabel!
    
    
    @IBAction func didTapSignInButton(sender: UIButton) {
        hideMessage()
        signInButton.startAnimating()
        RemoteServiceFactory.getDefaultService().createCurrentUser(nil) { (userData, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.state = .Welcomed
                self.signInButton.stopAnimating()
            })
        }
    }
    
    @IBAction func didTapContinueButton(sender: UIButton) {
        if let delegate = self.delegate {
            delegate.welcomeViewControllerDidFinish(self)
        }
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        let service = RemoteServiceFactory.getDefaultService()
        if service.hasCurrentUserIdentity {
            state = .FetchingUserProfile
            service.fetchCurrentUser({ (userData, error) -> Void in
                if let error = error {
                    print(error)
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.state = .FetchedUserProfile
                })
            })
        } else {
            state = .Welcome
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editProfileSegue" {
            hideMessage()
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

