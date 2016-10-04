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
    
    var testBundle: Bundle!


    override func setUp() {
        super.setUp()
        service.removeCurrentUser()
        if testBundle == nil {
            testBundle = Bundle(for: RemoteServiceTest.self)
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
        
        let exp = expectation(description: "testThatCreateCurrenUserWithNameCausesNoError")
        service.createCurrentUser(user) { (error) -> Void in
            
            // then
            // no error should occur
            
            XCTAssertNil(error, "error: \(error)")
            
            exp.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    
    func testThatCreateCurrenUserWithNameAndImageCausesNoError() {
        
        // given
        // A user with name "AA" and an image
        
        var user = UserDataValue()
        user.name = "AA"
        let img = UIImage(named: "female", in: testBundle, compatibleWith: nil)
        XCTAssertNotNil(img)
        user.imageData = UIImageJPEGRepresentation(img!, 0.6)
        
        // when
        // this user is created as current user on the server
        
        let exp = expectation(description: "testThatCreateCurrenUserWithNameAndImageCausesNoError")
        service.createCurrentUser(user) { (error) -> Void in
            
            // then
            // no error should occur
            
            XCTAssertNil(error, "error: \(error)")
            
            exp.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }

    
    func testThatUpdateCurrenUserWithNewNameCausesNoError() {
        
        // given
        // A user with name "AA", stored on the server

        var user = UserDataValue()
        user.name = "AA"
        
        let exp = expectation(description: "testThatCreateCurrenUserWithNameCausesNoError")
        service.createCurrentUser(user) { (error) -> Void in
            XCTAssertNil(error, "error: \(error)")
            exp.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)


        // when
        // this user's name is updated and updateCurrentUser is called
        
        user.name = "BB"
        
        let exp1 = expectation(description: "testThatCreateCurrenUserWithNameCausesNoError1")
        service.updateCurrentUser(user) { (error) -> Void in
            
            // then
            // no error should occur
            
            XCTAssertNil(error, "error: \(error)")
            exp1.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    
    func testThatFetchCurrentUserWithoutImageCausesNoError() {
        
        // given
        // A user with name "AA", without image, stored on the server

        var user = UserDataValue()
        user.name = "AA"
        
        let exp = expectation(description: "testThatFetchCurrentUserWithoutImageCausesNoError")
        service.createCurrentUser(user) { (error) -> Void in
            XCTAssertNil(error, "error: \(error)")
            exp.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
        
        // when
        // The userdata is fetched
        
        let exp1 = expectation(description: "testThatFetchCurrentUserWithoutImageCausesNoError1")
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
        waitForExpectations(timeout: 10, handler: nil)
        
    }

    func testThatFetchCurrentUserWithImageCausesNoError() {
        
        // given
        // A user with name "AA", with image, stored on the server
        
        var user = UserDataValue()
        user.name = "AA"
        let img = UIImage(named: "female", in: testBundle, compatibleWith: nil)
        XCTAssertNotNil(img)
        user.imageData = UIImageJPEGRepresentation(img!, 0.6)
        
        let exp = expectation(description: "testThatFetchCurrentUserWithImageCausesNoError")
        service.createCurrentUser(user) { (error) -> Void in
            XCTAssertNil(error, "error: \(error)")
            exp.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
        
        // when
        // The userdata is fetched
        
        let exp1 = expectation(description: "testThatFetchCurrentUserWithImageCausesNoError1")
        service.fetchCurrentUser { (userData, error) -> Void in
            
            // then
            // The userdata must be returned, with property imageData != nil, and error == nil
            
            XCTAssertNil(error, "error: \(error)")
            XCTAssertNotNil(userData)
            XCTAssertNotNil(userData!.name)
            XCTAssertEqual(userData!.name!, "AA")
            XCTAssertNotNil(userData!.imageData)
            XCTAssertEqual(user.imageData!, userData!.imageData!)
            
            exp1.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
        
    }

    
}
