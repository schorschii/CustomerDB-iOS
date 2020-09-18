//
//  VoucherDetailsViewController.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class VoucherDetailsViewController : UIViewController {
    
    @IBOutlet weak var labelCurrentValue: UILabel!
    @IBOutlet weak var labelOriginalValue: UILabel!
    @IBOutlet weak var labelVoucherNumber: UILabel!
    @IBOutlet weak var labelFromCustomer: UILabel!
    @IBOutlet weak var labelForCustomer: UILabel!
    @IBOutlet weak var labelIssued: UILabel!
    @IBOutlet weak var labelValidUntil: UILabel!
    @IBOutlet weak var labelRedeemed: UILabel!
    @IBOutlet weak var labelNotes: UILabel!
    @IBOutlet weak var labelLastModified: UILabel!
    @IBOutlet weak var buttonEdit: UIButton!
    
    let mDb = CustomerDatabase()
    
    var mCurrency = UserDefaults.standard.string(forKey: "currency") ?? ""
    
    var mCurrentVoucherId:Int64 = -1
    private var mCurrentVoucher:Voucher? = nil
    
    override func viewDidLoad() {
        initColor()
        loadVoucher()
    }
    
    func initColor() {
        buttonEdit.backgroundColor = UINavigationBar.appearance().barTintColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadVoucher()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? VoucherEditViewController {
            vc.mCurrentVoucher = mCurrentVoucher
        }
    }
    
    func exitViewController() {
        triggerListUpdate()
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
    
    func loadVoucher() {
        // (re)query voucher
        mCurrentVoucher = mDb.getVoucher(id: mCurrentVoucherId)
        if(mCurrentVoucher == nil) {
            exitViewController()
            return
        }
        
        labelCurrentValue.text = Voucher.format(value: mCurrentVoucher!.mCurrentValue) + " " + mCurrency
        labelOriginalValue.text = Voucher.format(value: mCurrentVoucher!.mOriginalValue) + " " + mCurrency
        labelVoucherNumber.text = mCurrentVoucher?.mVoucherNo
        if(mCurrentVoucher!.mFromCustomerId != nil) {
            if let c = mDb.getCustomer(id: mCurrentVoucher!.mFromCustomerId!, showDeleted: false) {
                labelFromCustomer.text = c.getFullName(lastNameFirst: false)
            } else {
                labelFromCustomer.text = NSLocalizedString("removed_placeholder", comment: "")
            }
        } else {
            labelFromCustomer.text = mCurrentVoucher?.mFromCustomer
        }
        if(mCurrentVoucher!.mForCustomerId != nil) {
            if let c = mDb.getCustomer(id: mCurrentVoucher!.mForCustomerId!, showDeleted: false) {
                labelForCustomer.text = c.getFullName(lastNameFirst: false)
            } else {
                labelForCustomer.text = NSLocalizedString("removed_placeholder", comment: "")
            }
        } else {
            labelForCustomer.text = mCurrentVoucher?.mForCustomer
        }
        labelNotes.text = mCurrentVoucher?.mNotes
        labelIssued.text = CustomerDatabase.dateToDisplayString(date: mCurrentVoucher!.mIssued)
        if(mCurrentVoucher!.mValidUntil != nil) {
            labelValidUntil.text = CustomerDatabase.dateToDisplayString(date: mCurrentVoucher!.mValidUntil!)
        } else {
            labelValidUntil.text = ""
        }
        if(mCurrentVoucher!.mRedeemed != nil) {
            labelRedeemed.text = CustomerDatabase.dateToDisplayString(date: mCurrentVoucher!.mRedeemed!)
        } else {
            labelRedeemed.text = ""
        }
        labelLastModified.text = CustomerDatabase.dateToDisplayString(date: mCurrentVoucher!.mLastModified)
    }
    
    @IBAction func onClickRedeem(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: NSLocalizedString("redeem", comment: ""), message: nil, preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.keyboardType = .numbersAndPunctuation
            textField.placeholder = NSLocalizedString("value", comment: "")
            textField.text = Voucher.format(value: self.mCurrentVoucher!.mCurrentValue)
        }
        alert.addTextField { (textField) in
            textField.placeholder = NSLocalizedString("notes", comment: "")
            textField.text = self.mCurrentVoucher!.mNotes
        }
        alert.addAction(UIAlertAction(title: NSLocalizedString("redeem", comment: ""), style: .default, handler: { [weak alert] (_) in
            let textFieldRedeemValue = alert?.textFields![0]
            let textFieldNotes = alert?.textFields![1]
            if let doubleValue = Double(textFieldRedeemValue!.text!) {
                self.mCurrentVoucher?.mCurrentValue -= doubleValue
                self.mCurrentVoucher?.mNotes = textFieldNotes!.text!
                self.mCurrentVoucher?.mRedeemed = Date()
                self.mCurrentVoucher?.mLastModified = Date()
                _ = self.mDb.updateVoucher(v: self.mCurrentVoucher!)
                self.loadVoucher()
                self.triggerListUpdate()
                self.setUnsyncedChanges()
            } else {
                let alert2 = UIAlertController(title: NSLocalizedString("number_parse_error", comment: ""), message: NSLocalizedString("enter_valid_number", comment: ""), preferredStyle: .alert)
                alert2.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .cancel, handler: nil))
                self.present(alert2, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: {
            
        })
    }
    @IBAction func onClickMore(_ sender: UIBarButtonItem) {
        let printAction = UIAlertAction(
            title: NSLocalizedString("print_voucher", comment: ""),
            style: .default) { (action) in
                
        }
        printAction.setValue(UIImage(named:"baseline_print_black_24pt"), forKey: "image")
        let deleteAction = UIAlertAction(
            title: NSLocalizedString("delete_voucher", comment: ""),
            style: .destructive) { (action) in
                self.mDb.removeVoucher(id: self.mCurrentVoucher?.mId ?? -1)
                self.setUnsyncedChanges()
                self.exitViewController()
        }
        deleteAction.setValue(UIImage(named:"baseline_delete_forever_black_24pt"), forKey: "image")
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("close", comment: ""),
            style: .cancel) { (action) in
                
        }
        
        let alert = UIAlertController(
            title: nil,
            message: NSLocalizedString("ID:", comment: "")+" "+String(mCurrentVoucher!.mId),
            preferredStyle: .actionSheet
        )
        //alert.addAction(printAction) // ToDo
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        // On iPad, action sheets must be presented from a popover.
        alert.popoverPresentationController?.barButtonItem = sender
        
        self.present(alert, animated: true) {
            // The alert was presented
        }
    }

    @IBAction func onClickEdit(_ sender: UIButton) {
        performSegue(withIdentifier: "segueVoucherEdit", sender: nil)
    }
    
}
