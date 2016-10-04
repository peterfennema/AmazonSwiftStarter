//
//  ComingSoonViewController.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 15/02/16.
//  Copyright © 2016 Peter Fennema. All rights reserved.
//

import UIKit

class ComingSoonViewController: UIViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showMessage("More AWS features will be added here later", type: .info, options: MessageOptions.Info)
    }


}
