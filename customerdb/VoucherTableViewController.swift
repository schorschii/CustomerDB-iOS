//
//  VoucherTableViewController.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class VoucherCell : UITableViewCell {
    @IBOutlet weak var labelMain: UILabel!
    @IBOutlet weak var labelSub: UILabel!
}

class VoucherTableViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {
    
    @IBOutlet weak var imageLogo: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var buttonAdd: UIButton!
    
    let mDb = CustomerDatabase()
    var mVouchers:[Voucher] = []
    var mCurrentSearch:String? = nil
    
    var mMainViewControllerRef:MainViewController? = nil
    
    var mCurrency = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mCurrency = UserDefaults.standard.string(forKey: "currency") ?? ""
        tableView.dataSource = self
        tableView.delegate = self
        initColor()
        initSearch()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        reloadVouchers(search: mCurrentSearch, refreshTable: true)
        initColor()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
    @IBAction func onClickAdd(_ sender: UIButton) {
        let detailViewController = storyboard?.instantiateViewController(withIdentifier: "VoucherEditNavigationViewController")
        splitViewController?.showDetailViewController(detailViewController!, sender: nil)
    }
    
    let mSearchController = UISearchController(searchResultsController: nil)
    func initSearch() {
        if #available(iOS 11.0, *) {} else {
            mSearchController.searchResultsUpdater = self
            mSearchController.obscuresBackgroundDuringPresentation = false
            // cancel button tint color
            mSearchController.searchBar.tintColor = .white
            mSearchController.searchBar.barTintColor = navigationController?.navigationBar.barTintColor
            tableView.tableHeaderView = mSearchController.searchBar
            //definesPresentationContext = true
        }
    }
    func updateSearchResults(for searchController: UISearchController) {
        if(mMainViewControllerRef != nil) {
            mMainViewControllerRef!.updateSearchResults(for: searchController)
        }
    }
    
    func initColor() {
        buttonAdd.backgroundColor = navigationController?.navigationBar.barTintColor
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
        
        if(UserDefaults.standard.bool(forKey: "unlocked-do")) {
            if let image = GuiHelper.loadImage(file: SettingsViewController.getLogoFile()) {
                imageLogo.contentMode = .scaleAspectFit
                imageLogo.image = image
                imageLogo.alpha = 0.2
            } else {
                imageLogo.image = UIImage(named: "icon_gray")
                imageLogo.alpha = 0.05
            }
        }
    }
    
    func reloadVouchers(search:String?, refreshTable:Bool) {
        let tempVouchers = mDb.getVouchers(showDeleted: false)
        if(search == nil || search == "") {
            mCurrentSearch = nil
            mVouchers = tempVouchers
        } else {
            mCurrentSearch = search
            let normalizedSearch = search!.uppercased()
            mVouchers.removeAll()
            for voucher in tempVouchers {
                if(voucher.mNotes.uppercased().contains(normalizedSearch)
                    || voucher.mVoucherNo.uppercased().contains(normalizedSearch)
                    || voucher.mFromCustomer.uppercased().contains(normalizedSearch)
                    || voucher.mForCustomer.uppercased().contains(normalizedSearch)) {
                    mVouchers.append(voucher)
                }
            }
        }
        if(refreshTable) { tableView.reloadData() }
    }
    
    // list implementation
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let detailViewController = storyboard?.instantiateViewController(withIdentifier:"VoucherDetailsNavigationViewController") as! UINavigationController
        if let vdvc = detailViewController.viewControllers.first as? VoucherDetailsViewController {
            vdvc.mCurrentVoucherId = mVouchers[indexPath.row].mId
        }
        splitViewController?.showDetailViewController(detailViewController, sender: nil)
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mVouchers.count
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    func tableView(_ tableView: UITableView,
                             cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let voucher = mVouchers[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier:"VoucherCell", for: indexPath) as! VoucherCell
        if(voucher.mCurrentValue != voucher.mOriginalValue) {
            cell.labelMain.text = Voucher.format(value: voucher.mCurrentValue)+" "+mCurrency + "  ("+Voucher.format(value: voucher.mOriginalValue)+" "+mCurrency+")"
        } else {
            cell.labelMain.text = Voucher.format(value: voucher.mCurrentValue)+" "+mCurrency
        }
        if(voucher.mVoucherNo == "") {
            cell.labelSub.text = String(voucher.mId)
        } else {
            cell.labelSub.text = voucher.mVoucherNo
        }
        return cell
    }
    internal func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            mDb.removeVoucher(id: mVouchers[indexPath.row].mId)
            reloadVouchers(search: mCurrentSearch, refreshTable: false)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
}
