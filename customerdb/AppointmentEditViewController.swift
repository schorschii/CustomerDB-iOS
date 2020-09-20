//
//  AppointmentEditViewController.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class AppointmentEditViewController : UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pickerCalendar: UIPickerView!
    @IBOutlet weak var textFieldSubject: UITextField!
    @IBOutlet weak var textFieldCustomer: UITextField!
    @IBOutlet weak var textFieldLocation: UITextField!
    @IBOutlet weak var textFieldNotes: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var datePickerStart: UIDatePicker!
    @IBOutlet weak var datePickerEnd: UIDatePicker!
    @IBOutlet weak var imageQrCode: UIImageView!
    @IBOutlet weak var buttonShowCustomer: UIButton!
    
    let mDb = CustomerDatabase()
    var mCalendars:[CustomerCalendar] = []
    
    var mDefaultDate = Date()
    var mCurrentAppointment:CustomerAppointment? = nil
    var mIsNewAppointment = true
    
    override func viewDidLoad() {
        if(splitViewController!.isCollapsed) {
            navigationItem.leftBarButtonItem = nil
        }
        
        GuiHelper.adjustTextviewStyle(control: textFieldNotes, viewController: self)
        
        mCalendars = mDb.getCalendars(showDeleted: false)
        pickerCalendar.dataSource = self
        pickerCalendar.delegate = self
        
        datePicker.date = mDefaultDate
        datePickerEnd.date = datePickerStart.date.addingTimeInterval(30*60)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
        
        // load default values
        textFieldSubject.text = UserDefaults.standard.string(forKey: "default-appointment-title") ?? ""
        textFieldLocation.text = UserDefaults.standard.string(forKey: "default-appointment-location") ?? ""
        
        loadAppointment()
        
        Timer.scheduledTimer(
            timeInterval: 1.0, target: self,
            selector: #selector(refreshQrCode),
            userInfo: nil, repeats: true
        )
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return mCalendars.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return mCalendars[row].mTitle
    }
    
    var mCustomerPickerController:CustomerPickerController? = nil
    @IBAction func onClickAddCustomer(_ sender: UIButton) {
        self.mCustomerPickerController = CustomerPickerController(db: self.mDb)
        let vc = UIViewController()
        vc.preferredContentSize = CGSize(width: 250, height: 300)
        let pickerView = UIPickerView(frame: CGRect(x: 0, y: 0, width: 250, height: 300))
        pickerView.delegate = self.mCustomerPickerController
        pickerView.dataSource = self.mCustomerPickerController
        vc.view.addSubview(pickerView)
        let filterAlert = UIAlertController(title: NSLocalizedString("customer", comment: ""), message: nil, preferredStyle: UIAlertController.Style.alert)
        filterAlert.setValue(vc, forKey: "contentViewController")
        filterAlert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { (alert) in
            if(self.mCustomerPickerController!.mSelectedCustomer != nil) {
                self.buttonShowCustomer.isEnabled = true
                self.mCurrentAppointment?.mCustomerId = self.mCustomerPickerController!.mSelectedCustomer?.mId
                self.mCurrentAppointment?.mCustomer = ""
                self.textFieldCustomer.text = self.mCustomerPickerController!.mSelectedCustomer?.getFullName(lastNameFirst: false)
            }
        }))
        filterAlert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        self.present(filterAlert, animated: true)
    }
    @IBAction func onClickShowCustomer(_ sender: UIButton) {
        if let id = mCurrentAppointment?.mCustomerId {
            showCustomerDetails(id: id)
        }
    }
    @IBAction func onClickRemoveCustomer(_ sender: UIButton) {
        mCurrentAppointment?.mCustomer = ""
        mCurrentAppointment?.mCustomerId = nil
        textFieldCustomer.text = ""
        buttonShowCustomer.isEnabled = false
    }
    
    func showCustomerDetails(id: Int64) {
        let detailViewController = storyboard?.instantiateViewController(withIdentifier:"CustomerDetailsNavigationViewController") as! UINavigationController
        if let cdvc = detailViewController.viewControllers.first as? CustomerDetailsViewController {
            cdvc.mCurrentCustomerId = id
        }
        splitViewController?.showDetailViewController(detailViewController, sender: nil)
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
    
    func loadAppointment() {
        if(mCurrentAppointment != nil) {
            var count = 0
            for c in mCalendars {
                if(c.mId == mCurrentAppointment?.mCalendarId) {
                    pickerCalendar.selectRow(count, inComponent: 0, animated: false)
                }
                count += 1
            }
            textFieldSubject.text = mCurrentAppointment?.mTitle
            textFieldLocation.text = mCurrentAppointment?.mLocation
            textFieldNotes.text = mCurrentAppointment?.mNotes
            datePickerStart.date = mCurrentAppointment!.mTimeStart!
            datePickerEnd.date = mCurrentAppointment!.mTimeEnd!
            datePicker.date = mCurrentAppointment!.mTimeStart!
            if(mCurrentAppointment!.mCustomerId != nil) {
                if let c = mDb.getCustomer(id: mCurrentAppointment!.mCustomerId!, showDeleted: false) {
                    textFieldCustomer.text = c.getFullName(lastNameFirst: false)
                    buttonShowCustomer.isEnabled = true
                } else {
                    textFieldCustomer.text = NSLocalizedString("removed_placeholder", comment: "")
                }
            } else {
                textFieldCustomer.text = mCurrentAppointment?.mCustomer
            }
            mIsNewAppointment = false
        } else {
            mCurrentAppointment = CustomerAppointment()
            navigationItem.title = NSLocalizedString("new_appointment", comment: "")
            mIsNewAppointment = true
        }
    }
    
    @IBAction func onClickMore(_ sender: UIBarButtonItem) {
        let exportIcsAction = UIAlertAction(
            title: NSLocalizedString("export_ics", comment: ""),
            style: .default) { (action) in
                self.exportIcs(sender)
        }
        let exportCsvAction = UIAlertAction(
            title: NSLocalizedString("export_csv", comment: ""),
            style: .default) { (action) in
                self.exportCsv(sender)
        }
        let deleteAction = UIAlertAction(
            title: NSLocalizedString("delete_appointment", comment: ""),
            style: .destructive) { (action) in
                self.mDb.removeAppointment(id: self.mCurrentAppointment?.mId ?? -1)
                self.setUnsyncedChanges()
                self.exitViewController()
        }
        deleteAction.setValue(UIImage(named:"baseline_delete_forever_black_24pt"), forKey: "image")
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("close", comment: ""),
            style: .cancel) { (action) in
                
        }
        
        var message:String? = nil
        if(mCurrentAppointment != nil) {
            message = NSLocalizedString("ID:", comment: "")+" "+String(mCurrentAppointment!.mId)
        }
        let alert = UIAlertController(
            title: nil, message: message, preferredStyle: .actionSheet
        )
        alert.addAction(exportIcsAction)
        alert.addAction(exportCsvAction)
        if(mCurrentAppointment != nil) {
            alert.addAction(deleteAction)
        }
        alert.addAction(cancelAction)
        
        // On iPad, action sheets must be presented from a popover.
        alert.popoverPresentationController?.barButtonItem = sender
        self.present(alert, animated: true)
    }
    
    @IBAction func onClickDone(_ sender: UIBarButtonItem) {
        if(saveAppointment()) {
            exitViewController()
        }
    }
    
    func exportCsv(_ sender: UIBarButtonItem) {
        let csv = CalendarCsvWriter(appointments: [mCurrentAppointment!])
        
        let fileurl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("export."+String(mCurrentAppointment!.mId)+".csv")

        do {
            try csv.buildCsvContent().write(to: fileurl, atomically: true, encoding: .utf8)

            let activityController = UIActivityViewController(
                activityItems: [fileurl], applicationActivities: nil
            )
            activityController.popoverPresentationController?.barButtonItem = sender
            self.present(activityController, animated: true, completion: nil)

        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func exportIcs(_ sender: UIBarButtonItem) {
        let ics = CalendarIcsWriter(appointments: [mCurrentAppointment!])
        
        let fileurl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("export."+String(mCurrentAppointment!.mId)+".ics")

        do {
            try ics.buildIcsContent().write(to: fileurl, atomically: true, encoding: .utf8)

            let activityController = UIActivityViewController(
                activityItems: [fileurl], applicationActivities: nil
            )
            activityController.popoverPresentationController?.barButtonItem = sender
            self.present(activityController, animated: true, completion: nil)

        } catch let error {
            print(error.localizedDescription)
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
    
    func saveAppointment() -> Bool {
        if(mCalendars.count <= pickerCalendar.selectedRow(inComponent: 0)) {
            infoBox(title: nil, text: NSLocalizedString("no_calendar_selected", comment: ""))
            return false
        }
        
        if(!updateAppointmentObjectByInputs()) {
            return false
        }
        
        if(mCurrentAppointment!.mTimeStart!.timeIntervalSince1970 > mCurrentAppointment!.mTimeEnd!.timeIntervalSince1970) {
            infoBox(title: nil, text: NSLocalizedString("end_date_before_start_date", comment: ""))
            return false
        }
        if(mCurrentAppointment!.mTimeEnd!.timeIntervalSince1970 - mCurrentAppointment!.mTimeStart!.timeIntervalSince1970 < 60*5) {
            infoBox(title: nil, text: NSLocalizedString("appointment_too_short", comment: ""))
            return false
        }
        
        var success = false
        if(mIsNewAppointment) {
            success = mDb.insertAppointment(a: mCurrentAppointment!)
        } else {
            success = mDb.updateAppointment(a: mCurrentAppointment!)
        }
        
        if(success) {
            setUnsyncedChanges()
        }
        
        return success
    }
    
    func updateAppointmentObjectByInputs() -> Bool {
        // check if a calendar is selected
        if(mCalendars.count <= pickerCalendar.selectedRow(inComponent: 0)) {
            return false
        }
        mCurrentAppointment?.mCalendarId = mCalendars[pickerCalendar.selectedRow(inComponent: 0)].mId
        
        let dateFormatterDateTime = DateFormatter()
        dateFormatterDateTime.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let dateFormatterDate = DateFormatter()
        dateFormatterDate.dateFormat = "yyyy-MM-dd"
        
        let dateFormatterTime = DateFormatter()
        dateFormatterTime.dateFormat = "HH:mm"
        
        let strTimeStart = dateFormatterDate.string(from: datePicker.date) + " " + dateFormatterTime.string(from: datePickerStart.date) + ":00"
        let strTimeEnd = dateFormatterDate.string(from: datePicker.date) + " " + dateFormatterTime.string(from: datePickerEnd.date) + ":00"
        
        mCurrentAppointment?.mTimeStart = CustomerDatabase.parseDateRaw(strDate: strTimeStart)
        mCurrentAppointment?.mTimeEnd = CustomerDatabase.parseDateRaw(strDate: strTimeEnd)
        
        if(mCurrentAppointment?.mTimeStart == nil || mCurrentAppointment?.mTimeEnd == nil) {
            return false
        }
        
        mCurrentAppointment?.mTitle = textFieldSubject.text!
        mCurrentAppointment?.mLocation = textFieldLocation.text!
        mCurrentAppointment?.mNotes = textFieldNotes.text!
        mCurrentAppointment?.mLastModified = Date()
        
        return true
    }
    
    func infoBox(title: String?, text: String?) {
        let alert = UIAlertController(
            title: title, message: text, preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("ok", comment: ""),
            style: .cancel
        ))
        self.present(alert, animated: true)
    }
    
    var mLastQrContent = ""
    @objc func refreshQrCode() {
        if(!updateAppointmentObjectByInputs()) { return }
        var content = "BEGIN:VEVENT" + "\n"
        content += "SUMMARY:" + textFieldSubject.text! + "\n"
        content +=  "DESCRIPTION:" + textFieldNotes.text!.replacingOccurrences(of: "\n", with: "\\n") + "\n"
        content +=  "LOCATION:" + textFieldLocation.text! + "\n"
        content +=  "DTSTART:" + CalendarIcsWriter.format(date: mCurrentAppointment!.mTimeStart!) + "\n"
        content +=  "DTEND:" + CalendarIcsWriter.format(date: mCurrentAppointment!.mTimeEnd!) + "\n"
        content +=  "END:VEVENT" + "\n"
        if(mLastQrContent == content) {return}
        mLastQrContent = content
        
        let data = content.data(using: String.Encoding.ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            if let output = filter.outputImage?.transformed(by: transform) {
                imageQrCode.image = UIImage(ciImage: output)
            }
        }
    }
}
