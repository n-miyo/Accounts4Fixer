// Copyright (c) 2018 MIYOKAWA, Nobuyoshi. All rights reserved.

import Foundation

class AccountInformation {
    var pk: Int64 = 0

    private var dbDescription = ""
    private var userDescription = ""
    private(set) var accountProperties: [AccountProperty.PropertyKey: AccountProperty] = [:]

    var description: String {
        return userDescription
    }

    init(pk: Int64, description: String) {
        self.pk = pk
        dbDescription = description
        userDescription = description
    }

    func update(description: String) {
        userDescription = description
    }

    func applyDescriptionUpdate() {
        dbDescription = userDescription
    }

    func resetDescriptionUpdate() {
        userDescription = dbDescription
    }

    func isDescriptionUpdated() -> Bool {
        return dbDescription != userDescription
    }

    func value(propertyKey: AccountProperty.PropertyKey) -> Any? {
        return accountProperties[propertyKey]?.value
    }

    func store(propertyKeyString: String, archivedValue: Data, pk: Int64) {
        if !isValid(propertyKeyString: propertyKeyString) {
            Log.d("InvalidKey: \(propertyKeyString)")
            return
        }
        let key = AccountProperty.PropertyKey(rawValue: propertyKeyString)!
        accountProperties[key] = AccountProperty(pk: pk, key: key, dbValue: archivedValue, ownerId: self.pk)
    }

    func update(propertyKey: AccountProperty.PropertyKey, value: Any) {
        if !isValid(propertyKeyString: propertyKey.rawValue) {
            Log.d("InvalidKey: \(propertyKey)")
            return
        }
        if let o = self.accountProperties[propertyKey] {
            o.value = value
        } else {
            accountProperties[propertyKey] = AccountProperty(key: propertyKey, userValue: value, ownerId: pk)
        }
    }

    func applyUpdate(propertyKey: AccountProperty.PropertyKey, pk: Int64) {
        if let p = self.accountProperties[propertyKey] {
            p.applyUserValue(pk: pk)
        } else {
            Log.d("InvalidKey: \(propertyKey)")
        }
    }

    func resetAllPropertyUpdates() {
        for (k, v) in accountProperties {
            if v.isReadFromDB() {
                v.resetToDBValue()
            } else {
                accountProperties[k] = nil
            }
        }
    }

    func isAnyPropertyUpdated() -> Bool {
        var ret = false
        for (_, v) in accountProperties {
            if v.isUpdated() {
                ret = true
                break
            }
        }
        return ret
    }

    private func isValid(propertyKeyString: String) -> Bool {
        var ret = false
        switch propertyKeyString {
        case AccountProperty.PropertyKey.Hostname.rawValue,
             AccountProperty.PropertyKey.PortNumber.rawValue,
             AccountProperty.PropertyKey.DisableDynamicConfiguration.rawValue,
             AccountProperty.PropertyKey.AllowsInsecureAuthentication.rawValue,
             AccountProperty.PropertyKey.ServerPath.rawValue:
            ret = true
        default:
            ret = false
        }

        return ret
    }
}
