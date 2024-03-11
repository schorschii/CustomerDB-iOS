//
//  SyncInfoViewController.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class SyncInfoViewController : UIViewController {
    
    @IBOutlet weak var buttonFaq: UIButton!
    @IBOutlet weak var buttonGithub: UIButton!
    
    static let HELP_URL = "https://georg-sieber.de/?page=app-customerdb"
    static let REPO_URL = "https://github.com/schorschii/CustomerDB-Server"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buttonGithub.setTitle(SyncInfoViewController.REPO_URL, for: .normal)
        navigationController?.navigationBar.barStyle = .black
        
        buttonFaq.titleLabel?.lineBreakMode = .byWordWrapping
        buttonFaq.titleLabel?.textAlignment = .center
    }
    
    func refreshSyncSettings() {
        if let pvc = self.presentingViewController as? SettingsViewController {
            pvc.loadSettings()
        }
    }
    
    @IBAction func onClickDone(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onClickFaq(_ sender: UIButton) {
        if let url = URL(string: SyncInfoViewController.HELP_URL) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func onClickResetPassword(_ sender: UIButton) {
        let alert = UIAlertController(
            title: NSLocalizedString("reset_password", comment: ""),
            message: nil,
            preferredStyle: .alert
        )
        alert.addTextField { (textField) in
            textField.keyboardType = .emailAddress
            textField.placeholder = NSLocalizedString("email_address", comment: "")
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { [weak alert] (_) in
            self.accountRequest(method: "account.resetpwd", email: alert!.textFields![0].text!)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onClickDeleteAccount(_ sender: UIButton) {
        let alert = UIAlertController(
            title: NSLocalizedString("delete_account", comment: ""),
            message: nil,
            preferredStyle: .alert
        )
        alert.addTextField { (textField) in
            textField.keyboardType = .emailAddress
            textField.placeholder = NSLocalizedString("email_address", comment: "")
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { [weak alert] (_) in
            self.accountRequest(method: "account.delete", email: alert!.textFields![0].text!)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onClickServerGithub(_ sender: UIButton) {
        if let url = URL(string: SyncInfoViewController.REPO_URL) {
            UIApplication.shared.open(url)
        }
    }
    
    func accountRequest(method:String, email:String) {
        let json: [String:Any?] = [
            "jsonrpc":"2.0", "id":1,
            "method":method,
            "params":[
                "email": email
            ] as [String:Any?]
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        let defaults = UserDefaults.standard
        let apiType = defaults.integer(forKey: "sync-mode")
        let apiUrl = defaults.string(forKey: "sync-url")
        
        var url:URL? = nil
        if(apiType == 2 && apiUrl != nil && apiUrl != "") {
            url = URL(string: apiUrl!)
        }
        if(url == nil) {
            // fallback/default to MANAGED_API
            url = URL(string: CustomerDatabaseApi.MANAGED_API)
        }
        
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                self.handleError(message: error?.localizedDescription ?? "")
                return
            }
            //print(String(decoding:data, as: UTF8.self))
            
            do {
                if let response = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] {
                    if let result = response["result"] as? Bool, result == true {
                        self.handleSuccess()
                        return
                    } else {
                        if let message = response["error"] as? String {
                            self.handleError(message: message)
                            return
                        }
                    }
                }
            } catch {}
            
            self.handleError(message: String(data:data, encoding: .utf8)!)
        }
        
        task.resume()
    }
    
    func handleSuccess() {
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("ok", comment: ""),
            style: .cancel) { (action) in
        }
        let alert = UIAlertController(
            title: NSLocalizedString("success", comment: ""),
            message: NSLocalizedString("please_check_inbox", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(cancelAction)
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
    func handleError(message:String) {
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("ok", comment: ""),
            style: .cancel) { (action) in
        }
        let alert = UIAlertController(title: NSLocalizedString("error", comment: ""), message: message, preferredStyle: .alert)
        alert.addAction(cancelAction)
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
}
