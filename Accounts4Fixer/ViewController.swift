// Copyright (c) 2018 MIYOKAWA, Nobuyoshi. All rights reserved.

import Cocoa

class ViewController: NSViewController {
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var descriptionLabel: NSTextField!
    @IBOutlet var descriptionField: NSTextField!
    @IBOutlet var hostnameLabel: NSTextField!
    @IBOutlet var hostnameField: NSTextField!
    @IBOutlet var portLabel: NSTextField!
    @IBOutlet var portField: NSTextField!
    @IBOutlet var prefixLabel: NSTextField!
    @IBOutlet var prefixField: NSTextField!
    @IBOutlet var allowsInsecureButton: NSButton!
    @IBOutlet var disableDynamicConfigurationButton: NSButton!
    @IBOutlet var saveButton: NSButton!
    @IBOutlet var resetButton: NSButton!
    @IBOutlet var createBackupButton: NSButton!

    var accountManager: AccountManager?
    var accountInformations: [AccountInformation]?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.target = self

        descriptionLabel.stringValue =
            NSLocalizedString("description_label", comment: "")
        descriptionField.delegate = self
        hostnameLabel.stringValue =
            NSLocalizedString("hostname_label", comment: "")
        hostnameField.delegate = self
        portLabel.stringValue =
            NSLocalizedString("port_label", comment: "")
        portField.delegate = self
        prefixLabel.stringValue =
            NSLocalizedString("prefix_label", comment: "")
        prefixField.delegate = self
        allowsInsecureButton.title =
            NSLocalizedString("allows_insecure_button", comment: "")
        disableDynamicConfigurationButton.title =
            NSLocalizedString("disable_dynamic_configuration_button", comment: "")
        saveButton.title =
            NSLocalizedString("save_button", comment: "")
        resetButton.title =
            NSLocalizedString("reset_button", comment: "")
        createBackupButton.title =
            NSLocalizedString("create_backup_button", comment: "")

        accountManager = AccountManager()
        reloadAccountList()
    }

    override func viewWillAppear() {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String
        view.window?.title = appName

        saveButton.isEnabled = false

        let defaults = UserDefaults.standard
        let v = NSControl.StateValue(defaults.integer(forKey: UserDefaultsConstants.Key.createBackupButtonState.rawValue))
        createBackupButton.state = v
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    @IBAction func didPushSaveButton(_: Any) {
        guard let accountManager = self.accountManager else {
            return
        }
        if let accountInformation = self.selectedAccountInformation() {
            _ = accountManager.save(accountInformation: accountInformation, backup: createBackupButton.state == .on)
            updateSaveButtonEnabled(forAccountInformation: accountInformation)
        }
    }

    @IBAction func didPushResetButton(_: Any) {
        guard let accountManager = self.accountManager else {
            return
        }
        if let accountInformation = self.selectedAccountInformation() {
            accountManager.reset(accountInformation: accountInformation)
            updatePropertyViews(forAccountInformation: accountInformation)
            updateSaveButtonEnabled(forAccountInformation: accountInformation)
        }
    }

    @IBAction func didPushCreateBackupButton(_: Any) {
        let s = createBackupButton.state
        let defaults = UserDefaults.standard
        defaults.set(s.rawValue, forKey: UserDefaultsConstants.Key.createBackupButtonState.rawValue)
    }

    @IBAction func didPushAllowsInsecureButton(_: Any) {
        guard let accountInformation = self.selectedAccountInformation() else {
            return
        }
        let s = allowsInsecureButton.state
        accountInformation.update(
            propertyKey: AccountProperty.PropertyKey.AllowsInsecureAuthentication,
            value: s == NSControl.StateValue.on
        )
        updateSaveButtonEnabled(forAccountInformation: accountInformation)
    }

    @IBAction func didPushDisableDynamicConfigurationButton(_: Any) {
        guard let accountInformation = self.selectedAccountInformation() else {
            return
        }
        let s = disableDynamicConfigurationButton.state
        accountInformation.update(
            propertyKey: AccountProperty.PropertyKey.DisableDynamicConfiguration,
            value: s == NSControl.StateValue.off
        ) // CAUTION: button state is opposite
        updateSaveButtonEnabled(forAccountInformation: accountInformation)
    }

    func reloadAccountList() {
        guard let accountManager = self.accountManager else {
            return
        }
        accountManager.load()
        accountInformations = accountManager.accountInformations
        tableView.reloadData()
        if (accountInformations?.count)! >= 0 {
            tableView.selectRowIndexes(.init(integer: 0), byExtendingSelection: false)
        }
    }

    func selectedAccountInformation() -> AccountInformation? {
        let row = tableView.selectedRow
        if row < 0 {
            return nil
        }
        guard let accountInformations = self.accountInformations else {
            return nil
        }
        let accountInformation = accountInformations[row]
        Log.d("SelectedAccount: \(accountInformation)")

        return accountInformation
    }

    func updatePropertyViews(forAccountInformation accountInformation: AccountInformation) {
        descriptionField.stringValue = accountInformation.description

        hostnameField.stringValue = ""
        if let value = accountInformation.value(propertyKey: AccountProperty.PropertyKey.Hostname) {
            hostnameField.stringValue = value as! String
        }

        portField.stringValue = ""
        if let value = accountInformation.value(propertyKey: AccountProperty.PropertyKey.PortNumber) {
            portField.stringValue = String(value as! Int64)
        }

        prefixField.stringValue = ""
        if let value = accountInformation.value(propertyKey: AccountProperty.PropertyKey.ServerPath) {
            prefixField.stringValue = value as! String
        }

        allowsInsecureButton.state = NSControl.StateValue.off
        if let value = accountInformation.value(propertyKey: AccountProperty.PropertyKey.AllowsInsecureAuthentication) {
            allowsInsecureButton.state = value as! Bool ? NSControl.StateValue.on : NSControl.StateValue.off
        }

        disableDynamicConfigurationButton.state = NSControl.StateValue.off
        if let value = accountInformation.value(propertyKey: AccountProperty.PropertyKey.DisableDynamicConfiguration) {
            // CAUTION: button state is opposite
            disableDynamicConfigurationButton.state = value as! Bool ? NSControl.StateValue.off : NSControl.StateValue.on
        }
    }

    func updateSaveButtonEnabled(forAccountInformation accountInformation: AccountInformation) {
        saveButton.isEnabled = false
        if accountInformation.isDescriptionUpdated() {
            saveButton.isEnabled = true
        }
        if accountInformation.isAnyPropertyUpdated() {
            saveButton.isEnabled = true
        }
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in _: NSTableView) -> Int {
        return accountInformations?.count ?? 0
    }

    func tableView(_: NSTableView, objectValueFor _: NSTableColumn?, row: Int) -> Any? {
        guard let accountInformations = self.accountInformations else {
            return nil
        }
        return accountInformations[row].description
    }
}

extension ViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_: Notification) {
        if let accountInformation = self.selectedAccountInformation() {
            Log.d("SelectedAccount: \(accountInformation)")
            updatePropertyViews(forAccountInformation: accountInformation)
            updateSaveButtonEnabled(forAccountInformation: accountInformation)
        }
    }
}

extension ViewController: NSTextFieldDelegate {
    override func controlTextDidChange(_ notification: Notification) {
        guard let accountInformation = self.selectedAccountInformation() else {
            return
        }
        if let target = notification.object as? NSTextField {
            switch target {
            case descriptionField:
                let s = descriptionField.stringValue
                accountInformation.update(description: s)
            case hostnameField:
                let s = hostnameField.stringValue
                accountInformation.update(
                    propertyKey: AccountProperty.PropertyKey.Hostname,
                    value: s
                )
            case portField:
                let s = portField.stringValue
                guard let v = Int64(s) else {
                    let alert = NSAlert()
                    alert.alertStyle = .critical
                    alert.messageText =
                        String(format: NSLocalizedString("invalid_value_as_port_number", comment: ""), s)
                    alert.runModal()
                    return
                }
                accountInformation.update(
                    propertyKey: AccountProperty.PropertyKey.PortNumber,
                    value: v
                )
            case prefixField:
                let s = prefixField.stringValue
                accountInformation.update(
                    propertyKey: AccountProperty.PropertyKey.ServerPath,
                    value: s
                )
            default:
                Log.d("Invalid target")
            }
        }
        updateSaveButtonEnabled(forAccountInformation: accountInformation)
    }
}
