// Copyright (c) 2018 MIYOKAWA, Nobuyoshi. All rights reserved.

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        let defaults = UserDefaults.standard
        let appDefaults = [UserDefaultsConstants.Key.createBackupButtonState.rawValue: true]
        defaults.register(defaults: appDefaults)
    }

    func applicationWillTerminate(_: Notification) {
        // Insert code here to tear down your application
    }
}
