//
//  ButtonWithActivityIndicator.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 05/09/15.
//  Copyright (c) 2015 peterfennema.nl. All rights reserved.
//

import UIKit

class ButtonWithActivityIndicator: UIButton {

    private (set) var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
    
    var buttonTitleText = "" {
        didSet {
            setTitle(buttonTitleText, forState: UIControlState.Normal)
            self.titleLabel?.hidden = false
        }
    }
    
    var showTitleTextAfterAnimation = true
    
    init() {
        super.init(frame: CGRectZero)
        configure()
    }
    
    // This is required by the NSCoding protocol
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    private func configure() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidden = true
        buttonTitleText = titleLabel?.text ?? ""
        self.addSubview(activityIndicator)
        addLayoutConstraints()
    }
    
    private func addLayoutConstraints() {
        let cWidth = NSLayoutConstraint(item: activityIndicator, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 20)
        let cHeight = NSLayoutConstraint(item: activityIndicator, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 20)
        activityIndicator.addConstraints([cWidth, cHeight])
        let cCenterX = NSLayoutConstraint(item: activityIndicator, attribute: .CenterX, relatedBy: .Equal, toItem: self, attribute: .CenterX, multiplier: 1, constant: 0)
        let cCenterY = NSLayoutConstraint(item: activityIndicator, attribute: .CenterY, relatedBy: .Equal, toItem: self, attribute: .CenterY, multiplier: 1, constant: 0)
        self.addConstraints([cCenterX, cCenterY])
    }
    
    func startAnimating() {
        titleLabel?.text = "" // prevents flashing text after activityIndicator animation
        setTitle("", forState: UIControlState.Normal)
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
    }

    func stopAnimating() {
        if showTitleTextAfterAnimation {
            setTitle(buttonTitleText, forState: UIControlState.Normal)
        }
        activityIndicator.stopAnimating()
        activityIndicator.hidden = true
    }
    
}
