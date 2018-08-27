// Copyright (c) 2018 MIYOKAWA, Nobuyoshi. All rights reserved.

import Foundation

class AccountProperty {
    enum PropertyKey: String {
        case
            AllowsInsecureAuthentication, // 1
            DisableDynamicConfiguration, // 1
            Hostname, // imap.example.com
            PortNumber, // 80143
            ServerPath, // IMAP
            // Unsupported
            AuthenticationScheme,
            SSLEnabled,
            ACPropertyFullName, // John Appleseed
            AllowsRecoverableTrustCertificate, // 0
            EmailAliases,
            /*
                * value: Optional(<__NSSingleObjectArrayI 0x604000002b00>(
                * {
                *     DisplayName = "John Appleseed";
                *     EmailAddresses = (
                *         {
                *             EmailAddress = "appleseed@example.com";
                *             IsDefault = 1;
                *             IsEnabled = 1;
                *         }
                *     );
                *     IsEnabled = 1;
                *     IsPrimary = 1;
                * }))
                */
            IdentityEmailAddress, // appleseed@example.com
            SecIdentityPersistentRef, // (Opaque)
            SendingAccountIdentifier // (UUIDv4)
    }

    private(set) var pk: Int64?
    private(set) var key: PropertyKey
    private var dbValue: Data?
    private var userValue: Data
    private(set) var ownerId: Int64

    var keyString: String {
        return key.rawValue
    }

    var value: Any {
        get {
            return NSKeyedUnarchiver.unarchiveObject(with: userValue)!
        }
        set(v) {
            userValue = AccountProperty.convToArchivedData(v)
        }
    }

    var valueArchived: Data {
        return userValue
    }

    init(pk: Int64, key: PropertyKey, dbValue: Data, ownerId: Int64) {
        self.pk = pk
        self.key = key
        self.dbValue = AccountProperty.fixWrongValueType(key: key, value: dbValue)
        userValue = self.dbValue!
        self.ownerId = ownerId
    }

    init(key: PropertyKey, userValue: Any, ownerId: Int64) {
        pk = nil
        self.key = key
        dbValue = nil
        self.userValue = AccountProperty.convToArchivedData(userValue)
        self.ownerId = ownerId
    }

    func isReadFromDB() -> Bool {
        return dbValue == nil ? false : true
    }

    func isUpdated() -> Bool {
        return dbValue != userValue // XXX
    }

    func applyUserValue(pk: Int64) {
        self.pk = pk
        dbValue = userValue
    }

    func resetToDBValue() {
        if let dbValue = self.dbValue {
            userValue = dbValue
        }
    }

    private static func convToArchivedData(_ data: Any) -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: data)
    }

    private static func fixWrongValueType(key: PropertyKey, value: Data) -> Data {
        var ret = value

        if key == PropertyKey.PortNumber {
            if let v = NSKeyedUnarchiver.unarchiveObject(with: value),
                let vv = v as? String,
                let num = Int64(vv) {
                ret = NSKeyedArchiver.archivedData(withRootObject: num)
            }
        }

        return ret
    }
}
