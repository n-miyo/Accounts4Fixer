//
//  AccountPropertyTests.swift
//  Accounts4FixerTests
//
//  Created by MIYOKAWA, Nobuyoshi on 2018/08/17.
//  Copyright © 2018年 MIYOKAWA, Nobuyoshi. All rights reserved.
//

import XCTest

@testable import Accounts4Fixer

class AccountPropertyTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testCreateDBValueInstance() {
        let pk: Int64 = 456
        let key = AccountProperty.PropertyKey.AllowsInsecureAuthentication
        let value = true
        let dbValue = NSKeyedArchiver.archivedData(withRootObject: value)
        let ownerId: Int64 = 123

        let o = AccountProperty(pk: pk, key: key, dbValue: dbValue, ownerId: ownerId)
        XCTAssertNotNil(o, "Create DBValue instance.")
        XCTAssertEqual(o.ownerId, ownerId, "Get ownerId")
        XCTAssertEqual(o.key, key, "Get key")
        XCTAssertEqual(o.value as! Bool, value, "Get value")
        XCTAssertEqual(o.pk, pk, "Get PK")
        XCTAssertTrue(o.isReadFromDB(), "Read from DB")
        XCTAssertFalse(o.isUpdated(), "Not updated")

        XCTAssertEqual(o.keyString, "AllowsInsecureAuthentication", "Get key")
        XCTAssertEqual(o.valueArchived, dbValue, "Get ArchivedData")
    }

    func testCreateUserValueInstance() {
        let key = AccountProperty.PropertyKey.Hostname
        let value = "example.com"
        let ownerId: Int64 = 1230

        let o = AccountProperty(key: key, userValue: value, ownerId: ownerId)
        XCTAssertNotNil(o, "Create UserValue instance.")
        XCTAssertEqual(o.ownerId, ownerId, "Get ownerId")
        XCTAssertEqual(o.key, key, "Get key")
        XCTAssertEqual(o.value as! String, value, "Get value")
        XCTAssertEqual(o.pk, nil, "PK remains as nil")
        XCTAssertFalse(o.isReadFromDB(), "Not read from DB")
        XCTAssertTrue(o.isUpdated(), "Is updated")

        let valueArchived = NSKeyedArchiver.archivedData(withRootObject: value)
        XCTAssertEqual(o.keyString, "Hostname", "Get key")
        XCTAssertEqual(o.valueArchived, valueArchived, "Get ArchivedData")
    }

    func testUpdateDBValue() {
        let pk: Int64 = 564
        let key = AccountProperty.PropertyKey.PortNumber
        let value: Int64 = 23
        let dbValue = NSKeyedArchiver.archivedData(withRootObject: value)
        let ownerId: Int64 = 231

        let o = AccountProperty(pk: pk, key: key, dbValue: dbValue, ownerId: ownerId)
        XCTAssertNotNil(o, "Create DBValue instance.")
        XCTAssertEqual(o.pk, pk, "Get PK")

        // Update userValue
        let newValue: Int64 = 22
        let newValueArchived = NSKeyedArchiver.archivedData(withRootObject: newValue)
        XCTAssertFalse(o.isUpdated(), "Not updated")
        o.value = newValue
        XCTAssertEqual(o.value as! Int64, newValue, "Get new value")
        XCTAssertTrue(o.isUpdated(), "Is updated")
        XCTAssertEqual(o.valueArchived, newValueArchived, "Get ArchivedData")

        // Adopot userValue
        let newPk: Int64 = 5640
        o.adoptUserValue(pk: newPk)
        XCTAssertEqual(o.pk, newPk, "Get PK")
        XCTAssertEqual(o.value as! Int64, newValue, "Get new value")
        XCTAssertFalse(o.isUpdated(), "Not updated")

        // Update userValue again, and reset it.
        let newValue2: Int64 = 2222
        o.value = newValue2
        XCTAssertEqual(o.value as! Int64, newValue2, "Get new value")
        XCTAssertTrue(o.isUpdated(), "Is updated")
        o.resetToDBValue()
        XCTAssertEqual(o.value as! Int64, newValue, "Get new value")
        XCTAssertFalse(o.isUpdated(), "Not updated")
    }

    func testUpdateUserValue() {
        let key = AccountProperty.PropertyKey.ServerPath
        let value = "serverPath"
        let ownerId: Int64 = 1234

        let o = AccountProperty(key: key, userValue: value, ownerId: ownerId)
        XCTAssertNotNil(o, "Create UserValue instance.")
        XCTAssertEqual(o.pk, nil, "PK remains as nil")

        // Update userValue
        let newValue = "updatedServerPath"
        let newValueArchived = NSKeyedArchiver.archivedData(withRootObject: newValue)
        XCTAssertTrue(o.isUpdated(), "Is updated")
        o.value = newValue
        XCTAssertEqual(o.value as! String, newValue, "Get new value")
        XCTAssertTrue(o.isUpdated(), "Is updated")
        XCTAssertEqual(o.valueArchived, newValueArchived, "Get ArchivedData")

        // Adopot userValue
        let newPk: Int64 = 4567
        o.adoptUserValue(pk: newPk)
        XCTAssertEqual(o.pk, newPk, "Get PK")
        XCTAssertEqual(o.value as! String, newValue, "Get new value")
        XCTAssertFalse(o.isUpdated(), "Not updated")
    }
}
