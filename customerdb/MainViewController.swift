//
//  MainViewController.swift
//  Copyright © 2019 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit
import UniformTypeIdentifiers
import MessageUI
import Contacts
import StoreKit

class MainViewController : UITabBarController, MFMailComposeViewControllerDelegate, UISearchResultsUpdating, UIDocumentPickerDelegate, RequestFinishedListener {
    
    @IBOutlet weak var buttonSearch: UIBarButtonItem!
    @IBOutlet weak var buttonSync: UIBarButtonItem!
    
    let mDb = CustomerDatabase()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barStyle = .black
        initColor()
        initSearch()
        refreshSyncIcon()
        initLock()
        
        if(UIDevice.current.userInterfaceIdiom == .pad) {
            // iOS automatically displays a search button in iPads
            // so we show our own search icon only on iPhone to match the Android behavior
            if #available(iOS 16.0, *) {
                buttonSearch.isHidden = true
            }
        }
        
        if(!UserDefaults.standard.bool(forKey: "eulaok")) {
            let alert = UIAlertController(
                title: NSLocalizedString("eula_title", comment: ""),
                message: NSLocalizedString("eula", comment: ""),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                    title: NSLocalizedString("ok", comment: ""),
                    style: .cancel) { (action) in
                        UserDefaults.standard.set(true, forKey: "eulaok")
                }
            )
            self.present(alert, animated: true)
        }
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil, completion: {
            _ in
            self.initLock()
        })
        /*if UIDevice.currentDevice.orientation.isLandscape.boolValue {
            print("Landscape")
        }*/
    }
    override func viewDidAppear(_ animated: Bool) {
        initActiveTab()
        
        let startCount = UserDefaults.standard.integer(forKey: "started")
        UserDefaults.standard.set(startCount+1, forKey: "started")
        if #available(iOS 10.3, *) {
            if(startCount == 15) {
                SKStoreReviewController.requestReview()
            }
        }
    }
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        initActiveTab()
    }
    func initActiveTab() {
        if let vc = self.selectedViewController as? CustomerTableViewController {
            vc.mMainViewControllerRef = self
        }
        else if let vc = self.selectedViewController as? VoucherTableViewController {
            vc.mMainViewControllerRef = self
        }
    }
    
    func initColor() {
        if let cvc = selectedViewController as? CustomerTableViewController {
            cvc.initColor()
        } else if let vvc = selectedViewController as? VoucherTableViewController {
            vvc.initColor()
        }
    }
    
    func initLock() {
        if(UserDefaults.standard.bool(forKey: "iom")) {
            guard (navigationController!.topViewController as? InputOnlyModeViewController) != nil else {
                performSegue(withIdentifier: "segueInputOnlyMode", sender: nil)
                return
            }
        } else if(UserDefaults.standard.bool(forKey: "lock")) {
            guard (navigationController!.topViewController as? LockViewController) != nil else {
                performSegue(withIdentifier: "segueLock", sender: nil)
                return
            }
        }
    }
    
    func setUnsyncedChanges() {
        UserDefaults.standard.set(true, forKey: "unsynced-changes")
        refreshSyncIcon()
    }
    func refreshSyncIcon() {
        let apiType = UserDefaults.standard.integer(forKey: "sync-mode")
        if(UserDefaults.standard.bool(forKey: "unsynced-changes")) {
            if(apiType == 1 || apiType == 2) {
                buttonSync.image = UIImage(named: "baseline_sync_problem_black_24pt")
            }
        } else {
            buttonSync.image = UIImage(named: "baseline_autorenew_black_24pt")
        }
    }
    
    // sync implementation
    func queueFinished(success:Bool, message:String?) {
        DispatchQueue.main.async {
            self.mDb.updateCallDirectoryDatabase()
            self.refreshSyncIcon()
            self.reloadData()
            self.setupStatusIndicator(visible: false, message: nil, completion: {
                if(success) {
                    UserDefaults.standard.set(Date(), forKey: "last-successful-sync")
                    self.dialog(
                        title: NSLocalizedString("sync_succeeded", comment: ""),
                        text: message
                    )
                } else {
                    self.dialog(
                        title: NSLocalizedString("sync_failed", comment: ""),
                        text: message
                    )
                }
            })
        }
    }
    func reloadData() {
        if let vc = self.selectedViewController as? CustomerTableViewController {
            vc.reloadCustomers(search: nil, refreshTable: true)
        }
        else if let vc = self.selectedViewController as? VoucherTableViewController {
            vc.reloadVouchers(search: nil, refreshTable: true)
        }
        else if let vc = self.selectedViewController as? AppointmentViewController {
            vc.drawEvents()
        }
    }
    var syncInProgressAlert: UIAlertController? = nil
    func setupStatusIndicator(visible: Bool, message: String?, completion: (()->Void)?) {
        if(visible) {
            syncInProgressAlert = UIAlertController(title: nil, message: message ?? "", preferredStyle: .alert)
            let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
            loadingIndicator.hidesWhenStopped = true
            loadingIndicator.style = UIActivityIndicatorView.Style.gray
            loadingIndicator.startAnimating()
            if #available(iOS 12.0, *) {
                if(traitCollection.userInterfaceStyle == .dark) {
                    loadingIndicator.color = .white
                }
            }
            syncInProgressAlert!.view.addSubview(loadingIndicator)
            present(syncInProgressAlert!, animated: false, completion: nil)
        } else {
            if let alert = syncInProgressAlert {
                DispatchQueue.main.async {
                    alert.dismiss(animated: true, completion: {
                        if(completion != nil) { completion!() }
                    })
                }
            }
        }
    }
    
    // search implementation
    let mSearchController = UISearchController(searchResultsController: nil)
    func initSearch() {
        mSearchController.searchResultsUpdater = self
        mSearchController.obscuresBackgroundDuringPresentation = false
        
        // cancel button tint color
        mSearchController.searchBar.tintColor = .white
        mSearchController.searchBar.barTintColor = navigationController?.navigationBar.barTintColor
        
        if #available(iOS 11.0, *) {
            // get search bar
            if let textFieldInsideSearchBar = mSearchController.searchBar.textField {
                // text field placeholder
                textFieldInsideSearchBar.attributedPlaceholder =
                    NSAttributedString(string: NSLocalizedString("search", comment: ""), attributes: [NSAttributedString.Key.foregroundColor : UIColor.gray])
                // magnifying glass color
                let glassIconView: UIImageView = textFieldInsideSearchBar.leftView as! UIImageView
                glassIconView.image = glassIconView.image?.withRenderingMode(.alwaysTemplate)
                glassIconView.tintColor = .gray
                // text field text & background color
                UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).defaultTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
                textFieldInsideSearchBar.backgroundColor = UIColor.white
                textFieldInsideSearchBar.tintColor = UIColor.black
                // apply search controller
                navigationItem.searchController = mSearchController
            }
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        if let searchString = searchController.searchBar.textField!.text {
            if let vc = self.selectedViewController as? CustomerTableViewController {
                vc.reloadCustomers(search: searchString, refreshTable: true)
            }
            else if let vc = self.selectedViewController as? VoucherTableViewController {
                vc.reloadVouchers(search: searchString, refreshTable: true)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "segueSettings") {
            if let svc = segue.destination as? SettingsViewController {
                svc.mMainViewControllerRef = self
            }
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // button click events
    @IBAction func onClickSync(_ sender: UIBarButtonItem) {
        let defaults = UserDefaults.standard
        let apiType = defaults.integer(forKey: "sync-mode")
        let apiUrl = defaults.string(forKey: "sync-url")
        let apiUsername = defaults.string(forKey: "sync-username")
        let apiPassword = defaults.string(forKey: "sync-password")
        
        var api: CustomerDatabaseApi? = nil
        if(apiType == 1 && apiUsername != nil && apiPassword != nil && apiUsername != "") {
            api = CustomerDatabaseApi(db: mDb, username: apiUsername!, password: apiPassword!)
        } else if(apiType == 2 && apiUrl != nil && apiUsername != nil && apiPassword != nil && apiUrl != "" && apiUsername != "") {
            api = CustomerDatabaseApi(db: mDb, url: apiUrl!, username: apiUsername!, password: apiPassword!)
        } else {
            self.dialog(
                title: NSLocalizedString("sync_not_configured", comment: ""),
                text: NSLocalizedString("please_setup_sync", comment: "")
            )
        }
        if let api2 = api {
            var diffSince = Date(timeIntervalSince1970: 0)
            if let date = UserDefaults.standard.object(forKey: "last-successful-sync") as? Date {
                diffSince = date
            }
            api2.delegate = self
            api2.sync(diffSince: diffSince)
            setupStatusIndicator(visible: true, message: NSLocalizedString("syncing", comment: ""), completion: nil)
        }
    }
    @IBAction func onClickSearch(_ sender: UIBarButtonItem) {
        mSearchController.isActive = true
    }
    @IBAction func onClickMenu(_ sender: UIBarButtonItem) {
        let db = CustomerDatabase()
        let customers = db.getCustomers(search: nil, showDeleted: false, withFiles: false)
        let vouchers = db.getVouchers(showDeleted: false)
        let infoString = String(customers.count) + " " + NSLocalizedString("customers", comment: "")
            + "\n" + String(vouchers.count) + " " + NSLocalizedString("vouchers", comment: "")
        
        var infoString2:String? = NSLocalizedString("backup_note_menu", comment: "")
        let apiType = UserDefaults.standard.integer(forKey: "sync-mode")
        if(apiType == 1 || apiType == 2) {
            infoString2 = nil
        }
        
        let infoAction = UIAlertAction(
            title: NSLocalizedString("information", comment: ""),
            style: .default) { (action) in
                self.performSegue(withIdentifier: "segueInfo", sender: nil)
        }
        infoAction.setValue(UIImage(named:"outline_info_black_24pt"), forKey: "image")
        
        let settingsAction = UIAlertAction(
            title: NSLocalizedString("settings", comment: ""),
            style: .default) { (action) in
                self.performSegue(withIdentifier: "segueSettings", sender: nil)
        }
        settingsAction.setValue(UIImage(named:"baseline_settings_black_24pt"), forKey: "image")
        
        let inputOnlyModeAction = UIAlertAction(
            title: NSLocalizedString("input_only_mode", comment: ""),
            style: .default) { (action) in
                if(UserDefaults.standard.bool(forKey: "unlocked-iom")) {
                    if(UserDefaults.standard.string(forKey: "iom-password") ?? "" == "") {
                        self.dialog(
                            title: nil,
                            text: NSLocalizedString("please_set_password_first", comment: "")
                        )
                    } else {
                        UserDefaults.standard.set(true, forKey: "iom")
                        UserDefaults.standard.synchronize()
                        self.performSegue(withIdentifier: "segueInputOnlyMode", sender: nil)
                        if let msvc = self.splitViewController as? MainSplitViewController {
                            msvc.closeDetailViewController()
                        }
                        if(!UserDefaults.standard.bool(forKey: "input-only-mode-instructions-shown")) {
                            self.dialog(
                                title: NSLocalizedString("input_only_mode", comment: ""),
                                text: NSLocalizedString("input_only_mode_instructions", comment: "")
                            )
                            UserDefaults.standard.set(true, forKey: "input-only-mode-instructions-shown")
                        }
                    }
                } else {
                    self.dialogInApp()
                }
        }
        inputOnlyModeAction.setValue(UIImage(named:"outline_lock_black_24pt"), forKey: "image")
        
        let lockAction = UIAlertAction(
            title: NSLocalizedString("lock_app", comment: ""),
            style: .default) { (action) in
                if(UserDefaults.standard.bool(forKey: "unlocked-iom")) {
                    if(UserDefaults.standard.string(forKey: "iom-password") ?? "" == "") {
                        self.dialog(
                            title: nil,
                            text: NSLocalizedString("please_set_password_first", comment: "")
                        )
                    } else {
                        UserDefaults.standard.set(true, forKey: "lock")
                        UserDefaults.standard.synchronize()
                        self.performSegue(withIdentifier: "segueLock", sender: nil)
                        if let msvc = self.splitViewController as? MainSplitViewController {
                            msvc.closeDetailViewController()
                        }
                    }
                } else {
                    self.dialogInApp()
                }
        }
        lockAction.setValue(UIImage(named:"baseline_lock_black_24pt"), forKey: "image")
        
        let filterAction = UIAlertAction(
            title: NSLocalizedString("filter", comment: ""),
            style: .default) { (action) in
                if let vc = self.selectedViewController as? CustomerTableViewController {
                    vc.filterDialog()
                }
        }
        filterAction.setValue(UIImage(named:"baseline_filter_list_black_24pt"), forKey: "image")
        
        let sortAction = UIAlertAction(
            title: NSLocalizedString("order", comment: ""),
            style: .default) { (action) in
                if let vc = self.selectedViewController as? CustomerTableViewController {
                    vc.sortDialog()
                }
        }
        sortAction.setValue(UIImage(named:"baseline_sort_by_alpha_black_24pt"), forKey: "image")
        
        let newsletterAction = UIAlertAction(
            title: NSLocalizedString("newsletter", comment: ""),
            style: .default) { (action) in
                if(MFMailComposeViewController.canSendMail()) {
                    var recipients:[String] = []
                    for c in self.mDb.getCustomers(search: nil, showDeleted: false, withFiles: false) {
                        if(c.mNewsletter && self.isValidEmail(c.mEmail)) {
                            recipients.append(c.mEmail)
                        }
                    }
                    if(recipients.count == 0) {
                        self.dialog(
                            title: NSLocalizedString("no_newsletter_customers", comment: ""),
                            text: NSLocalizedString("no_newsletter_customers_text", comment: "")
                        )
                        return
                    }
                    let composeVC = MFMailComposeViewController()
                    composeVC.mailComposeDelegate = self
                    composeVC.setBccRecipients(recipients)
                    composeVC.setSubject("Newsletter")
                    composeVC.setMessageBody(UserDefaults.standard.string(forKey: "email-newsletter-template") ?? "", isHTML: false)
                    self.present(composeVC, animated: true, completion: nil)
                } else {
                    self.dialog(
                        title: NSLocalizedString("no_email_account", comment: ""),
                        text: NSLocalizedString("please_set_up_email", comment: "")
                    )
                }
        }
        newsletterAction.setValue(UIImage(named:"baseline_markunread_mailbox_black_24pt"), forKey: "image")
        
        let birthdayAction = UIAlertAction(
            title: NSLocalizedString("birthdays", comment: ""),
            style: .default) { (action) in
                let previewDays = UserDefaults.standard.integer(forKey: "birthday-preview-days")
                let birthdays = CustomerBirthdayTableViewController.getSoonBirthdayCustomers(customers: customers, days: previewDays )
                if(birthdays.count == 0) {
                    self.dialog(
                        title: nil,
                        text: NSLocalizedString("no_birthdays_in_the_next_days", comment: "").replacingOccurrences(of: "%d", with: String(previewDays))
                    )
                    return
                }
                self.performSegue(withIdentifier: "segueBirthday", sender: nil)
        }
        birthdayAction.setValue(UIImage(named:"baseline_cake_black_24pt"), forKey: "image")
        
        let importExportAction = UIAlertAction(
            title: NSLocalizedString("import_export", comment: ""),
            style: .default) { (action) in
                if let _ = self.selectedViewController as? CustomerTableViewController {
                    self.menuImportExportCustomer(sender)
                } else if let _ = self.selectedViewController as? VoucherTableViewController {
                    self.menuImportExportVoucher(sender)
                } else if let _ = self.selectedViewController as? AppointmentViewController {
                    self.menuImportExportAppointments(sender)
                }
        }
        importExportAction.setValue(UIImage(named:"baseline_import_export_black_24pt"), forKey: "image")
        
        let deleteAction = UIAlertAction(
            title: NSLocalizedString("delete_selected", comment: ""),
            style: .destructive) { (action) in
                if let vc = self.selectedViewController as? CustomerTableViewController {
                    vc.tableView.setEditing(!vc.tableView.isEditing, animated: true)
                }
                else if let vc = self.selectedViewController as? VoucherTableViewController {
                    vc.tableView.setEditing(!vc.tableView.isEditing, animated: true)
                }
        }
        deleteAction.setValue(UIImage(named:"baseline_delete_forever_black_24pt"), forKey: "image")
        
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("close", comment: ""),
            style: .cancel) { (action) in
        }
        
        let alert = UIAlertController(
            title: infoString, message: infoString2, preferredStyle: .actionSheet
        )
        alert.addAction(infoAction)
        alert.addAction(settingsAction)
        alert.addAction(inputOnlyModeAction)
        alert.addAction(lockAction)
        alert.addAction(sortAction) // ToDo
        alert.addAction(filterAction)
        alert.addAction(newsletterAction)
        alert.addAction(birthdayAction)
        alert.addAction(importExportAction)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        // On iPad, action sheets must be presented from a popover.
        alert.popoverPresentationController?.barButtonItem = sender
        self.present(alert, animated: true)
    }
    
    func dialog(title:String?, text:String?) {
        let alert = UIAlertController(
            title: title, message: text, preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("ok", comment: ""),
            style: .cancel) { (action) in
        })
        self.present(alert, animated: true, completion: nil)
        return
    }
    func dialogInApp() {
        let alert = UIAlertController(
            title: NSLocalizedString("not_unlocked", comment: ""),
            message: NSLocalizedString("unlock_feature_via_inapp", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("more", comment: ""),
            style: .default) { (action) in
                self.performSegue(withIdentifier: "segueInfo", sender: nil)
        })
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("close", comment: ""),
            style: .cancel) { (action) in
        })
        self.present(alert, animated: true)
    }
    
    func menuImportExportCustomer(_ sender: UIBarButtonItem) {
        let importVcfAction = UIAlertAction(
            title: NSLocalizedString("import_vcf", comment: ""),
            style: .default) { (action) in
                if #available(iOS 11, *) {
                    let documentPicker: UIDocumentPickerViewController
                    if #available(iOS 14.0, *) {
                        documentPicker = CustomerDocumentPickerViewController(forOpeningContentTypes: [UTType.vCard], asCopy: false)
                    } else {
                        documentPicker = CustomerDocumentPickerViewController(documentTypes: ["public.vcard"], in: .import)
                    }
                    documentPicker.delegate = self
                    self.present(documentPicker, animated: true, completion: nil)
                } else {
                    self.dialog(
                        title: NSLocalizedString("not_supported", comment: ""),
                        text: NSLocalizedString("file_selection_not_supported", comment: "")
                    )
                }
        }
        let importCsvAction = UIAlertAction(
            title: NSLocalizedString("import_csv", comment: ""),
            style: .default) { (action) in
                if #available(iOS 11, *) {
                    let alert = UIAlertController(
                        title: "", message: NSLocalizedString("import_csv_note", comment: ""),
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(
                        title: NSLocalizedString("ok", comment: ""),
                        style: .default) { (action) in
                            let documentPicker: UIDocumentPickerViewController
                            if #available(iOS 14.0, *) {
                                documentPicker = CustomerDocumentPickerViewController(forOpeningContentTypes: [UTType.commaSeparatedText], asCopy: false)
                            } else {
                                documentPicker = CustomerDocumentPickerViewController(documentTypes: ["public.comma-separated-values-text"], in: .import)
                            }
                            documentPicker.delegate = self
                            self.present(documentPicker, animated: true, completion: nil)
                    })
                    self.present(alert, animated: true, completion: nil)
                } else {
                    self.dialog(
                        title: NSLocalizedString("not_supported", comment: ""),
                        text: NSLocalizedString("file_selection_not_supported", comment: "")
                    )
                }
        }
        let importCodeAction = UIAlertAction(
            title: NSLocalizedString("import_qr_code", comment: ""),
            style: .default) { (action) in
                self.performSegue(withIdentifier: "segueScanner", sender: nil)
        }
        let exportVcfAction = UIAlertAction(
            title: NSLocalizedString("export_vcf", comment: ""),
            style: .default) { (action) in
                self.exportVcf(barButtonItem: sender)
        }
        let exportCsvAction = UIAlertAction(
            title: NSLocalizedString("export_csv", comment: ""),
            style: .default) { (action) in
                self.exportCsvCustomer(barButtonItem: sender)
        }
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("close", comment: ""),
            style: .cancel) { (action) in
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(importVcfAction)
        alert.addAction(importCsvAction)
        alert.addAction(importCodeAction)
        alert.addAction(exportVcfAction)
        alert.addAction(exportCsvAction)
        alert.addAction(cancelAction)
        
        alert.popoverPresentationController?.barButtonItem = sender
        self.present(alert, animated: true)
    }
    
    func menuImportExportVoucher(_ sender: UIBarButtonItem) {
        let importCsvAction = UIAlertAction(
            title: NSLocalizedString("import_csv", comment: ""),
            style: .default) { (action) in
                if #available(iOS 11, *) {
                    let alert = UIAlertController(
                        title: "", message: NSLocalizedString("import_csv_note_voucher", comment: ""),
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(
                        title: NSLocalizedString("ok", comment: ""),
                        style: .default) { (action) in
                            let documentPicker: UIDocumentPickerViewController
                            if #available(iOS 14.0, *) {
                                documentPicker = VoucherDocumentPickerViewController(forOpeningContentTypes: [UTType.commaSeparatedText], asCopy: false)
                            } else {
                                documentPicker = VoucherDocumentPickerViewController(documentTypes: ["public.comma-separated-values-text"], in: .import)
                            }
                            documentPicker.delegate = self
                            self.present(documentPicker, animated: true, completion: nil)
                    })
                    self.present(alert, animated: true, completion: nil)
                } else {
                    self.dialog(
                        title: NSLocalizedString("not_supported", comment: ""),
                        text: NSLocalizedString("file_selection_not_supported", comment: "")
                    )
                }
        }
        let exportCsvAction = UIAlertAction(
            title: NSLocalizedString("export_csv", comment: ""),
            style: .default) { (action) in
                self.exportCsvVoucher(barButtonItem: sender)
        }
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("close", comment: ""),
            style: .cancel) { (action) in
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(importCsvAction)
        alert.addAction(exportCsvAction)
        alert.addAction(cancelAction)
        
        alert.popoverPresentationController?.barButtonItem = sender
        self.present(alert, animated: true)
    }
    
    func menuImportExportAppointments(_ sender: UIBarButtonItem) {
        let importIcsAction = UIAlertAction(
            title: NSLocalizedString("import_ics", comment: ""),
            style: .default) { (action) in
                if #available(iOS 11, *) {
                    let documentPicker: UIDocumentPickerViewController
                    if #available(iOS 14.0, *) {
                        documentPicker = AppointmentDocumentPickerViewController(forOpeningContentTypes: [UTType.calendarEvent], asCopy: false)
                    } else {
                        documentPicker = AppointmentDocumentPickerViewController(documentTypes: ["public.calendar-event"], in: .import)
                    }
                    documentPicker.delegate = self
                    self.present(documentPicker, animated: true, completion: nil)
                } else {
                    self.dialog(
                        title: NSLocalizedString("not_supported", comment: ""),
                        text: NSLocalizedString("file_selection_not_supported", comment: "")
                    )
                }
        }
        let importCsvAction = UIAlertAction(
            title: NSLocalizedString("import_csv", comment: ""),
            style: .default) { (action) in
                if #available(iOS 11, *) {
                    let documentPicker: UIDocumentPickerViewController
                    if #available(iOS 14.0, *) {
                        documentPicker = AppointmentDocumentPickerViewController(forOpeningContentTypes: [UTType.commaSeparatedText], asCopy: false)
                    } else {
                        documentPicker = AppointmentDocumentPickerViewController(documentTypes: ["public.comma-separated-values-text"], in: .import)
                    }
                    documentPicker.delegate = self
                    self.present(documentPicker, animated: true, completion: nil)
                } else {
                    self.dialog(
                        title: NSLocalizedString("not_supported", comment: ""),
                        text: NSLocalizedString("file_selection_not_supported", comment: "")
                    )
                }
        }
        let exportIcsAction = UIAlertAction(
            title: NSLocalizedString("export_ics", comment: ""),
            style: .default) { (action) in
                self.exportIcs(barButtonItem: sender)
        }
        let exportCsvAction = UIAlertAction(
            title: NSLocalizedString("export_csv", comment: ""),
            style: .default) { (action) in
                self.exportCsvAppointment(barButtonItem: sender)
        }
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("close", comment: ""),
            style: .cancel) { (action) in
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(importIcsAction)
        alert.addAction(importCsvAction)
        alert.addAction(exportIcsAction)
        alert.addAction(exportCsvAction)
        alert.addAction(cancelAction)
        
        alert.popoverPresentationController?.barButtonItem = sender
        self.present(alert, animated: true)
    }
    
    func exportCsvCustomer(barButtonItem:UIBarButtonItem) {
        let csv = CustomerCsvWriter(customers: self.mDb.getCustomers(search: nil, showDeleted: false, withFiles: false), customFields: self.mDb.getCustomFields())
        
        let fileurl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("export.csv")

        do {
            try csv.buildCsvContent().write(to: fileurl, atomically: true, encoding: .utf8)

            let activityController = UIActivityViewController(
                activityItems: [fileurl], applicationActivities: nil
            )
            activityController.popoverPresentationController?.barButtonItem = barButtonItem
            self.present(activityController, animated: true, completion: nil)

        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func exportCsvVoucher(barButtonItem:UIBarButtonItem) {
        let csv = VoucherCsvWriter(vouchers: self.mDb.getVouchers(showDeleted: false))
        
        let fileurl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("export.csv")

        do {
            try csv.buildCsvContent().write(to: fileurl, atomically: true, encoding: .utf8)

            let activityController = UIActivityViewController(
                activityItems: [fileurl], applicationActivities: nil
            )
            activityController.popoverPresentationController?.barButtonItem = barButtonItem
            self.present(activityController, animated: true, completion: nil)

        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func exportCsvAppointment(barButtonItem:UIBarButtonItem) {
        if let calendarSelectionAlert = createCalendarSelectAlert() {
            calendarSelectionAlert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { (action: UIAlertAction!) in
                let csv = CalendarCsvWriter(
                    appointments: self.mDb.getAppointments(
                        calendarId: Int64(self.mCalendars[self.mCalendarPicker!.selectedRow(inComponent: 0)].key),
                        day: nil, showDeleted: false
                    )
                )
                
                let fileurl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("export.csv")

                do {
                    try csv.buildCsvContent().write(to: fileurl, atomically: true, encoding: .utf8)

                    let activityController = UIActivityViewController(
                        activityItems: [fileurl], applicationActivities: nil
                    )
                    activityController.popoverPresentationController?.barButtonItem = barButtonItem
                    self.present(activityController, animated: true, completion: nil)

                } catch let error {
                    print(error.localizedDescription)
                }
            }))
            self.present(calendarSelectionAlert, animated: true)
        }
    }
    
    func exportVcf(barButtonItem:UIBarButtonItem) {
        let vcf = CustomerVcfWriter(customers: self.mDb.getCustomers(search: nil, showDeleted: false, withFiles: true))
        
        let fileurl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("export.vcf")

        do {
            try vcf.buildVcfContent().write(to: fileurl, atomically: true, encoding: .utf8)

            let activityController = UIActivityViewController(
                activityItems: [fileurl], applicationActivities: nil
            )
            activityController.popoverPresentationController?.barButtonItem = barButtonItem
            self.present(activityController, animated: true, completion: nil)

        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    var mCalendarPickerController:PickerDataController? = nil
    var mCalendarPicker:UIPickerView? = nil
    var mCalendars:[KeyValueItem] = []
    func createCalendarSelectAlert() -> UIAlertController? {
        mCalendars = []
        mCalendars.removeAll()
        for c in mDb.getCalendars(showDeleted: false) {
            mCalendars.append(KeyValueItem(String(c.mId), c.mTitle))
        }
        if(mCalendars.count == 0) {
            self.dialog(
                title: nil,
                text: NSLocalizedString("no_calendar_selected", comment: "")
            )
            return nil
        }
        
        let vc = UIViewController()
        vc.preferredContentSize = CGSize(width: 250, height: 300)
        mCalendarPicker = UIPickerView(frame: CGRect(x: 0, y: 0, width: 250, height: 300))
        mCalendarPickerController = PickerDataController(data: mCalendars)
        mCalendarPicker!.dataSource = mCalendarPickerController
        mCalendarPicker!.delegate = mCalendarPickerController
        vc.view.addSubview(mCalendarPicker!)
        let calendarSelectionAlert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        calendarSelectionAlert.setValue(vc, forKey: "contentViewController")
        calendarSelectionAlert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        return calendarSelectionAlert
    }
    
    func exportIcs(barButtonItem:UIBarButtonItem) {
        if let calendarSelectionAlert = createCalendarSelectAlert() {
            calendarSelectionAlert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { (action: UIAlertAction!) in
                let ics = CalendarIcsWriter(
                    appointments: self.mDb.getAppointments(
                        calendarId: Int64(self.mCalendars[self.mCalendarPicker!.selectedRow(inComponent: 0)].key),
                        day: nil, showDeleted: false
                    )
                )
                
                let fileurl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("export.ics")

                do {
                    try ics.buildIcsContent().write(to: fileurl, atomically: true, encoding: .utf8)

                    let activityController = UIActivityViewController(
                        activityItems: [fileurl], applicationActivities: nil
                    )
                    activityController.popoverPresentationController?.barButtonItem = barButtonItem
                    self.present(activityController, animated: true, completion: nil)

                } catch let error {
                    print(error.localizedDescription)
                }
            }))
            self.present(calendarSelectionAlert, animated: true)
        }
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            
            if let _ = controller as? CustomerDocumentPickerViewController {
                
                _ = url.startAccessingSecurityScopedResource()
                if(url.pathExtension.lowercased() == "csv") {
                    do {
                        var inserted = 0
                        let csv: CSV = try CSV(url: url)
                        for row in csv.namedRows {
                            let newCustomer = Customer()
                            for field in row {
                                newCustomer.putAttribute(key: field.key, value: field.value)
                            }
                            if(newCustomer.mTitle != "" || newCustomer.mFirstName != "" || newCustomer.mLastName != "") {
                                if(newCustomer.mId < 0 || mDb.getCustomer(id: newCustomer.mId, showDeleted: true) != nil) {
                                    // generate new ID if exists in db or not set in csv file
                                    newCustomer.mId = Customer.generateID(suffix: inserted)
                                }
                                if(mDb.insertCustomer(c: newCustomer)) {
                                    inserted += 1
                                }
                            }
                        }
                        mDb.updateCallDirectoryDatabase()
                        handleImportSuccess(imported: inserted)
                    } catch let error {
                        handleImportError(message: error.localizedDescription)
                    }
                } else if(url.pathExtension.lowercased() == "vcf") {
                    var inserted = 0
                    for newCustomer in CustomerVcfWriter.readVcfFile(url: url) {
                        if(newCustomer.mTitle != "" || newCustomer.mFirstName != "" || newCustomer.mLastName != "") {
                            // generate new ID because ID is not present in vcf file
                            newCustomer.mId = Customer.generateID(suffix: inserted)
                            if(mDb.insertCustomer(c: newCustomer)) {
                                inserted += 1
                            }
                        }
                    }
                    if(inserted > 0) {
                        mDb.updateCallDirectoryDatabase()
                        handleImportSuccess(imported: inserted)
                    } else {
                        handleImportError(message: NSLocalizedString("file_does_not_contain_valid_records", comment: ""))
                    }
                } else {
                    handleImportError(message: NSLocalizedString("unknown_file_format", comment: ""))
                }
                url.stopAccessingSecurityScopedResource()
                
            } else if let _ = controller as? AppointmentDocumentPickerViewController {
                
                if let calendarSelectionAlert = createCalendarSelectAlert() {
                    calendarSelectionAlert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { (action: UIAlertAction!) in
                        let calendarId = Int64(self.mCalendars[self.mCalendarPicker!.selectedRow(inComponent: 0)].key)
                        
                        // startAccessingSecurityScopedResource must be done inside alert action delegate
                        _ = url.startAccessingSecurityScopedResource()
                        if(url.pathExtension.lowercased() == "csv") {
                            do {
                                var inserted = 0
                                let csv: CSV = try CSV(url: url)
                                for row in csv.namedRows {
                                    let newAppointment = CustomerAppointment()
                                    newAppointment.mCalendarId = calendarId!
                                    for field in row {
                                        newAppointment.putAttribute(key: field.key, value: field.value)
                                    }
                                    if(newAppointment.mTitle != "" && newAppointment.mTimeStart != nil && newAppointment.mTimeEnd != nil) {
                                        if(newAppointment.mId < 0 || self.mDb.getAppointment(id: newAppointment.mId, showDeleted: true) != nil) {
                                            // generate new ID if exists in db or not set in csv file
                                            newAppointment.mId = CustomerAppointment.generateID(suffix: inserted)
                                        }
                                        if(self.mDb.insertAppointment(a: newAppointment)) {
                                            inserted += 1
                                        }
                                    }
                                }
                                self.handleImportSuccess(imported: inserted)
                            } catch let error {
                                self.handleImportError(message: error.localizedDescription)
                            }
                        } else if(url.pathExtension.lowercased() == "ics") {
                            var inserted = 0
                            for newAppointment in CalendarIcsWriter.readIcsFile(url: url) {
                                if(newAppointment.mTitle != "" && newAppointment.mTimeStart != nil && newAppointment.mTimeEnd != nil) {
                                    // generate new ID because ID is not present in ics file
                                    newAppointment.mId = CustomerAppointment.generateID(suffix: inserted)
                                    newAppointment.mCalendarId = calendarId!
                                    if(self.mDb.insertAppointment(a: newAppointment)) {
                                        inserted += 1
                                    }
                                }
                            }
                            if(inserted > 0) {
                                self.handleImportSuccess(imported: inserted)
                            } else {
                                self.handleImportError(message: NSLocalizedString("file_does_not_contain_valid_records", comment: ""))
                            }
                        } else {
                            self.handleImportError(message: NSLocalizedString("unknown_file_format", comment: ""))
                        }
                        url.stopAccessingSecurityScopedResource()
                    }))
                    self.present(calendarSelectionAlert, animated: true)
                }
                
            } else if let _ = controller as? VoucherDocumentPickerViewController {
                
                _ = url.startAccessingSecurityScopedResource()
                if(url.pathExtension.lowercased() == "csv") {
                    do {
                        var inserted = 0
                        let csv: CSV = try CSV(url: url)
                        for row in csv.namedRows {
                            let newVoucher = Voucher()
                            for field in row {
                                newVoucher.putAttribute(key: field.key, value: field.value)
                            }
                            if(newVoucher.mId < 0 || mDb.getVoucher(id: newVoucher.mId, showDeleted: true) != nil) {
                                // generate new ID if exists in db or not set in csv file
                                newVoucher.mId = Voucher.generateID(suffix: inserted)
                            }
                            if(mDb.insertVoucher(v: newVoucher)) {
                                inserted += 1
                            }
                        }
                        handleImportSuccess(imported: inserted)
                    } catch let error {
                        handleImportError(message: error.localizedDescription)
                    }
                } else {
                    handleImportError(message: NSLocalizedString("unknown_file_format", comment: ""))
                }
                url.stopAccessingSecurityScopedResource()
                
            }
            
        }
        
        DispatchQueue.main.async {
            self.reloadData()
        }
    }
    
    func handleImportError(message:String) {
        self.dialog(
            title: NSLocalizedString("import_failed", comment: ""),
            text: message
        )
    }
    func handleImportSuccess(imported:Int) {
        self.dialog(
            title: NSLocalizedString("import_succeeded", comment: ""),
            text: NSLocalizedString("imported_records", comment: "") + " " + String(imported)
        )
    }
    
}
