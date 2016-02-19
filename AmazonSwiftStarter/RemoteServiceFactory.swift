//
//  RemoteServiceFactory.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 15/02/16.
//  Copyright © 2016 Peter Fennema. All rights reserved.
//

import Foundation

class RemoteServiceFactory {
    
    static func getDefaultService() -> RemoteService {
        return AMZRemoteService.defaultService()
    }
}