//
//  CreateAccountViewController.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class CreateAccountViewController : UIViewController {
    
    @IBOutlet weak var textFieldEmail: UITextField!
    @IBOutlet weak var textFieldPassword: UITextField!
    @IBOutlet weak var textFieldPasswordConfirm: UITextField!
    @IBOutlet weak var buttonRegister: UIButton!
    @IBOutlet weak var switchPolicy: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barStyle = .black
    }
    
    @IBAction func onClickDone(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onClickPolicy(_ sender: UIButton) {
        if let url = URL(string: "https://georg-sieber.de/?page=app-customerdb-terms") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func onClickRegister(_ sender: UIButton) {
        if(!switchPolicy.isOn) {
            handleError(message: NSLocalizedString("please_accept_privacy_policy", comment: ""))
            return
        }
        
        if(textFieldPassword.text! != textFieldPasswordConfirm.text!) {
            handleError(message: NSLocalizedString("passwords_do_not_match", comment: ""))
            return
        }
        
        let json: [String:Any?] = [
            "jsonrpc":"2.0",
            "id":1,
            "method":"account.register",
            "params":[
                "email": textFieldEmail.text!,
                "password": textFieldPassword.text!
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

        buttonRegister.isEnabled = false
        buttonRegister.setTitle(NSLocalizedString("please_wait", comment: ""), for: .normal)
        task.resume()
    }
    
    func handleSuccess() {
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("ok", comment: ""),
            style: .cancel) { (action) in
                DispatchQueue.main.async {
                    // apply username and password in settings
                    let defaults = UserDefaults.standard
                    defaults.set(1, forKey: "sync-mode")
                    defaults.set(self.textFieldEmail.text!, forKey: "sync-username")
                    defaults.set(self.textFieldPassword.text!, forKey: "sync-password")
                    // refresh settings controller to display the new entered credentials
                    if let pvc = self.presentingViewController as? SyncInfoViewController {
                        pvc.refreshSyncSettings()
                    }
                    // close registration view controller
                    self.dismiss(animated: true, completion: nil)
                }
        }
        let alert = UIAlertController(
            title: NSLocalizedString("registration_succeeded", comment: ""),
            message: NSLocalizedString("registration_succeeded_text", comment: ""),
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
                DispatchQueue.main.async {
                    self.buttonRegister.isEnabled = true
                    self.buttonRegister.setTitle(NSLocalizedString("register_now", comment: ""), for: .normal)
                }
        }
        let alert = UIAlertController(title: NSLocalizedString("registration_failed", comment: ""), message: message, preferredStyle: .alert)
        alert.addAction(cancelAction)
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }
    
}
