// Copyright (c) 2018 MIYOKAWA, Nobuyoshi. All rights reserved.

import Foundation
import SQLite

class AccountManager {
    var accountInformations: [AccountInformation] = []

    let dbDirPath: String
    let dbName: String
    let dbPath: String

    init(dbDirPath: String, dbName: String) {
        self.dbDirPath = dbDirPath
        self.dbName = dbName
        dbPath = self.dbDirPath + "/" + self.dbName
    }

    convenience init() {
        let dbDirPath = NSHomeDirectory() + "/Library/Accounts"
        let dbName = "Accounts4.sqlite"
        self.init(dbDirPath: dbDirPath, dbName: dbName)
    }

    func load() {
        let connection = try! Connection(dbPath)
        let accountTypeID = findIMAPAccountTypeID(connection: connection)
        guard let id = accountTypeID else {
            Log.d("No IMAP account")
            return
        }
        let r = findAccount(connection: connection, accountTypeId: id)

        for x in r {
            if let description = x.description {
                let o = createAccountInformation(connection: connection, pk: x.pk, description: description)
                accountInformations.append(o)
            }
        }
        Log.d("Loaded: \(accountInformations)")
    }

    func save(accountInformation: AccountInformation, backup: Bool) -> Bool {
        if backup {
            if !createBackup() {
                return false
            }
        }

        let connection = try! Connection(dbPath)
        storeDescription(connection: connection, accountInformation: accountInformation)
        storeAccountProperetiesToDB(connection: connection, accountInformation: accountInformation)

        return true
    }

    func reset(accountInformation: AccountInformation) {
        accountInformation.resetDescriptionUpdate()
        accountInformation.resetAllPropertyUpdates()
    }

    private func findIMAPAccountTypeID(connection: Connection) -> Int64? {
        let IDENTIFIER_IMAP = "com.apple.account.IMAP"
        var result: Int64?

        let accountTypeTable = Table("ZACCOUNTTYPE")
        let pkExp = Expression<Int64>("Z_PK")
        let identifierExp = Expression<String?>("ZIDENTIFIER")

        let query =
            accountTypeTable.filter(identifierExp == IDENTIFIER_IMAP).limit(1)
        for r in try! connection.prepare(query) {
            result = r[pkExp]
        }

        return result
    }

    private func findAccount(connection: Connection, accountTypeId: Int64) -> [(pk: Int64, description: String?)] {
        var result: [(Int64, String?)] = []

        let accountTable = Table("ZACCOUNT")
        let pkExp = Expression<Int64>("Z_PK")
        let accountTypeExp = Expression<Int64>("ZACCOUNTTYPE")
        let parentAccountExp = Expression<Int64?>("ZPARENTACCOUNT")
        let accountDescriptionExp = Expression<String?>("ZACCOUNTDESCRIPTION")

        let query =
            accountTable.filter(
                accountTypeExp == accountTypeId && parentAccountExp == nil
            )
        for r in try! connection.prepare(query) {
            result.append((pk: r[pkExp], description: r[accountDescriptionExp]))
        }

        return result
    }

    private func createAccountInformation(connection: Connection, pk: Int64, description: String) -> AccountInformation {
        let accountPropertyTable = Table("ZACCOUNTPROPERTY")

        let pkExp = Expression<Int64>("Z_PK")
        let ownerExp = Expression<Int64>("ZOWNER")
        let keyExp = Expression<String>("ZKEY")
        let valueExp = Expression<Data>("ZVALUE")

        let query = accountPropertyTable.filter(ownerExp == pk)
        let ret = AccountInformation(pk: pk, description: description)
        for r in try! connection.prepare(query) {
            ret.store(propertyKeyString: r[keyExp], archivedValue: r[valueExp], pk: r[pkExp])
        }

        return ret
    }

    private func storeDescription(connection: Connection, accountInformation: AccountInformation) {
        if !accountInformation.isDescriptionUpdated() {
            return
        }

        let accountTable = Table("ZACCOUNT")
        let pkExp = Expression<Int64>("Z_PK")
        let accountDescriptionExp = Expression<String?>("ZACCOUNTDESCRIPTION")

        let account = accountTable.filter(pkExp == accountInformation.pk)
        let command = account.update(accountDescriptionExp <- accountInformation.description)
        do {
            try connection.run(command)
        } catch {
            Log.d("SQL update failed: \(error)")
        }
        accountInformation.applyDescriptionUpdate()
    }

    private func storeAccountProperetiesToDB(connection: Connection, accountInformation: AccountInformation) {
        Log.d("AccountInformation: \(accountInformation.description)")
        for (_, v) in accountInformation.accountProperties {
            if v.isUpdated() {
                Log.d("accountProperty: \(accountInformation.description)")
                let pk: Int64? = storeAccountProperety(connection: connection, accountProperty: v)
                if let pk = pk {
                    // Update PK
                    accountInformation.applyUpdate(propertyKey: v.key, pk: pk)
                }
            }
        }
    }

    private func storeAccountProperety(connection: Connection, accountProperty: AccountProperty) -> Int64? {
        let accountPropertyTable = Table("ZACCOUNTPROPERTY")

        let pkExp = Expression<Int64>("Z_PK")
        let entExp = Expression<Int64>("Z_ENT")
        let optExp = Expression<Int64>("Z_OPT")
        let ownerExp = Expression<Int64>("ZOWNER")
        let keyExp = Expression<String>("ZKEY")
        let valueExp = Expression<Data>("ZVALUE")

        let entValue: Int64 = 3
        let optValue: Int64 = 1

        let pk = accountProperty.pk
        let ownerId = accountProperty.ownerId
        let key = accountProperty.keyString

        var retPk: Int64?
        if let pk = pk {
            retPk = pk
            let property = accountPropertyTable.filter(pkExp == pk)
            let command = property.update(
                entExp <- entValue,
                optExp <- optValue,
                ownerExp <- ownerId,
                keyExp <- key,
                valueExp <- accountProperty.valueArchived
            )
            do {
                try connection.run(command)
            } catch {
                Log.d("SQL update failed: \(error)")
            }
        } else {
            let command = accountPropertyTable.insert(
                entExp <- entValue,
                optExp <- optValue,
                ownerExp <- ownerId,
                keyExp <- key,
                valueExp <- accountProperty.valueArchived
            )
            do {
                retPk = try connection.run(command)
            } catch {
                Log.d("SQL insert failed: \(error)")
            }
        }
        Log.d("Save: Key: \(key) / Val: \(accountProperty.value)")

        return retPk
    }

    private func createBackup() -> Bool {
        let date = Date()
        let options: ISO8601DateFormatter.Options = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let dateString = ISO8601DateFormatter.string(from: date, timeZone: TimeZone.current, formatOptions: options)
        let newDbDirPath = dbDirPath + "-\(dateString)"

        do {
            try FileManager.default.copyItem(atPath: dbDirPath, toPath: newDbDirPath)
        } catch {
            Log.d("Failed to copy dir: \(newDbDirPath)")
            return false
        }

        return true
    }
}
