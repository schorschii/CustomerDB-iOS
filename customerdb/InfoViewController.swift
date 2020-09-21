//
//  InfoViewController.swift
//  Copyright © 2019 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit
import MessageUI
import StoreKit

class InfoViewController : UIViewController, MFMailComposeViewControllerDelegate, SKProductsRequestDelegate, SKPaymentTransactionObserver, SKStoreProductViewControllerDelegate {
    
    @IBOutlet weak var labelVersion: UILabel!
    
    static let activateURL = "https://apps.georg-sieber.de/activate/app.php"
    
    static let homepageURL = "https://georg-sieber.de/"
    static let supportEmail = "support@georg-sieber.de"
    
    static let inappCloudAccessLicenseId = "systems.sieber.customerdb.cal"
    static let inappCommercialUsageId = "systems.sieber.customerdb.cu"
    static let inappLargeCompanyId = "systems.sieber.customerdb.lc"
    static let inappInputOnlyModeId = "systems.sieber.customerdb.iom"
    static let inappDesignOptionsId = "systems.sieber.customerdb.do"
    static let inappCustomFieldsId = "systems.sieber.customerdb.cf"
    static let inappFilesId = "systems.sieber.customerdb.fs"
    static let inappCalendarId = "systems.sieber.customerdb.cl"
    private var inappCloudAccessLicenseProduct: SKProduct?
    private var inappCommercialUsageProduct: SKProduct?
    private var inappCustomFieldsProduct: SKProduct?
    private var inappInputOnlyModeProduct: SKProduct?
    private var inappDesignOptionsProduct: SKProduct?
    private var inappLargeCompanyProduct: SKProduct?
    private var inappFilesProduct: SKProduct?
    private var inappCalendarProduct: SKProduct?
    
    @IBOutlet weak var imageLogo: UIImageView!
    @IBOutlet weak var buttonBuyCloudAccessLicense: UIButton!
    @IBOutlet weak var buttonBuyCommercialUsage: UIButton!
    @IBOutlet weak var buttonBuyLargeCompany: UIButton!
    @IBOutlet weak var buttonBuyInputOnlyMode: UIButton!
    @IBOutlet weak var buttonBuyDesignOptions: UIButton!
    @IBOutlet weak var buttonBuyCustomFields: UIButton!
    @IBOutlet weak var buttonBuyFiles: UIButton!
    @IBOutlet weak var buttonBuyCalendar: UIButton!
    @IBOutlet weak var buttonRestore: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initIAP()
        let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        labelVersion.text = "v" + (versionString ?? "?")
        navigationController?.navigationBar.barStyle = .black
        
        let singleTap = UILongPressGestureRecognizer(target: self, action: #selector(onClickManualUnlock(_:)))
        imageLogo.isUserInteractionEnabled = true
        imageLogo.addGestureRecognizer(singleTap)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if let svc = presentingViewController as? MainSplitViewController {
            if let mnvc = svc.viewControllers[0] as? MasterNavigationController {
                if let mvc = mnvc.viewControllers.first as? MainViewController {
                    if let ctvc = mvc.viewControllers?.first as? CustomerTableViewController {
                        ctvc.initCommercialUsageNote()
                    }
                }
            }
        }
    }
    
    @IBAction func onClickDone(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func onClickWebsite(_ sender: UIButton) {
        if let url = URL(string: InfoViewController.homepageURL) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    @IBAction func onClickEmail(_ sender: UIButton) {
        if(MFMailComposeViewController.canSendMail()) {
            let composeVC = MFMailComposeViewController()
            composeVC.mailComposeDelegate = self
            composeVC.setToRecipients([InfoViewController.supportEmail])
            composeVC.setSubject(NSLocalizedString("feedback_title", comment: ""))
            composeVC.setMessageBody("", isHTML: false)
            self.present(composeVC, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(
                title: NSLocalizedString("no_email_account", comment: ""),
                message: NSLocalizedString("please_set_up_email", comment: ""),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("ok", comment: ""),
                style: .cancel) { (action) in
            })
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let langCode = Locale.current.languageCode
        if(langCode != "de" && langCode != "en") {
            let alert = UIAlertController(
                title: nil,
                message: NSLocalizedString("only_german_and_english_messages", comment: ""),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("cancel", comment: ""),
                style: .cancel) { (action) in
            })
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("ok", comment: ""),
                style: .default) { (action) in
            })
            self.present(alert, animated: true, completion: nil)
        }
    }
    @IBAction func onClickCustomerDatbaseAndroid(_ sender: UIButton) {
        if let url = URL(string: "https://play.google.com/store/apps/details?id=de.georgsieber.customerdb") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    @IBAction func onClickBallBreakIos(_ sender: UIButton) {
        openStoreProductWithiTunesItemIdentifier(identifier: "1409746305");
    }
    func openStoreProductWithiTunesItemIdentifier(identifier: String) {
        let storeViewController = SKStoreProductViewController()
        storeViewController.delegate = self

        let parameters = [ SKStoreProductParameterITunesItemIdentifier : identifier]
        storeViewController.loadProduct(withParameters: parameters) { [weak self] (loaded, error) -> Void in
            if loaded {
                // Parent class of self is UIViewContorller
                self?.present(storeViewController, animated: true, completion: nil)
            }
        }
    }
    func productViewControllerDidFinish(_ viewController: SKStoreProductViewController) {
        //dismiss(animated: true, completion: nil)
    }
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func initIAP() {
        SKPaymentQueue.default().add(self)

        var productIdentifiers:[String] = [InfoViewController.inappCloudAccessLicenseId]

        let unlockedCommercialUsage = UserDefaults.standard.bool(forKey: "unlocked-cu")
        let unlockedLargeCompany = UserDefaults.standard.bool(forKey: "unlocked-lc")
        let unlockedInputOnlyMode = UserDefaults.standard.bool(forKey: "unlocked-iom")
        let unlockedDesignOptions = UserDefaults.standard.bool(forKey: "unlocked-do")
        let unlockedCustomFields = UserDefaults.standard.bool(forKey: "unlocked-cf")
        let unlockedFiles = UserDefaults.standard.bool(forKey: "unlocked-fs")
        let unlockedCalendar = UserDefaults.standard.bool(forKey: "unlocked-cl")
        if(unlockedCommercialUsage) {
            buttonBuyCommercialUsage.setTitle(NSLocalizedString("purchased", comment: ""), for: UIControl.State.normal)
        } else {
            productIdentifiers.append(InfoViewController.inappCommercialUsageId)
        }
        if(unlockedLargeCompany) {
            buttonBuyLargeCompany.setTitle(NSLocalizedString("purchased", comment: ""), for: UIControl.State.normal)
        } else {
            productIdentifiers.append(InfoViewController.inappLargeCompanyId)
        }
        if(unlockedInputOnlyMode) {
            buttonBuyInputOnlyMode.setTitle(NSLocalizedString("purchased", comment: ""), for: UIControl.State.normal)
        } else {
            productIdentifiers.append(InfoViewController.inappInputOnlyModeId)
        }
        if(unlockedDesignOptions) {
            buttonBuyDesignOptions.setTitle(NSLocalizedString("purchased", comment: ""), for: UIControl.State.normal)
        } else {
            productIdentifiers.append(InfoViewController.inappDesignOptionsId)
        }
        if(unlockedCustomFields) {
            buttonBuyCustomFields.setTitle(NSLocalizedString("purchased", comment: ""), for: UIControl.State.normal)
        } else {
            productIdentifiers.append(InfoViewController.inappCustomFieldsId)
        }
        if(unlockedFiles) {
            buttonBuyFiles.setTitle(NSLocalizedString("purchased", comment: ""), for: UIControl.State.normal)
        } else {
            productIdentifiers.append(InfoViewController.inappFilesId)
        }
        if(unlockedCalendar) {
            buttonBuyCalendar.setTitle(NSLocalizedString("purchased", comment: ""), for: UIControl.State.normal)
        } else {
            productIdentifiers.append(InfoViewController.inappCalendarId)
        }
        
        let IAPrequest = SKProductsRequest(productIdentifiers: Set(productIdentifiers))
        IAPrequest.delegate = self
        IAPrequest.start()
    }
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        for iap in response.products {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .currency
            numberFormatter.locale = iap.priceLocale
            print("found IAP: "+iap.productIdentifier)
            
            if(iap.productIdentifier == InfoViewController.inappCloudAccessLicenseId) {
                DispatchQueue.main.async {
                    self.buttonBuyCloudAccessLicense.titleLabel?.textAlignment = .center
                    self.buttonBuyCloudAccessLicense.setTitle(
                        numberFormatter.string(from: iap.price)! + "\n" + NSLocalizedString("buy", comment: ""),
                        for: UIControl.State.normal
                    )
                    self.buttonBuyCloudAccessLicense.isEnabled = true
                    self.buttonRestore.isEnabled = true
                }
                inappCloudAccessLicenseProduct = iap
            }
            else if(iap.productIdentifier == InfoViewController.inappCommercialUsageId) {
                DispatchQueue.main.async {
                    self.buttonBuyCommercialUsage.titleLabel?.textAlignment = .center
                    self.buttonBuyCommercialUsage.setTitle(
                        numberFormatter.string(from: iap.price)! + "\n" + NSLocalizedString("buy", comment: ""),
                        for: UIControl.State.normal
                    )
                    self.buttonBuyCommercialUsage.isEnabled = true
                    self.buttonRestore.isEnabled = true
                }
                inappCommercialUsageProduct = iap
            }
            else if(iap.productIdentifier == InfoViewController.inappLargeCompanyId) {
                DispatchQueue.main.async {
                    self.buttonBuyLargeCompany.titleLabel?.textAlignment = .center
                    self.buttonBuyLargeCompany.setTitle(
                        numberFormatter.string(from: iap.price)! + "\n" + NSLocalizedString("buy", comment: ""),
                        for: UIControl.State.normal
                    )
                    self.buttonBuyLargeCompany.isEnabled = true
                    self.buttonRestore.isEnabled = true
                }
                inappLargeCompanyProduct = iap
            }
            else if(iap.productIdentifier == InfoViewController.inappInputOnlyModeId) {
                DispatchQueue.main.async {
                    self.buttonBuyInputOnlyMode.titleLabel?.textAlignment = .center
                    self.buttonBuyInputOnlyMode.setTitle(
                        numberFormatter.string(from: iap.price)! + "\n" + NSLocalizedString("buy", comment: ""),
                        for: UIControl.State.normal
                    )
                    self.buttonBuyInputOnlyMode.isEnabled = true
                    self.buttonRestore.isEnabled = true
                }
                inappInputOnlyModeProduct = iap
            }
            else if(iap.productIdentifier == InfoViewController.inappDesignOptionsId) {
                DispatchQueue.main.async {
                    self.buttonBuyDesignOptions.titleLabel?.textAlignment = .center
                    self.buttonBuyDesignOptions.setTitle(
                        numberFormatter.string(from: iap.price)! + "\n" + NSLocalizedString("buy", comment: ""),
                        for: UIControl.State.normal
                    )
                    self.buttonBuyDesignOptions.isEnabled = true
                    self.buttonRestore.isEnabled = true
                }
                inappDesignOptionsProduct = iap
            }
            else if(iap.productIdentifier == InfoViewController.inappCustomFieldsId) {
                DispatchQueue.main.async {
                    self.buttonBuyCustomFields.titleLabel?.textAlignment = .center
                    self.buttonBuyCustomFields.setTitle(
                        numberFormatter.string(from: iap.price)! + "\n" + NSLocalizedString("buy", comment: ""),
                        for: UIControl.State.normal
                    )
                    self.buttonBuyCustomFields.isEnabled = true
                    self.buttonRestore.isEnabled = true
                }
                inappCustomFieldsProduct = iap
            }
            else if(iap.productIdentifier == InfoViewController.inappFilesId) {
                DispatchQueue.main.async {
                    self.buttonBuyFiles.titleLabel?.textAlignment = .center
                    self.buttonBuyFiles.setTitle(
                        numberFormatter.string(from: iap.price)! + "\n" + NSLocalizedString("buy", comment: ""),
                        for: UIControl.State.normal
                    )
                    self.buttonBuyFiles.isEnabled = true
                    self.buttonRestore.isEnabled = true
                }
                inappFilesProduct = iap
            }
            else if(iap.productIdentifier == InfoViewController.inappCalendarId) {
                DispatchQueue.main.async {
                    self.buttonBuyCalendar.titleLabel?.textAlignment = .center
                    self.buttonBuyCalendar.setTitle(
                        numberFormatter.string(from: iap.price)! + "\n" + NSLocalizedString("buy", comment: ""),
                        for: UIControl.State.normal
                    )
                    self.buttonBuyCalendar.isEnabled = true
                    self.buttonRestore.isEnabled = true
                }
                inappCalendarProduct = iap
            }
        }
    }
    func request(_ request: SKRequest, didFailWithError error: Error) {
        handleError(text: (error.localizedDescription))
    }
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for tx in transactions {
            switch (tx.transactionState) {
            
            case .purchased:
                unlock(productId: tx.payment.productIdentifier)
                queue.finishTransaction(tx)
                
            case .restored:
                if(tx.original != nil) {
                    unlock(productId: tx.original!.payment.productIdentifier)
                }
                queue.finishTransaction(tx)
                
            case .failed:
                handleError(text: (tx.error?.localizedDescription)!)
                queue.finishTransaction(tx)
                
            case .purchasing: break   // do nothing
            case .deferred:   break   // do nothing
            @unknown default: break
            
            }
        }
    }
    func unlock(productId: String) {
        switch(productId) {
            case InfoViewController.inappCloudAccessLicenseId:
                UserDefaults.standard.set(true, forKey: "unlocked-cal")
                handleSuccess()
                break
            case InfoViewController.inappCommercialUsageId:
                UserDefaults.standard.set(true, forKey: "unlocked-cu")
                handleSuccess()
                break
            case InfoViewController.inappLargeCompanyId:
                UserDefaults.standard.set(true, forKey: "unlocked-lc")
                handleSuccess()
                break
            case InfoViewController.inappInputOnlyModeId:
                UserDefaults.standard.set(true, forKey: "unlocked-iom")
                handleSuccess()
                break
            case InfoViewController.inappDesignOptionsId:
                UserDefaults.standard.set(true, forKey: "unlocked-do")
                handleSuccess()
                break
            case InfoViewController.inappCustomFieldsId:
                UserDefaults.standard.set(true, forKey: "unlocked-cf")
                handleSuccess()
                break
            case InfoViewController.inappFilesId:
                UserDefaults.standard.set(true, forKey: "unlocked-fs")
                handleSuccess()
                break
            case InfoViewController.inappCalendarId:
                UserDefaults.standard.set(true, forKey: "unlocked-cl")
                handleSuccess()
                break
            default:
                print("UNKNOWN: "+productId)
        }
    }
    
    @objc func onClickManualUnlock(_ sender: UIButton) {
        let alert = UIAlertController(title: NSLocalizedString("manual_unlock", comment: ""), message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: NSLocalizedString("commercial_usage", comment: ""), style: .default, handler: { (_) in
            self.openUnlockInputBox(productId: InfoViewController.inappCommercialUsageId)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("more_than_500_customers", comment: ""), style: .default, handler: { (_) in
            self.openUnlockInputBox(productId: InfoViewController.inappLargeCompanyId)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("input_only_mode", comment: ""), style: .default, handler: { (_) in
            self.openUnlockInputBox(productId: InfoViewController.inappInputOnlyModeId)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("design_options", comment: ""), style: .default, handler: { (_) in
            self.openUnlockInputBox(productId: InfoViewController.inappDesignOptionsId)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("custom_fields", comment: ""), style: .default, handler: { (_) in
            self.openUnlockInputBox(productId: InfoViewController.inappCustomFieldsId)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("files", comment: ""), style: .default, handler: { (_) in
            self.openUnlockInputBox(productId: InfoViewController.inappFilesId)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("calendar", comment: ""), style: .default, handler: { (_) in
            self.openUnlockInputBox(productId: InfoViewController.inappCalendarId)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        alert.popoverPresentationController?.sourceView = sender
        self.present(alert, animated: true, completion: nil)
    }
    @IBAction func onClickBuyCloudAccessLicense(_ sender: UIButton) {
        if(inappCloudAccessLicenseProduct != nil) {
            let payment = SKPayment(product: inappCloudAccessLicenseProduct!)
            SKPaymentQueue.default().add(payment)
            buttonBuyCloudAccessLicense.isEnabled = false
        }
    }
    @IBAction func onClickBuyCommercialUsage(_ sender: UIButton) {
        if(inappCommercialUsageProduct != nil) {
            let payment = SKPayment(product: inappCommercialUsageProduct!)
            SKPaymentQueue.default().add(payment)
            buttonBuyCommercialUsage.isEnabled = false
        }
    }
    @IBAction func onClickBuyLargeCompany(_ sender: UIButton) {
        if(inappLargeCompanyProduct != nil) {
            let payment = SKPayment(product: inappLargeCompanyProduct!)
            SKPaymentQueue.default().add(payment)
            buttonBuyLargeCompany.isEnabled = false
        }
    }
    @IBAction func onClickBuyInputOnlyMode(_ sender: UIButton) {
        if(inappInputOnlyModeProduct != nil) {
            let payment = SKPayment(product: inappInputOnlyModeProduct!)
            SKPaymentQueue.default().add(payment)
            buttonBuyInputOnlyMode.isEnabled = false
        }
    }
    @IBAction func onClickBuyDesignOptions(_ sender: UIButton) {
        if(inappDesignOptionsProduct != nil) {
            let payment = SKPayment(product: inappDesignOptionsProduct!)
            SKPaymentQueue.default().add(payment)
            buttonBuyDesignOptions.isEnabled = false
        }
    }
    @IBAction func onClickBuyCustomFields(_ sender: UIButton) {
        if(inappCustomFieldsProduct != nil) {
            let payment = SKPayment(product: inappCustomFieldsProduct!)
            SKPaymentQueue.default().add(payment)
            buttonBuyCustomFields.isEnabled = false
        }
    }
    @IBAction func onClickBuyFiles(_ sender: UIButton) {
        if(inappFilesProduct != nil) {
            let payment = SKPayment(product: inappFilesProduct!)
            SKPaymentQueue.default().add(payment)
            buttonBuyFiles.isEnabled = false
        }
    }
    @IBAction func onClickBuyCalendar(_ sender: UIButton) {
        if(inappCalendarProduct != nil) {
            let payment = SKPayment(product: inappCalendarProduct!)
            SKPaymentQueue.default().add(payment)
            buttonBuyCalendar.isEnabled = false
        }
    }
    @IBAction func onClickRestore(_ sender: UIButton) {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func openUnlockInputBox(productId: String) {
        let alert = UIAlertController(
            title: NSLocalizedString("unlock_code", comment: ""),
            message: "",
            preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = ""
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .destructive, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { [weak alert] (_) in
            let text = alert?.textFields![0].text
            let url = URL(string: InfoViewController.activateURL)!
            let session = URLSession.shared
            var request = URLRequest(url: url, cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalCacheData, timeoutInterval: 5.0)
            request.httpMethod = "POST"
            request.addValue(productId, forHTTPHeaderField: "X-Unlock-Feature")
            request.addValue(text!, forHTTPHeaderField: "X-Unlock-Code")
            let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
                guard error == nil else { return }
                if let httpResponse = response as? HTTPURLResponse {
                    //print(String(httpResponse.statusCode))
                    //print(String(data: data!, encoding: String.Encoding.utf8))
                    if(httpResponse.statusCode == 999) {
                        DispatchQueue.main.async {
                            self.unlock(productId: productId)
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.handleError(text: NSLocalizedString("invalid_unlock_code", comment: ""))
                        }
                    }
                }
            })
            task.resume()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func handleError(text: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: NSLocalizedString("error", comment: ""), message: text, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    func handleSuccess() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: NSLocalizedString("success", comment: ""),
                message: NSLocalizedString("feature_now_available", comment: ""),
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { (_) in self.dismiss(animated: true, completion: nil)}))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
}
