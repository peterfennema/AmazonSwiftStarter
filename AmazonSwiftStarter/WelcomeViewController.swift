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
    
    enum State {
        case Welcome
        case Welcomed
        case Error
    }


    weak var delegate: WelcomeViewControllerDelegate?
    
    private var state: State = .Welcome {
        didSet {
            switch state {
            case .Welcome:
                explanationLabel.text = "Anonymous Sign In wil call AWS Cognito. The app will receive an identity token from the Cognito service and will store it on the device."
                errorLabel.hidden = true
                signInButton.hidden = false
                createProfileButton.hidden = true
            case .Welcomed:
                explanationLabel.text = "You are now signed in. An empty user profile with a unique userId has already been created in DynamoDB. In the next step the user can add his username and a profile image. The username will be added to DynamoDB, the image will be uploaded to an S3 Bucket"
                errorLabel.hidden = true
                signInButton.hidden = true
                createProfileButton.hidden = false
            case .Error:
                errorLabel.hidden = false
            }
        }
    }
    

    @IBOutlet weak var explanationLabel: UILabel!
    
    @IBOutlet weak var errorLabel: ErrorLabel!
    
    @IBOutlet weak var signInButton: UIButton!
    
    @IBOutlet weak var createProfileButton: UIButton!
    
    
    @IBAction func didTapSignInButton(sender: UIButton) {
        state = .Welcomed
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        state = .Welcome
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editProfileSegue" {
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

