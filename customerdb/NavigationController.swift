//
//  NavigationController.swift
//  customerdb
//
//  Created by Georg on 13.05.20.
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class NavigationController: UINavigationController {
    
    override func viewDidLoad() {
        setNavigationBarColor(UIApplication.shared.windows[0].tintColor)
    }
    
    func setNavigationBarColor(_ color:UIColor) {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            if #unavailable(iOS 26.0) {
                navigationBar.barTintColor = color
                navigationBar.tintColor = .white
                
                UINavigationBar.appearance().tintColor = .white
                UINavigationBar.appearance().barTintColor = color
                
                appearance.backgroundColor = color
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            }
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
            if #available(iOS 26.0, *) {
            } else {
                mvc.tabBar.tintColor = color
            }
            if let cvc = mvc.selectedViewController as? CustomerTableViewController {
                cvc.initColor()
            } else if let vvc = mvc.selectedViewController as? VoucherTableViewController {
                vvc.initColor()
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
          return .lightContent
    }
    
}
