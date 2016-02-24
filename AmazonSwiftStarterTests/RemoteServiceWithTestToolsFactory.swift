//
//  RemoteServiceWithTestToolsFactory.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 24/02/16.
//  Copyright © 2016 Peter Fennema. All rights reserved.
//

import Foundation

class RemoteServiceWithTestToolsFactory {
    
    static func getDefaultService() -> RemoteServiceWithTestTools {
        return AMZRemoteServiceWithTestTools.defaultService()
    }

}
