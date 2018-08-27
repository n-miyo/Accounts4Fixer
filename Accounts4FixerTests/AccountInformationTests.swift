//
//  AccountInformationTests.swift
//  Accounts4FixerTests
//
//  Created by MIYOKAWA, Nobuyoshi on 2018/08/17.
//  Copyright © 2018年 MIYOKAWA, Nobuyoshi. All rights reserved.
//

import XCTest

@testable import Accounts4Fixer

class AccountInformationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

    func testCreateInstance() {
        let pk: Int64 = 123
        let description = "Description"

        let o = AccountInformation(pk: pk, description: description)
        XCTAssertEqual(o.accountProperties.count, 0, "Property is empty")
        XCTAssertEqual(o.pk, pk, "Get PrimaryKey")
        XCTAssertEqual(o.description, description, "Get Description")
    }

    func testUpdateDescription() {
        let pk: Int64 = 123
        let description = "DESCRIPTION"

        let o = AccountInformation(pk: pk, description: description)
        XCTAssertEqual(o.description, description, "Get Description")
        XCTAssertFalse(o.isDescriptionUpdated(), "Not updated")

        // Update description
        let newDescription = "New Description"
        o.update(description: newDescription)
        XCTAssertEqual(o.description, newDescription, "Get New Description")
        XCTAssertTrue(o.isDescriptionUpdated(), "Is updated")

        // Adopt userValue
        o.applyDescriptionUpdate()
        XCTAssertEqual(o.description, newDescription, "Get New Description")
        XCTAssertFalse(o.isDescriptionUpdated(), "Not updated")

        // Update description again, and reset it.
        o.resetDescriptionUpdate()
        let newDescription2 = "New Description 2"
        o.update(description: newDescription2)
        XCTAssertEqual(o.description, newDescription2, "Get New Description 2")
        XCTAssertTrue(o.isDescriptionUpdated(), "Is updated")
        o.resetDescriptionUpdate()
        XCTAssertEqual(o.description, newDescription, "Get New Description")
        XCTAssertFalse(o.isDescriptionUpdated(), "Not updated")
    }

    func testStoreProperty() {
        let pk: Int64 = 123
        let description = "Description"
        let o = AccountInformation(pk: pk, description: description)

        let value = true
        let dbValue = NSKeyedArchiver.archivedData(withRootObject: value)
        o.store(propertyKeyString: "AllowsInsecureAuthentication", archivedValue: dbValue, pk: pk)
        XCTAssertEqual(o.value(propertyKey: AccountProperty.PropertyKey.AllowsInsecureAuthentication) as! Bool, value)

        // Should be ignred invalid key silently
        o.store(propertyKeyString: "FooBar", archivedValue: dbValue, pk: pk)
    }

    func testUpdateProperty() {
        let pk: Int64 = 123
        let description = "Description"
        let o = AccountInformation(pk: pk, description: description)

        let value = "example.com"
        // Create new one.
        o.update(propertyKey: AccountProperty.PropertyKey.Hostname, value: value)
        XCTAssertEqual(o.value(propertyKey: AccountProperty.PropertyKey.Hostname) as! String, value)

        // Update one.
        let newValue = "example.org"
        o.update(propertyKey: AccountProperty.PropertyKey.Hostname, value: newValue)
        XCTAssertEqual(o.value(propertyKey: AccountProperty.PropertyKey.Hostname) as! String, newValue)

        // Should be ignred invalid key silently
        o.update(propertyKey: AccountProperty.PropertyKey.AuthenticationScheme, value: newValue)
    }

    func testUpdateDBValue() {
        let pk: Int64 = 123
        let description = "Description"
        let o = AccountInformation(pk: pk, description: description)

        let key = AccountProperty.PropertyKey.PortNumber
        let propPk: Int64 = 1230
        let value = "22"
        let dbValue = NSKeyedArchiver.archivedData(withRootObject: value)

        // Create new one.
        o.store(propertyKeyString: key.rawValue, archivedValue: dbValue, pk: propPk)
        XCTAssertEqual(o.accountProperties[key]?.pk, propPk)

        // Update one.
        let newPropPk: Int64 = 4560
        o.applyUpdate(propertyKey: key, pk: newPropPk)
        XCTAssertEqual(o.accountProperties[key]?.pk, newPropPk)

        // Should be ignred invalid key silently
        o.applyUpdate(propertyKey: AccountProperty.PropertyKey.AuthenticationScheme, pk: newPropPk)
    }

    func testRestAccountProperties() {
        let pk: Int64 = 123
        let description = "Description"
        let o = AccountInformation(pk: pk, description: description)

        // DB Value
        let key = AccountProperty.PropertyKey.AllowsInsecureAuthentication
        let value = true
        let dbValue = NSKeyedArchiver.archivedData(withRootObject: value)
        let propPk: Int64 = 123
        o.store(propertyKeyString: key.rawValue, archivedValue: dbValue, pk: propPk)
        XCTAssertEqual(o.accountProperties[key]!.value as! Bool, value)

        // User Value
        let key2 = AccountProperty.PropertyKey.Hostname
        let value2 = "example.com"
        o.update(propertyKey: key2, value: value2)
        XCTAssertEqual(o.accountProperties[key2]!.value as! String, value2)

        o.resetAllPropertyUpdates()
        XCTAssertEqual(o.accountProperties[key]!.value as! Bool, value)
        XCTAssertNil(o.accountProperties[key2])
    }

    func testIsPropertyUpdated() {
        let pk: Int64 = 123
        let description = "Description"
        let o = AccountInformation(pk: pk, description: description)

        let key = AccountProperty.PropertyKey.AllowsInsecureAuthentication
        let value = true
        let dbValue = NSKeyedArchiver.archivedData(withRootObject: value)
        let propPk: Int64 = 123
        o.store(propertyKeyString: key.rawValue, archivedValue: dbValue, pk: propPk)
        XCTAssertEqual(o.accountProperties[key]!.value as! Bool, value)

        let key2 = AccountProperty.PropertyKey.Hostname
        let value2 = "example.com"
        let dbValue2 = NSKeyedArchiver.archivedData(withRootObject: value2)
        let propPk2: Int64 = 456
        o.store(propertyKeyString: key2.rawValue, archivedValue: dbValue2, pk: propPk2)
        XCTAssertEqual(o.accountProperties[key2]!.value as! String, value2)

        // Not updated
        XCTAssertFalse(o.isAnyPropertyUpdated())

        // Updated
        let value3 = false
        o.update(propertyKey: key, value: value3)
        XCTAssertTrue(o.isAnyPropertyUpdated())
    }
}
