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
    }


    weak var delegate: WelcomeViewControllerDelegate?
    
    fileprivate var state: State = .welcome {
        didSet {
            switch state {
            case .welcome:
                showMessage("\"Anonymous Sign In\" will call AWS Cognito. The app will receive an identity token from the Cognito Service and will store it on the device.", type: GSMessageType.info, options: MessageOptions.Info)
                signInButton.isHidden = false
                createProfileButton.isHidden = true
            case .welcomed:
                showMessage("You are now signed in. An empty user profile with a unique userId has already been created behind the scenes in DynamoDB.", type: GSMessageType.info, options: MessageOptions.Info)
                signInButton.isHidden = true
                createProfileButton.isHidden = false
            }
        }
    }
    
    @IBOutlet weak var signInButton: ButtonWithActivityIndicator!
    
    @IBOutlet weak var createProfileButton: UIButton!
    
    
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
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        state = .welcome
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

