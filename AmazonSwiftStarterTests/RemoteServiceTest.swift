//
//  AMZRemoteServiceTest.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 23/02/16.
//  Copyright © 2016 Peter Fennema. All rights reserved.
//

import XCTest
@testable import AmazonSwiftStarter

class RemoteServiceTest: XCTestCase {
    
    let service = RemoteServiceWithTestToolsFactory.getDefaultService()
    
    var testBundle: NSBundle!


    override func setUp() {
        super.setUp()
        service.removeCurrentUser()
        if testBundle == nil {
            testBundle = NSBundle(forClass: RemoteServiceTest.self)
        }
    }
    
    override func tearDown() {
        service.removeCurrentUser()
        super.tearDown()
    }

    
    func testThatCreateCurrenUserWithNameCausesNoError() {
        
        // given
        // A user with name "AA"
        
        var user = UserDataValue()
        user.name = "AA"
        
        // when
        // this user is created as current user on the server
        
        let exp = expectationWithDescription("testThatCreateCurrenUserWithNameCausesNoError")
        service.createCurrentUser(user) { (error) -> Void in
            
            // then
            // no error should occur
            
            XCTAssertNil(error, "error: \(error)")
            
            exp.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    
    func testThatCreateCurrenUserWithNameAndImageCausesNoError() {
        
        // given
        // A user with name "AA" and an image
        
        var user = UserDataValue()
        user.name = "AA"
        let img = UIImage(named: "female", inBundle: testBundle, compatibleWithTraitCollection: nil)
        XCTAssertNotNil(img)
        user.imageData = UIImageJPEGRepresentation(img!, 0.6)
        
        // when
        // this user is created as current user on the server
        
        let exp = expectationWithDescription("testThatCreateCurrenUserWithNameAndImageCausesNoError")
        service.createCurrentUser(user) { (error) -> Void in
            
            // then
            // no error should occur
            
            XCTAssertNil(error, "error: \(error)")
            
            exp.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }

    
    func testThatUpdateCurrenUserWithNewNameCausesNoError() {
        
        // given
        // A user with name "AA", stored on the server

        var user = UserDataValue()
        user.name = "AA"
        
        let exp = expectationWithDescription("testThatCreateCurrenUserWithNameCausesNoError")
        service.createCurrentUser(user) { (error) -> Void in
            XCTAssertNil(error, "error: \(error)")
            exp.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)


        // when
        // this user's name is updated and updateCurrentUser is called
        
        user.name = "BB"
        
        let exp1 = expectationWithDescription("testThatCreateCurrenUserWithNameCausesNoError1")
        service.updateCurrentUser(user) { (error) -> Void in
            
            // then
            // no error should occur
            
            XCTAssertNil(error, "error: \(error)")
            exp1.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
    }
    
    
    func testThatFetchCurrentUserWithoutImageCausesNoError() {
        
        // given
        // A user with name "AA", without image, stored on the server

        var user = UserDataValue()
        user.name = "AA"
        
        let exp = expectationWithDescription("testThatFetchCurrentUserWithoutImageCausesNoError")
        service.createCurrentUser(user) { (error) -> Void in
            XCTAssertNil(error, "error: \(error)")
            exp.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
        
        // when
        // The userdata is fetched
        
        let exp1 = expectationWithDescription("testThatFetchCurrentUserWithoutImageCausesNoError1")
        service.fetchCurrentUser { (userData, error) -> Void in
            
            // then
            // The userdata must be returned, with property imageData == nil, and error == nil
            
            XCTAssertNil(error, "error: \(error)")
            XCTAssertNotNil(userData)
            XCTAssertNotNil(userData!.name)
            XCTAssertEqual(userData!.name!, "AA")
            XCTAssertNil(userData!.imageData)
            
            exp1.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
        
    }

    func testThatFetchCurrentUserWithImageCausesNoError() {
        
        // given
        // A user with name "AA", with image, stored on the server
        
        var user = UserDataValue()
        user.name = "AA"
        let img = UIImage(named: "female", inBundle: testBundle, compatibleWithTraitCollection: nil)
        XCTAssertNotNil(img)
        user.imageData = UIImageJPEGRepresentation(img!, 0.6)
        
        let exp = expectationWithDescription("testThatFetchCurrentUserWithImageCausesNoError")
        service.createCurrentUser(user) { (error) -> Void in
            XCTAssertNil(error, "error: \(error)")
            exp.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
        
        // when
        // The userdata is fetched
        
        let exp1 = expectationWithDescription("testThatFetchCurrentUserWithImageCausesNoError1")
        service.fetchCurrentUser { (userData, error) -> Void in
            
            // then
            // The userdata must be returned, with property imageData != nil, and error == nil
            
            XCTAssertNil(error, "error: \(error)")
            XCTAssertNotNil(userData)
            XCTAssertNotNil(userData!.name)
            XCTAssertEqual(userData!.name!, "AA")
            XCTAssertNotNil(userData!.imageData)
            XCTAssertTrue(user.imageData!.isEqualToData(userData!.imageData!))
            
            exp1.fulfill()
        }
        waitForExpectationsWithTimeout(10, handler: nil)
        
    }

    
}
