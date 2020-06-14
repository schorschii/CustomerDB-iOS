//
//  InputOnlyModeViewController.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class InputOnlyModeViewController : UIViewController {
    
    @IBOutlet weak var imageViewLogo: UIImageView!
    
    override func viewDidLoad() {
        navigationItem.hidesBackButton = true
        view.backgroundColor = navigationController?.navigationBar.barTintColor
        
        if(UserDefaults.standard.bool(forKey: "unlocked-do")) {
            if let image = load(file: SettingsViewController.getLogoFile()) {
                imageViewLogo.contentMode = .scaleAspectFit
                imageViewLogo.image = image
            }
        }
    }
    
    private func load(file: URL) -> UIImage? {
        do {
            let imageData = try Data(contentsOf: file)
            return UIImage(data: imageData)
        } catch {
            print("Error loading image : \(error)")
        }
        return nil
    }
    
    @IBAction func onClickUnlock(_ sender: UIButton) {
        let alert = UIAlertController(
            title: NSLocalizedString("unlock", comment: ""),
            message: NSLocalizedString("please_enter_password_to_exit", comment: ""),
            preferredStyle: .alert
        )
        alert.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("password", comment: "")
            textField.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            if(textField?.text == UserDefaults.standard.string(forKey: "iom-password") ?? "") {
                UserDefaults.standard.set(false, forKey: "iom")
                self.navigationController?.popViewController(animated: true)
            } else {
                let alert = UIAlertController(
                    title: NSLocalizedString("incorrect_password", comment: ""),
                    message: nil,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onClickregister(_ sender: UIButton) {
        let detailViewController = storyboard?.instantiateViewController(withIdentifier: "CustomerEditNavigationViewController")
        splitViewController?.showDetailViewController(detailViewController!, sender: nil)
    }
    
}
