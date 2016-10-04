//
//  ButtonWithActivityIndicator.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 05/09/15.
//  Copyright (c) 2015 peterfennema.nl. All rights reserved.
//

import UIKit

class ButtonWithActivityIndicator: UIButton {

    fileprivate (set) var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.white)
    
    var buttonTitleText = "" {
        didSet {
            setTitle(buttonTitleText, for: UIControlState())
            self.titleLabel?.isHidden = false
        }
    }
    
    var showTitleTextAfterAnimation = true
    
    init() {
        super.init(frame: CGRect.zero)
        configure()
    }
    
    // This is required by the NSCoding protocol
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    fileprivate func configure() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.isHidden = true
        buttonTitleText = titleLabel?.text ?? ""
        self.addSubview(activityIndicator)
        addLayoutConstraints()
    }
    
    fileprivate func addLayoutConstraints() {
        let cWidth = NSLayoutConstraint(item: activityIndicator, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20)
        let cHeight = NSLayoutConstraint(item: activityIndicator, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 20)
        activityIndicator.addConstraints([cWidth, cHeight])
        let cCenterX = NSLayoutConstraint(item: activityIndicator, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1, constant: 0)
        let cCenterY = NSLayoutConstraint(item: activityIndicator, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0)
        self.addConstraints([cCenterX, cCenterY])
    }
    
    func startAnimating() {
        titleLabel?.text = "" // prevents flashing text after activityIndicator animation
        setTitle("", for: UIControlState())
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }

    func stopAnimating() {
        if showTitleTextAfterAnimation {
            setTitle(buttonTitleText, for: UIControlState())
        }
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
    }
    
}
