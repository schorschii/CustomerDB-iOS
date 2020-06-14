//
//  VoucherEditViewController.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class VoucherEditViewController : UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var textFieldCurrentValue: UITextField!
    @IBOutlet weak var textFieldVoucherNumber: UITextField!
    @IBOutlet weak var textFieldFromCustomer: UITextField!
    @IBOutlet weak var textFieldForCustomer: UITextField!
    @IBOutlet weak var textFieldNotes: UITextField!
    @IBOutlet weak var textFieldValidUntil: UITextField!
    @IBOutlet weak var textFieldCurrency: UILabel!
    @IBOutlet weak var stackViewSyncInfo: UIStackView!
    
    let mDb = CustomerDatabase()
    
    var mCurrentVoucher:Voucher? = nil
    var mCurrentVoucherValidUntil:Date? = nil
    var mIsNewVoucher = true
    
    override func viewDidLoad() {
        if(splitViewController!.isCollapsed ||
            (!splitViewController!.isCollapsed && mCurrentVoucher != nil)) {
            navigationItem.leftBarButtonItem = nil
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
        
        let datePickerView = UIDatePicker()
        datePickerView.datePickerMode = .date
        textFieldValidUntil.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(handleDatePicker(sender:)), for: .valueChanged)
        
        let defaults = UserDefaults.standard
        let syncMode = defaults.integer(forKey: "sync-mode")
        if(syncMode == 1 || syncMode == 2) {
            stackViewSyncInfo.isHidden = false
        } else {
            stackViewSyncInfo.isHidden = true
        }
        textFieldCurrency.text = defaults.string(forKey: "currency")
        loadVoucher()
    }
    
    @objc func handleDatePicker(sender: UIDatePicker) {
        mCurrentVoucherValidUntil = sender.date
        textFieldValidUntil.text = CustomerDatabase.dateToDisplayStringWithoutTime(date: sender.date)
    }
    @IBAction func onClickGenerateVoucherNumber(_ sender: UIButton) {
        var newVoucherNo = UserDefaults.standard.integer(forKey: "voucher-no")
        newVoucherNo += 1
        while(existsVoucherNo(voucherNo: String(newVoucherNo))) {
            newVoucherNo += 1
        }
        textFieldVoucherNumber.text = String(newVoucherNo)
    }
    func existsVoucherNo(voucherNo:String) -> Bool {
        for v in mDb.getVouchers(showDeleted: true) {
            if(v.mVoucherNo == voucherNo) {
                return true
            }
        }
        return false
    }
    @IBAction func onClickBirthdayRemove(_ sender: UIButton) {
        mCurrentVoucherValidUntil = nil
        textFieldValidUntil.text = ""
    }

    @objc func keyboardWillShow(notification:NSNotification){
        //give room at the bottom of the scroll view, so it doesn't cover up anything the user needs to tap
        let userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        var contentInset:UIEdgeInsets = self.scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height
        scrollView.contentInset = contentInset
    }
    @objc func keyboardWillHide(notification:NSNotification){
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
    }
    
    @IBAction func onClickClose(_ sender: UIBarButtonItem) {
        exitViewController()
    }
    
    func loadVoucher() {
        if(mCurrentVoucher != nil) {
            textFieldCurrentValue.text = Voucher.format(value: mCurrentVoucher!.mCurrentValue)
            textFieldVoucherNumber.text = mCurrentVoucher!.mVoucherNo
            if(mCurrentVoucher!.mValidUntil == nil) {
                textFieldValidUntil.text = ""
            } else {
                mCurrentVoucherValidUntil = mCurrentVoucher!.mValidUntil
                textFieldValidUntil.text = CustomerDatabase.dateToDisplayString(date: mCurrentVoucher!.mValidUntil!)
            }
            textFieldFromCustomer.text = mCurrentVoucher?.mFromCustomer
            textFieldForCustomer.text = mCurrentVoucher?.mForCustomer
            textFieldNotes.text = mCurrentVoucher?.mNotes
            textFieldVoucherNumber.isEnabled = false
            mIsNewVoucher = false
        } else {
            navigationItem.title = NSLocalizedString("new_voucher", comment: "")
            mIsNewVoucher = true
        }
    }
    
    @IBAction func onClickDone(_ sender: UIBarButtonItem) {
        if(saveVoucher()) {
            exitViewController()
        }
    }
    
    func exitViewController() {
        triggerListUpdate()
        if(mIsNewVoucher) {
            // new voucher
            if(!splitViewController!.isCollapsed) {
                // hide detail view controller on the right side
                if let svc = splitViewController as? MainSplitViewController {
                    svc.closeDetailViewController()
                }
            } else {
                // go back to list view
                if let navController = splitViewController?.viewControllers[0] as? UINavigationController {
                    navController.popViewController(animated: true)
                }
            }
        } else {
            // go back to voucher details
            navigationController?.popViewController(animated: true)
        }
    }
    
    func setUnsyncedChanges() {
        if let svc = splitViewController as? MainSplitViewController {
            if let mnvc = svc.viewControllers[0] as? MasterNavigationController {
                if let mvc = mnvc.viewControllers.first as? MainViewController {
                    mvc.setUnsyncedChanges()
                }
            }
        }
    }
    func triggerListUpdate() {
        // on iPad, we must manually trigger the update method
        // on iPhone, this is handled by the viewWillAppear() method
        if(!splitViewController!.isCollapsed) {
            if let svc = splitViewController as? MainSplitViewController {
                if let mnvc = svc.viewControllers[0] as? MasterNavigationController {
                    if let mvc = mnvc.viewControllers.last as? MainViewController {
                        mvc.reloadData()
                    }
                }
            }
        }
    }
    
    func saveVoucher() -> Bool {
        if(mCurrentVoucher == nil) {
            mCurrentVoucher = Voucher()
        }
        
        mCurrentVoucher?.mCurrentValue = Double(textFieldCurrentValue.text!) ?? mCurrentVoucher!.mCurrentValue
        if(mIsNewVoucher) {
            mCurrentVoucher?.mOriginalValue = mCurrentVoucher!.mCurrentValue
        }
        mCurrentVoucher?.mVoucherNo = textFieldVoucherNumber.text!
        mCurrentVoucher?.mFromCustomer = textFieldFromCustomer.text!
        mCurrentVoucher?.mForCustomer = textFieldForCustomer.text!
        mCurrentVoucher?.mNotes = textFieldNotes.text!
        mCurrentVoucher?.mValidUntil = mCurrentVoucherValidUntil
        mCurrentVoucher?.mLastModified = Date()
        
        if let newVoucherNumber = Int(textFieldVoucherNumber.text!) {
            UserDefaults.standard.set(newVoucherNumber, forKey: "voucher-no")
        }
        
        var success = false
        if(mIsNewVoucher) {
            success = mDb.insertVoucher(v: mCurrentVoucher!)
        } else {
            success = mDb.updateVoucher(v: mCurrentVoucher!)
        }
        
        if(success) {
            setUnsyncedChanges()
        }
        
        return success
    }
    
}
