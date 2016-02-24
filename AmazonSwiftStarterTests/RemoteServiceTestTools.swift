//
//  RemoteServiceTestTools.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 23/02/16.
//  Copyright © 2016 Peter Fennema. All rights reserved.
//

import Foundation
@testable import AmazonSwiftStarter

protocol RemoteServiceWithTestTools: RemoteService {
    
    func removeCurrentUser()
    
}
