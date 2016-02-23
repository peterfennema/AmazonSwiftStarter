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
    
    @IBOutlet weak var doneButton: ButtonWithActivityIndicator!
    
    @IBAction func didTapDone(sender: UIButton) {
        doneButton.startAnimating()
        var userData = UserDataValue()
        userData.name = nameTextField.text
        if let image = imageView.image {
            userData.imageData = UIImageJPEGRepresentation(image, 1.0)
        } else {
            userData.imageData = nil
        }
        RemoteServiceFactory.getDefaultService().updateCurrentUser(userData) { (userData, error) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.doneButton.stopAnimating()
                if let delegate = self.delegate {
                    delegate.editProfileViewControllerDidFinishEditing(self)
                }
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let currentUser = RemoteServiceFactory.getDefaultService().currentUser else {
            preconditionFailure("CurrentUser must be available")
        }
        updateImageViewWithImageData(currentUser.imageData)
        imageView.userInteractionEnabled = true
        let tapRec = UITapGestureRecognizer(target: self, action: "didTapImageView:")
        imageView.addGestureRecognizer(tapRec)
        showMessage("After tapping \"Done\" your name will be saved to DynamoDB. Your image will be saved to S3.", type: .Info, options: MessageOptions.Info)
    }
    
    func didTapImageView(recognizer: UIGestureRecognizer) {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        picker.delegate = self
        presentViewController(picker, animated: true, completion: nil)
    }
    
    func updateImageViewWithImageData(data: NSData?) {
        if data == nil {
            imageView.image = UIImage(named: "unknownUser")
        } else {
            imageView.image = UIImage(data: data!)
        }
    }

}


extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let capturedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.imageView.image = capturedImage
            picker.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }

    
}