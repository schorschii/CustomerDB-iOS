//
//  CustomerTableController.swift
//  Copyright © 2019 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class CustomerCell : UITableViewCell {
    @IBOutlet weak var labelMain: UILabel!
    @IBOutlet weak var labelSub: UILabel!
}

class CustomerTableViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var buttonAdd: UIButton!
    @IBOutlet weak var labelCommercialUsage: UIView!
    
    let mDb = CustomerDatabase()
    var mCustomers:[Customer] = []
    var mFilterPickerController: FilterPickerController? = nil
    var mSortPickerController: SortPickerController? = nil
    
    var mCurrentSearch:String? = nil
    var mCurrentFilterGroup:String? = nil
    var mCurrentFilterCity:String? = nil
    var mCurrentFilterCountry:String? = nil
    var mCurrentSortField:String? = nil
    var mCurrentSortAsc:Bool = true
    
    var mMainViewControllerRef:MainViewController? = nil
    
    let mDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        initColor()
        initSearch()
        initCommercialUsageNote()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        reloadCustomers(search: mCurrentSearch, refreshTable: true)
        initCommercialUsageNote()
        initColor()
    }
    
    @IBAction func onClickAdd(_ sender: UIButton) {
        let detailViewController = storyboard?.instantiateViewController(withIdentifier: "CustomerEditNavigationViewController")
        splitViewController?.showDetailViewController(detailViewController!, sender: nil)
    }
    
    func initCommercialUsageNote() {
        if(mDefaults.bool(forKey: "unlocked-cu")) {
            labelCommercialUsage.isHidden = true
        }
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
    }
    
    func reloadCustomers(search:String?, refreshTable:Bool) {
        var tempCustomers = mDb.getCustomers(showDeleted: false, withFiles: false)
        var title = ""
        
        // apply filter
        if(mCurrentFilterGroup != nil || mCurrentFilterCity != nil || mCurrentFilterCountry != nil) {
            if(mCurrentFilterGroup != nil) {
                title += mCurrentFilterGroup! + " "
            }
            if(mCurrentFilterCity != nil) {
                title += mCurrentFilterCity! + " "
            }
            if(mCurrentFilterCountry != nil) {
                title += mCurrentFilterCountry! + " "
            }
            var filteredCustomers: [Customer] = []
            for customer in tempCustomers {
                if( (mCurrentFilterGroup == nil || customer.mGroup == mCurrentFilterGroup)
                    && (mCurrentFilterCity == nil || customer.mCity == mCurrentFilterCity)
                    && (mCurrentFilterCountry == nil || customer.mCountry == mCurrentFilterCountry)
                    ) {
                    filteredCustomers.append(customer)
                }
            }
            tempCustomers = filteredCustomers
        }
        
        // set title
        if(title.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
            title = NSLocalizedString("customer_database", comment: "")
        }
        if let msvc = splitViewController as? MainSplitViewController {
            if let mnvc = msvc.viewControllers[0] as? MasterNavigationController {
                if let mvc = mnvc.viewControllers[0] as? MainViewController {
                    mvc.title = title
                }
            }
        }
        
        // apply sort
        if(mCurrentSortField != nil) {
            if(mCurrentSortAsc) {
                if(mCurrentSortField == "first_name") {
                    tempCustomers.sort(by: { $0.mFirstName < $1.mFirstName })
                } else if(mCurrentSortField == "last_name") {
                    tempCustomers.sort(by: { $0.mLastName < $1.mLastName })
                } else {
                    tempCustomers.sort(by: { $0.getCustomFieldString(key: mCurrentSortField!) ?? "" < $1.getCustomFieldString(key: mCurrentSortField!) ?? "" })
                }
            } else {
                if(mCurrentSortField == "first_name") {
                    tempCustomers.sort(by: { $0.mFirstName > $1.mFirstName })
                } else if(mCurrentSortField == "last_name") {
                    tempCustomers.sort(by: { $0.mLastName > $1.mLastName })
                } else {
                    tempCustomers.sort(by: { $0.getCustomFieldString(key: mCurrentSortField!) ?? "" > $1.getCustomFieldString(key: mCurrentSortField!) ?? "" })
                }
            }
        }
        
        // apply search
        if(search == nil || search == "") {
            mCurrentSearch = nil
            mCustomers = tempCustomers
        } else {
            mCurrentSearch = search
            let normalizedSearch = search!.uppercased()
            mCustomers.removeAll()
            for customer in tempCustomers {
                if(customer.mTitle.uppercased().contains(normalizedSearch)
                    || customer.mFirstName.uppercased().contains(normalizedSearch)
                    || customer.mLastName.uppercased().contains(normalizedSearch)
                    || customer.mPhoneHome.uppercased().contains(normalizedSearch)
                    || customer.mPhoneMobile.uppercased().contains(normalizedSearch)
                    || customer.mPhoneWork.uppercased().contains(normalizedSearch)
                    || customer.mEmail.uppercased().contains(normalizedSearch)
                    || customer.mStreet.uppercased().contains(normalizedSearch)
                    || customer.mZipcode.uppercased().contains(normalizedSearch)
                    || customer.mCity.uppercased().contains(normalizedSearch)
                    || customer.mGroup.uppercased().contains(normalizedSearch)
                    || customer.mNotes.uppercased().contains(normalizedSearch)) {
                    mCustomers.append(customer)
                }
            }
        }
        
        if(refreshTable) { tableView.reloadData() }
    }
    
    func filterDialog() {
        self.mFilterPickerController = FilterPickerController(db: self.mDb)
        let vc = UIViewController()
        vc.preferredContentSize = CGSize(width: 250, height: 300)
        let pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: 250, height: 300))
        pickerView.delegate = self.mFilterPickerController
        pickerView.dataSource = self.mFilterPickerController
        vc.view.addSubview(pickerView)
        let filterAlert = UIAlertController(title: NSLocalizedString("filter", comment: ""), message: nil, preferredStyle: UIAlertController.Style.alert)
        filterAlert.setValue(vc, forKey: "contentViewController")
        filterAlert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { (alert) in
            if(self.mFilterPickerController!.mSelectedGroup == "") {
                self.mCurrentFilterGroup = nil
            } else {
                self.mCurrentFilterGroup = self.mFilterPickerController!.mSelectedGroup
            }
            if(self.mFilterPickerController!.mSelectedCity == "") {
                self.mCurrentFilterCity = nil
            } else {
                self.mCurrentFilterCity = self.mFilterPickerController!.mSelectedCity
            }
            if(self.mFilterPickerController!.mSelectedCountry == "") {
                self.mCurrentFilterCountry = nil
            } else {
                self.mCurrentFilterCountry = self.mFilterPickerController!.mSelectedCountry
            }
            self.reloadCustomers(search: nil, refreshTable: true)
        }))
        filterAlert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: { (alert) in
            self.mCurrentFilterGroup = nil
            self.mCurrentFilterCity = nil
            self.mCurrentFilterCountry = nil
            self.reloadCustomers(search: nil, refreshTable: true)
        }))
        self.present(filterAlert, animated: true)
    }
    
    func sortDialog() {
        self.mSortPickerController = SortPickerController(db: self.mDb)
        let vc = UIViewController()
        vc.preferredContentSize = CGSize(width: 250, height: 300)
        let pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: 250, height: 300))
        pickerView.delegate = self.mSortPickerController
        pickerView.dataSource = self.mSortPickerController
        vc.view.addSubview(pickerView)
        let sortAlert = UIAlertController(title: NSLocalizedString("order", comment: ""), message: nil, preferredStyle: UIAlertController.Style.alert)
        sortAlert.setValue(vc, forKey: "contentViewController")
        sortAlert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { (alert) in
            self.mCurrentSortField = self.mSortPickerController!.mSelectedSortField
            self.mCurrentSortAsc = self.mSortPickerController!.mSelectedOrderAsc
            self.reloadCustomers(search: nil, refreshTable: true)
        }))
        sortAlert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: { (alert) in
            self.mCurrentSortField = nil
            self.mCurrentSortAsc = true
            self.reloadCustomers(search: nil, refreshTable: true)
        }))
        self.present(sortAlert, animated: true)
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
        let cell = tableView.dequeueReusableCell(withIdentifier:"CustomerCell", for: indexPath) as! CustomerCell
        cell.labelMain.text = customer.getFirstLine()
        cell.labelSub.text = customer.getSecondLine()
        return cell
    }
    internal func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            mDb.removeCustomer(id: mCustomers[indexPath.row].mId)
            reloadCustomers(search: mCurrentSearch, refreshTable: false)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
}
