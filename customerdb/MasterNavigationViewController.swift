//
//  NavigationViewController.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class MasterNavigationController: UINavigationController {
    
    override func viewDidLoad() {
        initColor()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
          return .lightContent
    }
    
    func initColor() {
        let defaults = UserDefaults.standard
        let accentColor = UIColor.init(
            red: CGFloat(Float(defaults.integer(forKey: "color-red"))/255),
            green: CGFloat(Float(defaults.integer(forKey: "color-green"))/255),
            blue: CGFloat(Float(defaults.integer(forKey: "color-blue"))/255),
            alpha: 1
        )
        setNavigationBarColor(accentColor)
    }
    
    func setNavigationBarColor(_ color:UIColor) {
        navigationBar.barTintColor = color
        navigationBar.tintColor = .white
        
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().barTintColor = color
        
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.backgroundColor = color
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            
            navigationBar.standardAppearance = appearance
            navigationBar.compactAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        } else {
            navigationBar.isTranslucent = false
            
            UINavigationBar.appearance().isTranslucent = false
        }
        
        if let mvc = viewControllers[0] as? MainViewController {
            mvc.tabBar.tintColor = color
            if let cvc = mvc.selectedViewController as? CustomerTableViewController {
                cvc.initColor()
            } else if let vvc = mvc.selectedViewController as? VoucherTableViewController {
                vvc.initColor()
            }
        }
    }
    
}
