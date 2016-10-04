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
    
    func welcomeViewControllerDidFinish(_ controller: WelcomeViewController)
    
}

class WelcomeViewController: UIViewController {
    
    enum State {
        case welcome
        case welcomed
        case fetchingUserProfile
        case fetchedUserProfile
    }

    weak var delegate: WelcomeViewControllerDelegate?
    
    fileprivate var state: State = .welcome {
        didSet {
            switch state {
            case .welcome:
                showMessage("\"Anonymous Sign In\" will call AWS Cognito. The app will receive an identity token from the Cognito Service and will store it on the device.", type: GSMessageType.info, options: MessageOptions.Info)
                signInButton.isHidden = false
                createProfileButton.isHidden = true
                continueButton.isHidden = true
                orLabel.isHidden = true
                activityIndicator.isHidden = true
            case .welcomed:
                showMessage("You are now signed in. An empty user profile with a unique userId has already been created behind the scenes in DynamoDB.", type: GSMessageType.info, options: MessageOptions.Info)
                signInButton.isHidden = true
                createProfileButton.isHidden = false
                continueButton.isHidden = true
                orLabel.isHidden = true
                activityIndicator.isHidden = true
            case .fetchingUserProfile:
                signInButton.isHidden = true
                createProfileButton.isHidden = true
                continueButton.isHidden = true
                orLabel.isHidden = true
                activityIndicator.isHidden = false
                activityIndicator.startAnimating()
            case .fetchedUserProfile:
                showMessage("You are automatically signed in on your existing account. Your user profile data was fetched from AWS on the background.", type: GSMessageType.info, options: MessageOptions.Info)
                signInButton.isHidden = true
                createProfileButton.setTitle("Edit Profile", for: UIControlState())
                createProfileButton.isHidden = false
                continueButton.isHidden = false
                orLabel.isHidden = false
                activityIndicator.isHidden = true
                activityIndicator.stopAnimating()
            }
        }
    }
    
    @IBOutlet weak var signInButton: ButtonWithActivityIndicator!
    
    @IBOutlet weak var createProfileButton: UIButton!
    
    @IBOutlet weak var continueButton: ButtonWithActivityIndicator!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var orLabel: UILabel!
    
    
    @IBAction func didTapSignInButton(_ sender: UIButton) {
        hideMessage()
        signInButton.startAnimating()
        RemoteServiceFactory.getDefaultService().createCurrentUser(nil) { (error) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
                self.state = .welcomed
                self.signInButton.stopAnimating()
            })
        }
    }
    
    @IBAction func didTapContinueButton(_ sender: UIButton) {
        if let delegate = self.delegate {
            delegate.welcomeViewControllerDidFinish(self)
        }
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        let service = RemoteServiceFactory.getDefaultService()
        if service.hasCurrentUserIdentity {
            state = .fetchingUserProfile
            service.fetchCurrentUser({ (userData, error) -> Void in
                if let error = error {
                    print(error)
                }
                DispatchQueue.main.async(execute: { () -> Void in
                    self.state = .fetchedUserProfile
                })
            })
        } else {
            state = .welcome
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editProfileSegue" {
            hideMessage()
            let destVC = segue.destination as! EditProfileViewController
            destVC.delegate = self
        }
    }

}

// MARK: - EditProfileViewControllerDelegate

extension WelcomeViewController: EditProfileViewControllerDelegate {
    
    func editProfileViewControllerDidFinishEditing(_ controller: EditProfileViewController) {
        self.view.isHidden = true
        controller.dismiss(animated: true) { () -> Void in
            if let delegate = self.delegate {
                delegate.welcomeViewControllerDidFinish(self)
            }
        }
    }
    
}

