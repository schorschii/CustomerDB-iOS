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
        UIApplication.shared.windows[0].tintColor = color
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            if #available(iOS 26.0, *) {
                let gradient = CAGradientLayer()
                var bounds = navigationBar.bounds
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                    let statusBarHeight = windowScene.statusBarManager?.statusBarFrame.height {
                    bounds.size.height += statusBarHeight
                } else {
                    bounds.size.height += UIApplication.shared.statusBarFrame.height
                }
                gradient.frame = bounds
                gradient.colors = [
                    color.cgColor,
                    UIColor.init(red: 0, green: 0, blue: 0, alpha: 0).cgColor
                ]
                gradient.startPoint = CGPoint(x: 0.5, y: 0.16)
                gradient.endPoint = CGPoint(x: 0.5, y: 0.94)

                let image = UIGraphicsImageRenderer(bounds: bounds).image { rendererContext in
                    gradient.render(in: rendererContext.cgContext)
                }.resizableImage(withCapInsets: .zero, resizingMode: .stretch)

                appearance.configureWithDefaultBackground()
                appearance.backgroundImage = image
            } else {
                appearance.backgroundColor = color
                appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
                appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
                
                navigationBar.barTintColor = color
                navigationBar.tintColor = .white
                
                UINavigationBar.appearance().tintColor = .white
                UINavigationBar.appearance().barTintColor = color
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
            if #unavailable(iOS 26.0) {
                mvc.tabBar.tintColor = color
            }
            if let cvc = mvc.selectedViewController as? CustomerTableViewController {
                cvc.initColor()
            } else if let vvc = mvc.selectedViewController as? VoucherTableViewController {
                vvc.initColor()
            }
        }
    }
    
}
