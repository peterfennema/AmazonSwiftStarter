//
//  EditProfileViewController.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 12/02/16.
//  Copyright © 2016 Peter Fennema. All rights reserved.
//

import UIKit

protocol EditProfileViewControllerDelegate: class {
    
    func editProfileViewControllerDidFinishEditing(controller: EditProfileViewController)
    
}

class EditProfileViewController: UIViewController {
    
    weak var delegate: EditProfileViewControllerDelegate?
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var imageView: UIImageView!
    
    
    @IBAction func didTapDone(sender: UIButton) {
        if let delegate = delegate {
            delegate.editProfileViewControllerDidFinishEditing(self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showMessage("After tapping \"Done\" your name will be saved to DynamoDB. Your image will be saved to S3.", type: .Info, options: MessageOptions.Info)
    }

}
