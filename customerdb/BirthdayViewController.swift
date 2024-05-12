//
//  BirthdayViewController.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class CustomerBirthdayCell : UITableViewCell {
    @IBOutlet weak var labelMain: UILabel!
    @IBOutlet weak var labelSub: UILabel!
}

class CustomerBirthdayTableViewController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    static var DEFAULT_BIRTHDAY_PREVIEW_DAYS = 14
    
    let mDb = CustomerDatabase()
    var mCustomers:[Customer] = []
    
    let mDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.barStyle = .black
        tableView.dataSource = self
        tableView.delegate = self
        initColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        reloadCustomers()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
    func initColor() {
        if #available(iOS 13.0, *) {
            // applies background color (from navigation controller), also if search field is shown
            let navigationBar = self.navigationController!.navigationBar
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.backgroundColor = navigationBar.barTintColor
            navigationBar.standardAppearance = navBarAppearance
            navigationBar.scrollEdgeAppearance = navBarAppearance
        }
    }
    
    func reloadCustomers() {
        let previewDays = UserDefaults.standard.integer(forKey: "birthday-preview-days")
        mCustomers = CustomerBirthdayTableViewController.getSoonBirthdayCustomers(
            customers: mDb.getCustomers(search: nil, showDeleted: false, withFiles: false), days: previewDays
        )
        tableView.reloadData()
    }
    
    static func getSoonBirthdayCustomers(customers:[Customer], days:Int) -> [Customer] {
        var birthdayCustomers:[Customer] = []
        let cal = Calendar.current
        
        var dayComponent = DateComponents()
        dayComponent.day = -1
        let start = cal.date(byAdding: dayComponent, to: Date())
        
        var dayComponent2 = DateComponents()
        dayComponent2.day = days
        let end = cal.date(byAdding: dayComponent2, to: Date())
        
        for c in customers {
            let birthday = c.getNextBirthday()
            if(birthday != nil && isWithinRange(birthday, start, end)) {
                birthdayCustomers.append(c)
            }
        }
        
        birthdayCustomers.sort {
            $0.getNextBirthday()! < $1.getNextBirthday()!
        }
        
        return birthdayCustomers
    }
    
    static func isWithinRange(_ birthday:Date?, _ start:Date?, _ end:Date?) -> Bool {
        if(birthday == nil || start == nil || end == nil) {
            return false
        }
        if(birthday!.timeIntervalSince1970 > start!.timeIntervalSince1970
            && birthday!.timeIntervalSince1970 < end!.timeIntervalSince1970) {
            return true
        }
        return false
    }
    
    // list implementation
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailViewController = storyboard?.instantiateViewController(withIdentifier:"CustomerDetailsNavigationViewController") as! UINavigationController
        if let cdvc = detailViewController.viewControllers.first as? CustomerDetailsViewController {
            cdvc.mCurrentCustomerId = mCustomers[indexPath.row].mId
        }
        splitViewController?.showDetailViewController(detailViewController, sender: nil)
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mCustomers.count
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    func tableView(_ tableView: UITableView,
                             cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let customer = mCustomers[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier:"CustomerBirthdayCell", for: indexPath) as! CustomerBirthdayCell
        cell.labelMain.text = customer.getFirstLine()
        cell.labelSub.text = customer.getBirthdayString()
        return cell
    }
    internal func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            mDb.removeCustomer(id: mCustomers[indexPath.row].mId)
            reloadCustomers()
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}
