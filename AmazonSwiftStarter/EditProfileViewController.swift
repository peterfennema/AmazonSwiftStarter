//
//  EditProfileViewController.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 12/02/16.
//  Copyright © 2016 Peter Fennema. All rights reserved.
//

import UIKit

protocol EditProfileViewControllerDelegate: class {
    
    func editProfileViewControllerDidFinishEditing(_ controller: EditProfileViewController)
    
}

class EditProfileViewController: UIViewController {
    
    weak var delegate: EditProfileViewControllerDelegate?
    
    fileprivate var imageModified: Bool = false
    
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var doneButton: ButtonWithActivityIndicator!
    
    @IBAction func didTapDone(_ sender: UIButton) {
        doneButton.startAnimating()
        var userData = UserDataValue()
        userData.updateWithData(RemoteServiceFactory.getDefaultService().currentUser!)
        userData.name = nameTextField.text
        if imageModified {
            if let image = imageView.image {
                userData.imageData = UIImageJPEGRepresentation(image, 0.4)
            } else {
                userData.imageData = nil
            }
            imageModified = false
        }
        RemoteServiceFactory.getDefaultService().updateCurrentUser(userData) { (error) -> Void in
            DispatchQueue.main.async(execute: { () -> Void in
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
        updateUI(currentUser)
        imageView.isUserInteractionEnabled = true
        let tapRec = UITapGestureRecognizer(target: self, action: #selector(EditProfileViewController.didTapImageView(_:)))
        imageView.addGestureRecognizer(tapRec)
        showMessage("After tapping \"Done\" your name will be saved to DynamoDB. Your image will be saved to S3.", type: .info, options: MessageOptions.Info)
    }
    
    func didTapImageView(_ recognizer: UIGestureRecognizer) {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func updateUI(_ userData: UserData) {
        nameTextField.text = userData.name
        if userData.imageData == nil {
            imageView.image = UIImage(named: "unknownUser")
        } else {
            imageView.image = UIImage(data: userData.imageData! as Data)
        }
    }

}


extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let capturedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.imageView.image = capturedImage
            imageModified = true
            picker.dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    
}
