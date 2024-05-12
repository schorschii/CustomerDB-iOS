//
//  SettingsViewController.swift
//  Copyright © 2019 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController: UIViewController, UITextFieldDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var segmentedControlSync: UISegmentedControl!
    @IBOutlet weak var labelSyncModeDesc: UILabel!
    @IBOutlet weak var textFieldSyncUrl: UITextField!
    @IBOutlet weak var textFieldSyncUsername: UITextField!
    @IBOutlet weak var textFieldSyncPassword: UITextField!
    @IBOutlet weak var switchAllowCharsInNumbers: UISwitch!
    @IBOutlet weak var switchShowPicture: UISwitch!
    @IBOutlet weak var switchShowPhoneField: UISwitch!
    @IBOutlet weak var switchShowEmailField: UISwitch!
    @IBOutlet weak var switchShowAddressField: UISwitch!
    @IBOutlet weak var switchShowGroupField: UISwitch!
    @IBOutlet weak var switchShowNoteField: UISwitch!
    @IBOutlet weak var switchShowNewsletterField: UISwitch!
    @IBOutlet weak var switchShowBirthdayField: UISwitch!
    @IBOutlet weak var switchShowFiles: UISwitch!
    @IBOutlet weak var switchShowConsentField: UISwitch!
    @IBOutlet weak var textFieldBirthdayPreviewDays: UITextField!
    @IBOutlet weak var textFieldCurrency: UITextField!
    @IBOutlet weak var sliderRed: UISlider!
    @IBOutlet weak var sliderGreen: UISlider!
    @IBOutlet weak var sliderBlue: UISlider!
    @IBOutlet weak var viewColorPreview: UIView!
    @IBOutlet weak var textFieldCustomFields: UITextField!
    @IBOutlet weak var buttonChooseLogo: UIButton!
    @IBOutlet weak var buttonRemoveLogo: UIButton!
    @IBOutlet weak var buttonEditCustomField: UIButton!
    @IBOutlet weak var buttonRemoveCustomField: UIButton!
    @IBOutlet weak var textFieldCustomFieldPresets: UITextField!
    @IBOutlet weak var stackViewCustomFieldPresets: UIStackView!
    @IBOutlet weak var buttonRemoveCustomFieldPreset: UIButton!
    @IBOutlet weak var textFieldCalendars: UITextField!
    @IBOutlet weak var buttonEditCalendar: UIButton!
    @IBOutlet weak var buttonRemoveCalendar: UIButton!
    
    static var DEFAULT_COLOR_R = 15
    static var DEFAULT_COLOR_G = 124
    static var DEFAULT_COLOR_B = 157
    
    let mDefaults = UserDefaults.standard
    let mDb = CustomerDatabase()
    
    var mAppPassword = ""
    
    var mMainViewControllerRef: MainViewController? = nil
    
    var mCustomFieldsController: PickerDataController? = nil
    var mCurrentCustomField: CustomField? = nil
    var mCustomFieldPresetsController: PickerDataController? = nil
    var mCurrentCustomFieldPreset: KeyValueItem? = nil
    
    var mCalendarsController: PickerDataController? = nil
    var mCurrentCalendar: CustomerCalendar? = nil
    
    override func viewDidLoad() {
        navigationController?.navigationBar.barStyle = .default
        initDropDownStyle(textField: textFieldCustomFields)
        initDropDownStyle(textField: textFieldCustomFieldPresets)
        initDropDownStyle(textField: textFieldCalendars)
        createToolbar()
        loadSettings()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
        navigationController?.navigationBar.barStyle = .black
    }
    
    func loadSettings() {
        segmentedControlSync.selectedSegmentIndex = mDefaults.integer(forKey: "sync-mode")
        textFieldSyncUrl.text = mDefaults.string(forKey: "sync-url")
        textFieldSyncUsername.text = mDefaults.string(forKey: "sync-username")
        textFieldSyncPassword.text = mDefaults.string(forKey: "sync-password")
        switchAllowCharsInNumbers.isOn = mDefaults.bool(forKey: "phone-allow-chars")
        switchShowPicture.isOn = mDefaults.bool(forKey: "show-customer-picture")
        switchShowPhoneField.isOn = mDefaults.bool(forKey: "show-phone-field")
        switchShowEmailField.isOn = mDefaults.bool(forKey: "show-email-field")
        switchShowAddressField.isOn = mDefaults.bool(forKey: "show-address-field")
        switchShowGroupField.isOn = mDefaults.bool(forKey: "show-group-field")
        switchShowNoteField.isOn = mDefaults.bool(forKey: "show-note-field")
        switchShowNewsletterField.isOn = mDefaults.bool(forKey: "show-newsletter-field")
        switchShowBirthdayField.isOn = mDefaults.bool(forKey: "show-birthday-field")
        switchShowFiles.isOn = mDefaults.bool(forKey: "show-files")
        switchShowConsentField.isOn = mDefaults.bool(forKey: "show-consent-field")
        textFieldBirthdayPreviewDays.text = String(mDefaults.integer(forKey: "birthday-preview-days"))
        textFieldCurrency.text = mDefaults.string(forKey: "currency")
        mAppPassword = mDefaults.string(forKey: "iom-password") ?? ""
        sliderRed.isEnabled = mDefaults.bool(forKey: "unlocked-do")
        sliderGreen.isEnabled = mDefaults.bool(forKey: "unlocked-do")
        sliderBlue.isEnabled = mDefaults.bool(forKey: "unlocked-do")
        sliderRed.value = Float(mDefaults.integer(forKey: "color-red"))
        sliderGreen.value = Float(mDefaults.integer(forKey: "color-green"))
        sliderBlue.value = Float(mDefaults.integer(forKey: "color-blue"))
        mDefaultCustomerTitle = mDefaults.string(forKey: "default-customer-title") ?? ""
        mDefaultCustomerCity = mDefaults.string(forKey: "default-customer-city") ?? ""
        mDefaultCustomerCountry = mDefaults.string(forKey: "default-customer-country") ?? ""
        mDefaultCustomerGroup = mDefaults.string(forKey: "default-customer-group") ?? ""
        mEmailSubject = mDefaults.string(forKey: "email-subject") ?? ""
        mEmailTemplate = mDefaults.string(forKey: "email-template") ?? ""
        mNewsletterText = mDefaults.string(forKey: "email-newsletter-template") ?? ""
        mDefaultAppointmentTitle = mDefaults.string(forKey: "default-appointment-title") ?? ""
        mDefaultAppointmentLocation = mDefaults.string(forKey: "default-appointment-location") ?? ""
        
        updateColorPreview()
        onSyncModeChanged(segmentedControlSync)
        
        reloadCustomFields()
        reloadCalendars()
    }
    func saveSettings() -> Bool {
        mDefaults.set(segmentedControlSync.selectedSegmentIndex, forKey: "sync-mode")
        mDefaults.set(textFieldSyncUrl.text!, forKey: "sync-url")
        mDefaults.set(textFieldSyncUsername.text!, forKey: "sync-username")
        mDefaults.set(textFieldSyncPassword.text!, forKey: "sync-password")
        mDefaults.set(switchAllowCharsInNumbers.isOn, forKey: "phone-allow-chars")
        mDefaults.set(switchShowPicture.isOn, forKey: "show-customer-picture")
        mDefaults.set(switchShowPhoneField.isOn, forKey: "show-phone-field")
        mDefaults.set(switchShowEmailField.isOn, forKey: "show-email-field")
        mDefaults.set(switchShowAddressField.isOn, forKey: "show-address-field")
        mDefaults.set(switchShowGroupField.isOn, forKey: "show-group-field")
        mDefaults.set(switchShowNoteField.isOn, forKey: "show-note-field")
        mDefaults.set(switchShowNewsletterField.isOn, forKey: "show-newsletter-field")
        mDefaults.set(switchShowBirthdayField.isOn, forKey: "show-birthday-field")
        mDefaults.set(switchShowFiles.isOn, forKey: "show-files")
        mDefaults.set(switchShowConsentField.isOn, forKey: "show-consent-field")
        mDefaults.set(Int(textFieldBirthdayPreviewDays.text!), forKey: "birthday-preview-days")
        mDefaults.set(textFieldCurrency.text!, forKey: "currency")
        mDefaults.set(mAppPassword, forKey: "iom-password")
        mDefaults.set(Int(sliderRed.value), forKey: "color-red")
        mDefaults.set(Int(sliderGreen.value), forKey: "color-green")
        mDefaults.set(Int(sliderBlue.value), forKey: "color-blue")
        mDefaults.set(mDefaultCustomerTitle, forKey: "default-customer-title")
        mDefaults.set(mDefaultCustomerCity, forKey: "default-customer-city")
        mDefaults.set(mDefaultCustomerCountry, forKey: "default-customer-country")
        mDefaults.set(mDefaultCustomerGroup, forKey: "default-customer-group")
        mDefaults.set(mEmailSubject, forKey: "email-subject")
        mDefaults.set(mEmailTemplate, forKey: "email-template")
        mDefaults.set(mNewsletterText, forKey: "email-newsletter-template")
        mDefaults.set(mDefaultAppointmentTitle, forKey: "default-appointment-title")
        mDefaults.set(mDefaultAppointmentLocation, forKey: "default-appointment-location")
        
        if let msvc = presentingViewController as? MainSplitViewController {
            if let mnvc = msvc.viewControllers[0] as? MasterNavigationController {
                mnvc.setNavigationBarColor(UIColor.init(
                    red: CGFloat(sliderRed.value/255),
                    green: CGFloat(sliderGreen.value/255),
                    blue: CGFloat(sliderBlue.value/255),
                    alpha: 1
                ))
            }
        }
        
        return true
    }
    
    func reloadCustomFields() {
        var parsedData: [KeyValueItem] = []
        for field in mDb.getCustomFields() {
            parsedData.append(KeyValueItem(String(field.mId), field.mTitle))
        }
        mCustomFieldsController = PickerDataController(
            textField: textFieldCustomFields,
            data: parsedData,
            changed: { item in
                self.mCurrentCustomField = self.mDb.getCustomField(id: Int(item.key)!)
                self.reloadCustomField()
                self.reloadCustomFieldPresets()
            }
        )
        self.createPickerCustomFields(pickerDataController: self.mCustomFieldsController!, defaultValue: "")
        reloadCustomField()
    }
    func reloadCustomField() {
        stackViewCustomFieldPresets.isHidden = true
        if(self.mCurrentCustomField == nil) {
            textFieldCustomFields.text = ""
            buttonEditCustomField.isEnabled = false
            buttonRemoveCustomField.isEnabled = false
        } else {
            buttonEditCustomField.isEnabled = true
            buttonRemoveCustomField.isEnabled = true
            if(self.mCurrentCustomField?.mType == CustomField.TYPE.DROPDOWN) {
                stackViewCustomFieldPresets.isHidden = false
            }
        }
    }
    
    func reloadCustomFieldPresets() {
        var parsedData: [KeyValueItem] = []
        for field in mDb.getCustomFieldPresets(customFieldId: mCurrentCustomField!.mId) {
            parsedData.append(KeyValueItem(String(field.mId), field.mTitle))
        }
        mCustomFieldPresetsController = PickerDataController(
            textField: textFieldCustomFieldPresets,
            data: parsedData,
            changed: { item in
                self.mCurrentCustomFieldPreset = item
                self.reloadCustomFieldPreset()
            }
        )
        self.createPickerCustomFieldPresets(pickerDataController: self.mCustomFieldPresetsController!, defaultValue: "")
        reloadCustomFieldPreset()
    }
    func reloadCustomFieldPreset() {
        if(self.mCurrentCustomFieldPreset == nil) {
            self.textFieldCustomFieldPresets.text = ""
            self.buttonRemoveCustomFieldPreset.isEnabled = false
        } else {
            self.buttonRemoveCustomFieldPreset.isEnabled = true
        }
    }
    
    func reloadCalendars() {
        var parsedData: [KeyValueItem] = []
        for field in mDb.getCalendars(showDeleted: false) {
            parsedData.append(KeyValueItem(String(field.mId), field.mTitle))
        }
        mCalendarsController = PickerDataController(
            textField: textFieldCalendars,
            data: parsedData,
            changed: { item in
                self.mCurrentCalendar = self.mDb.getCalendar(id: Int64(item.key)!)
                self.reloadCalendar()
            }
        )
        self.createPickerCalendars(pickerDataController: self.mCalendarsController!, defaultValue: "")
        reloadCalendar()
    }
    func reloadCalendar() {
        if(self.mCurrentCalendar == nil) {
            textFieldCalendars.text = ""
            buttonEditCalendar.isEnabled = false
            buttonRemoveCalendar.isEnabled = false
        } else {
            buttonEditCalendar.isEnabled = true
            buttonRemoveCalendar.isEnabled = true
        }
    }
    
    func initDropDownStyle(textField:UITextField) {
        let imgViewForDropDown = UIImageView(frame: CGRect(x: 0, y: 0, width: 32, height: 48))
        imgViewForDropDown.image = UIImage(named: "expand_more")
        imgViewForDropDown.contentMode = .center
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 32, height: 48))
        paddingView.addSubview(imgViewForDropDown)
        paddingView.isUserInteractionEnabled = false
        
        textField.rightView = paddingView
        textField.rightViewMode = .always
    }
    
    @objc func keyboardWillShow(notification:NSNotification){
        // give room at the bottom of the scroll view, so it doesn't cover up anything the user needs to tap
        let userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        var contentInset:UIEdgeInsets = scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height
        scrollView.contentInset = contentInset
    }
    @objc func keyboardWillHide(notification:NSNotification){
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
    }
    
    @IBAction func onClickHelp(_ sender: UIBarButtonItem) {
        if let url = URL(string: SyncInfoViewController.HELP_URL) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func onClickCancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onClickDone(_ sender: UIBarButtonItem) {
        let lastUsername = mDefaults.string(forKey: "sync-username") ?? ""
        if(segmentedControlSync.selectedSegmentIndex != 0 && lastUsername != textFieldSyncUsername.text! && lastUsername != "") {
            
            let alert = UIAlertController(
                title: NSLocalizedString("sync_account_changed", comment: ""),
                message: NSLocalizedString("sync_account_changed_text", comment: ""),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("yes", comment: ""),
                style: .default) { (action) in
                    if(self.saveSettings()) {
                        self.mDefaults.set(0, forKey: "last-successful-sync")
                        self.mDb.deleteAllCustomers()
                        self.mDb.deleteAllVouchers()
                        self.mDb.deleteAllCalendars()
                        self.mDb.deleteAllAppointments()
                        if(self.mMainViewControllerRef != nil) {
                            self.mMainViewControllerRef!.reloadData()
                        }
                        self.dismiss(animated: true, completion: nil)
                    }
            })
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("no", comment: ""),
                style: .cancel) { (action) in
                    if(self.saveSettings()) {
                        self.dismiss(animated: true, completion: nil)
                    }
            })
            self.present(alert, animated: true)
            
        } else {
            if(saveSettings()) {
                dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func onSyncModeChanged(_ sender: UISegmentedControl) {
        labelSyncModeDesc.isHidden = true
        textFieldSyncUrl.isHidden = true
        textFieldSyncUsername.isHidden = true
        textFieldSyncPassword.isHidden = true
        if(sender.selectedSegmentIndex == 1) {
            textFieldSyncUsername.isHidden = false
            textFieldSyncPassword.isHidden = false
        }
        else if(sender.selectedSegmentIndex == 2) {
            textFieldSyncUrl.isHidden = false
            textFieldSyncUsername.isHidden = false
            textFieldSyncPassword.isHidden = false
        }
    }
    
    @IBAction func onClickSetPassword(_ sender: UIButton) {
        let alert = UIAlertController(title: NSLocalizedString("set_password", comment: ""), message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { (password1) in
            password1.text = ""
            password1.placeholder = NSLocalizedString("choose_a_password", comment: "")
            password1.isSecureTextEntry = true
        })
        alert.addTextField(configurationHandler: { (password2) in
            password2.text = ""
            password2.placeholder = NSLocalizedString("confirm_password", comment: "")
            password2.isSecureTextEntry = true
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { [weak alert] (_) in
            let password1 = alert?.textFields![0].text
            let password2 = alert?.textFields![1].text
            if(password1 != password2) {
                let alert2 = UIAlertController(
                    title: nil, message: NSLocalizedString("passwords_do_not_match", comment: ""), preferredStyle: .alert
                )
                alert2.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .cancel, handler: nil))
                self.present(alert2, animated: true, completion: nil)
            } else {
                self.mAppPassword = password1!
            }
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func onColorSliderChanged(_ sender: UISlider) {
        updateColorPreview()
    }
    @IBAction func onClickResetColor(_ sender: Any) {
        sliderRed.value = Float(SettingsViewController.DEFAULT_COLOR_R)
        sliderGreen.value = Float(SettingsViewController.DEFAULT_COLOR_G)
        sliderBlue.value = Float(SettingsViewController.DEFAULT_COLOR_B)
        updateColorPreview()
    }
    func updateColorPreview() {
        viewColorPreview.backgroundColor = UIColor.init(
            red: CGFloat(sliderRed.value/255),
            green: CGFloat(sliderGreen.value/255),
            blue: CGFloat(sliderBlue.value/255),
            alpha: 1
        )
    }
    
    var imagePicker = UIImagePickerController()
    @IBAction func onClickChooseLogo(_ sender: UIButton) {
        if(!mDefaults.bool(forKey: "unlocked-do")) {
            purchaseDialog()
            return
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false
            present(imagePicker, animated: true, completion: nil)
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            if let data = image.pngData() {
                try? data.write(to: SettingsViewController.getLogoFile())
            }
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    @IBAction func onClickRemoveLogo(_ sender: UIButton) {
        if(!mDefaults.bool(forKey: "unlocked-do")) {
            purchaseDialog()
            return
        }
        do {
            try FileManager.default.removeItem(at: SettingsViewController.getLogoFile())
            let alert = UIAlertController(
                title: nil,
                message: NSLocalizedString("logo_deleted", comment: ""),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("ok", comment: ""),
                style: .cancel) { (action) in
            })
            self.present(alert, animated: true)
        } catch let error as NSError {
            print("Delete Error: \(error.domain)")
        }
    }
    static func getLogoFile() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("logo.png")
    }
    
    let toolBar = UIToolbar()
    func createToolbar() {
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: NSLocalizedString("done", comment: ""), style: .plain, target: self, action: #selector(SettingsViewController.dismissKeyboard))
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
    }
    func createPickerCustomFields(pickerDataController: PickerDataController, defaultValue: String) {
        pickerDataController.textField?.text = ""
        mCurrentCustomField = nil
        let uiPicker = UIPickerView()
        uiPicker.delegate = pickerDataController
        pickerDataController.textField?.inputView = uiPicker
        pickerDataController.textField?.inputAccessoryView = toolBar
        if(pickerDataController.data.count > 0) {
            // select first item
            uiPicker.selectRow(0, inComponent: 0, animated: false)
            pickerDataController.textField?.text = pickerDataController.data[0].value
            mCurrentCustomField = mDb.getCustomField(id: Int(pickerDataController.data[0].key)!)
            // select given default if exists
            for i in 0...pickerDataController.data.count-1 {
                if(pickerDataController.data[i].key == defaultValue) {
                    uiPicker.selectRow(i, inComponent: 0, animated: false)
                    pickerDataController.textField?.text = pickerDataController.data[i].value
                    mCurrentCustomField = mDb.getCustomField(id: Int(pickerDataController.data[i].key)!)
                    break
                }
            }
            reloadCustomField()
        }
    }
    func createPickerCustomFieldPresets(pickerDataController: PickerDataController, defaultValue: String) {
        pickerDataController.textField?.text = ""
        mCurrentCustomFieldPreset = nil
        let uiPicker = UIPickerView()
        uiPicker.delegate = pickerDataController
        pickerDataController.textField?.inputView = uiPicker
        pickerDataController.textField?.inputAccessoryView = toolBar
        if(pickerDataController.data.count > 0) {
            // select first item
            uiPicker.selectRow(0, inComponent: 0, animated: false)
            pickerDataController.textField?.text = pickerDataController.data[0].value
            mCurrentCustomFieldPreset = pickerDataController.data[0]
            // select given default if exists
            for i in 0...pickerDataController.data.count-1 {
                if(pickerDataController.data[i].key == defaultValue) {
                    uiPicker.selectRow(i, inComponent: 0, animated: false)
                    pickerDataController.textField?.text = pickerDataController.data[i].value
                    mCurrentCustomFieldPreset = pickerDataController.data[i]
                    break
                }
            }
            reloadCustomFieldPreset()
        }
    }
    func createPickerCalendars(pickerDataController: PickerDataController, defaultValue: String) {
        pickerDataController.textField?.text = ""
        mCurrentCalendar = nil
        let uiPicker = UIPickerView()
        uiPicker.delegate = pickerDataController
        pickerDataController.textField?.inputView = uiPicker
        pickerDataController.textField?.inputAccessoryView = toolBar
        if(pickerDataController.data.count > 0) {
            // select first item
            uiPicker.selectRow(0, inComponent: 0, animated: false)
            pickerDataController.textField?.text = pickerDataController.data[0].value
            mCurrentCalendar = mDb.getCalendar(id: Int64(pickerDataController.data[0].key)!)
            // select given default if exists
            for i in 0...pickerDataController.data.count-1 {
                if(pickerDataController.data[i].key == defaultValue) {
                    uiPicker.selectRow(i, inComponent: 0, animated: false)
                    pickerDataController.textField?.text = pickerDataController.data[i].value
                    mCurrentCalendar = mDb.getCalendar(id: Int64(pickerDataController.data[i].key)!)
                    break
                }
            }
            reloadCalendar()
        }
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func purchaseDialog() {
        let alert = UIAlertController(
            title: NSLocalizedString("not_unlocked", comment: ""),
            message: NSLocalizedString("unlock_feature_via_inapp", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("more", comment: ""),
            style: .default) { (action) in
                self.performSegue(withIdentifier: "segueInfo", sender: nil)
        })
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("close", comment: ""),
            style: .cancel) { (action) in
        })
        self.present(alert, animated: true)
    }
    
    var mDefaultCustomerTitle = ""
    var mDefaultCustomerCity = ""
    var mDefaultCustomerCountry = ""
    var mDefaultCustomerGroup = ""
    var mEmailSubject = ""
    var mEmailTemplate = ""
    var mNewsletterText = ""
    var mDefaultAppointmentTitle = ""
    var mDefaultAppointmentLocation = ""
    @IBAction func onClickChangeDefaultCustomerTitle(_ sender: UIButton) {
        inputBox(title: NSLocalizedString("change_text_template", comment: ""), defaultText: mDefaultCustomerTitle, callback: { newText in
            if(newText != nil) { self.mDefaultCustomerTitle = newText! }
        })
    }
    @IBAction func onClickChangeDefaultCustomerCity(_ sender: UIButton) {
        inputBox(title: NSLocalizedString("change_text_template", comment: ""), defaultText: mDefaultCustomerCity, callback: { newText in
            if(newText != nil) { self.mDefaultCustomerCity = newText! }
        })
    }
    @IBAction func onClickChangeDefaultCustomerCountry(_ sender: UIButton) {
        inputBox(title: NSLocalizedString("change_text_template", comment: ""), defaultText: mDefaultCustomerCountry, callback: { newText in
            if(newText != nil) { self.mDefaultCustomerCountry = newText! }
        })
    }
    @IBAction func onClickChangeDefaultCustomerGroup(_ sender: UIButton) {
        inputBox(title: NSLocalizedString("change_text_template", comment: ""), defaultText: mDefaultCustomerGroup, callback: { newText in
            if(newText != nil) { self.mDefaultCustomerGroup = newText! }
        })
    }
    @IBAction func onClickChangeEmailSubject(_ sender: UIButton) {
        inputBox(title: NSLocalizedString("change_text_template", comment: ""), defaultText: mEmailSubject, callback: { newText in
            if(newText != nil) { self.mEmailSubject = newText! }
        })
    }
    @IBAction func onClickChangeEmailTemplate(_ sender: UIButton) {
        inputBox(title: NSLocalizedString("change_text_template", comment: ""), defaultText: mEmailTemplate, callback: { newText in
            if(newText != nil) { self.mEmailTemplate = newText! }
        })
    }
    @IBAction func onClickChangeNewsletterText(_ sender: UIButton) {
        inputBox(title: NSLocalizedString("change_text_template", comment: ""), defaultText: mNewsletterText, callback: { newText in
            if(newText != nil) { self.mNewsletterText = newText! }
        })
    }
    @IBAction func onClickChangeAppointmentTitle(_ sender: UIButton) {
        inputBox(title: NSLocalizedString("change_text_template", comment: ""), defaultText: mDefaultAppointmentTitle, callback: { newText in
            if(newText != nil) { self.mDefaultAppointmentTitle = newText! }
        })
    }
    @IBAction func onClickChangeAppointmentLocation(_ sender: UIButton) {
        inputBox(title: NSLocalizedString("change_text_template", comment: ""), defaultText: mDefaultAppointmentLocation, callback: { newText in
            if(newText != nil) { self.mDefaultAppointmentLocation = newText! }
        })
    }
    
    func messageBox(title: String, text: String) {
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    func inputBox(title: String, defaultText: String, callback: @escaping (String?)->()) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { (textField) -> Void in
            textField.text = defaultText
        })
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { [weak alert] (action) -> Void in
            let textField = (alert?.textFields![0])! as UITextField
            callback(textField.text)
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: { (action) -> Void in
            callback(nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    var mFieldTypePickerController:FieldTypePickerController? = nil
    @IBAction func onClickAddCustomField(_ sender: UIButton) {
        if(!mDefaults.bool(forKey: "unlocked-cf")) {
            purchaseDialog()
            return
        }
        
        self.mFieldTypePickerController = FieldTypePickerController()
        let vc = UIViewController()
        vc.preferredContentSize = CGSize(width: 250, height: 300)
        let pickerView = UIPickerView(frame: CGRect(x: 0, y: 30, width: 250, height: 270))
        pickerView.delegate = self.mFieldTypePickerController
        pickerView.dataSource = self.mFieldTypePickerController
        let textField = UITextField(frame: CGRect(x: 0, y: 0, width: 250, height: 30))
        textField.placeholder = NSLocalizedString("field_description", comment: "")
        textField.borderStyle = .roundedRect
        textField.delegate = self
        textField.becomeFirstResponder()
        if #available(iOS 11.0, *) {
            textField.smartInsertDeleteType = .no
        }
        vc.view.addSubview(textField)
        vc.view.addSubview(pickerView)
        let alert = UIAlertController(title: NSLocalizedString("new_custom_field", comment: ""), message: nil, preferredStyle: UIAlertController.Style.alert)
        alert.setValue(vc, forKey: "contentViewController")
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { (_) in
            if(textField.text == nil || textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                self.messageBox(title: NSLocalizedString("error", comment: ""), text: NSLocalizedString("name_cannot_be_empty", comment: ""))
                return
            }
            let typeString = self.mFieldTypePickerController!.mTypes[pickerView.selectedRow(inComponent: 0)]
            if(typeString == "field_alphanumeric") {
                self.addCustomField(title: textField.text!, type: CustomField.TYPE.TEXT)
            }
            else if(typeString == "field_alphanumeric_multiline") {
                self.addCustomField(title: textField.text!, type: CustomField.TYPE.TEXT_MULTILINE)
            }
            else if(typeString == "field_numeric") {
                self.addCustomField(title: textField.text!, type: CustomField.TYPE.NUMBER)
            }
            else if(typeString == "field_drop_down") {
                self.addCustomField(title: textField.text!, type: CustomField.TYPE.DROPDOWN)
            }
            else if(typeString == "field_date") {
                self.addCustomField(title: textField.text!, type: CustomField.TYPE.DATE)
            }
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    @IBAction func onClickEditCustomField(_ sender: UIButton) {
        if(mCurrentCustomField == nil) { return }
        let prevFieldId = mCurrentCustomField!.mId
        let prevFieldTitle = mCurrentCustomField!.mTitle
        
        self.mFieldTypePickerController = FieldTypePickerController()
        let vc = UIViewController()
        vc.preferredContentSize = CGSize(width: 250, height: 300)
        let pickerView = UIPickerView(frame: CGRect(x: 0, y: 30, width: 250, height: 270))
        pickerView.delegate = self.mFieldTypePickerController
        pickerView.dataSource = self.mFieldTypePickerController
        if(mCurrentCustomField!.mType == CustomField.TYPE.TEXT) {
            pickerView.selectRow(0, inComponent: 0, animated: false)
        } else if(mCurrentCustomField!.mType == CustomField.TYPE.TEXT_MULTILINE) {
            pickerView.selectRow(1, inComponent: 0, animated: false)
        } else if(mCurrentCustomField!.mType == CustomField.TYPE.NUMBER) {
            pickerView.selectRow(2, inComponent: 0, animated: false)
        } else if(mCurrentCustomField!.mType == CustomField.TYPE.DROPDOWN) {
            pickerView.selectRow(3, inComponent: 0, animated: false)
        } else if(mCurrentCustomField!.mType == CustomField.TYPE.DATE) {
           pickerView.selectRow(4, inComponent: 0, animated: false)
        }
        let textField = UITextField(frame: CGRect(x: 0, y: 0, width: 250, height: 30))
        textField.text = prevFieldTitle
        textField.placeholder = NSLocalizedString("field_description", comment: "")
        textField.borderStyle = .roundedRect
        textField.delegate = self
        textField.becomeFirstResponder()
        if #available(iOS 11.0, *) {
            textField.smartInsertDeleteType = .no
        }
        vc.view.addSubview(textField)
        vc.view.addSubview(pickerView)
        let alert = UIAlertController(title: NSLocalizedString("edit_custom_field", comment: ""), message: nil, preferredStyle: UIAlertController.Style.alert)
        alert.setValue(vc, forKey: "contentViewController")
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { (_) in
            if(textField.text == nil || textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                self.messageBox(title: NSLocalizedString("error", comment: ""), text: NSLocalizedString("name_cannot_be_empty", comment: ""))
                return
            }
            let newFieldTitle = textField.text!
            // rebase custom fields
            if(textField.text != prevFieldTitle) {
                for customer in self.mDb.getCustomers(search: nil, showDeleted: false, withFiles: false) {
                    var fields = customer.getCustomFields()
                    for (index, field) in fields.enumerated() {
                        if field.mTitle == prevFieldTitle {
                            fields.append(CustomField(title: newFieldTitle, value: field.mValue))
                            fields.remove(at: index)
                            customer.setCustomFields(fields: fields)
                            customer.mLastModified = Date()
                            _ = self.mDb.updateCustomer(c: customer)
                            break
                        }
                    }
                }
            }
            let typeString = self.mFieldTypePickerController!.mTypes[pickerView.selectedRow(inComponent: 0)]
            if(typeString == "field_alphanumeric") {
                _ = self.mDb.updateCustomField(cf: CustomField(id: prevFieldId, title: newFieldTitle, type: CustomField.TYPE.TEXT))
            }
            else if(typeString == "field_alphanumeric_multiline") {
                _ = self.mDb.updateCustomField(cf: CustomField(id: prevFieldId, title: newFieldTitle, type: CustomField.TYPE.TEXT_MULTILINE))
            }
            else if(typeString == "field_numeric") {
                _ = self.mDb.updateCustomField(cf: CustomField(id: prevFieldId, title: newFieldTitle, type: CustomField.TYPE.NUMBER))
            }
            else if(typeString == "field_drop_down") {
                _ = self.mDb.updateCustomField(cf: CustomField(id: prevFieldId, title: newFieldTitle, type: CustomField.TYPE.DROPDOWN))
            }
            else if(typeString == "field_date") {
                _ = self.mDb.updateCustomField(cf: CustomField(id: prevFieldId, title: newFieldTitle, type: CustomField.TYPE.DATE))
            }
            self.reloadCustomFields()
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }
    @IBAction func onClickRemoveCustomField(_ sender: UIButton) {
        if(mCurrentCustomField != nil) {
            let alert = UIAlertController(
                title: NSLocalizedString("are_you_sure", comment: ""),
                message: mCurrentCustomField!.mTitle,
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: NSLocalizedString("delete", comment: ""), style: .destructive, handler: { (_) in
                self.mDb.removeCustomField(id: self.mCurrentCustomField!.mId)
                self.reloadCustomFields()
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    func addCustomField(title:String, type:Int) {
        if(title != "") {
            _ = self.mDb.insertCustomField(cf: CustomField(id: -1, title: title, type: type))
            reloadCustomFields()
        }
    }
    
    @IBAction func onClickAddCustomFieldPreset(_ sender: UIButton) {
        if(mCurrentCustomField == nil) { return }
        inputBox(title: NSLocalizedString("add_drop_down_value", comment: ""), defaultText: "", callback: { newText in
            if(newText == nil) { // cancel pressed
                return
            }
            _ = self.mDb.insertCustomFieldPreset(
                fieldId: self.mCurrentCustomField!.mId, preset: newText!
            )
            self.reloadCustomFieldPresets()
        })
    }
    @IBAction func onClickRemoveCustomFieldPreset(_ sender: UIButton) {
        if(mCurrentCustomFieldPreset != nil) {
            let alert = UIAlertController(
                title: NSLocalizedString("are_you_sure", comment: ""),
                message: mCurrentCustomFieldPreset!.value,
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: NSLocalizedString("delete", comment: ""), style: .destructive, handler: { (_) in
                self.mDb.removeCustomFieldPreset(id: Int64(self.mCurrentCustomFieldPreset!.key)!)
                self.reloadCustomFieldPresets()
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    var mCurrentCalendarTextField:UITextField? = nil
    var mCurrentCalendarSliderRed:UISlider? = nil
    var mCurrentCalendarSliderGreen:UISlider? = nil
    var mCurrentCalendarSliderBlue:UISlider? = nil
    var mCurrentCalendarColorPreview:UIView? = nil
    func createCalendarAlert(edit: Bool) -> UIAlertController {
        let vc = UIViewController()
        vc.preferredContentSize = CGSize(width: 250, height: 150)
        
        mCurrentCalendarTextField = UITextField()
        mCurrentCalendarTextField!.placeholder = NSLocalizedString("name", comment: "")
        mCurrentCalendarTextField!.borderStyle = .roundedRect
        mCurrentCalendarTextField!.delegate = self
        mCurrentCalendarTextField!.becomeFirstResponder()
        if #available(iOS 11.0, *) {
            mCurrentCalendarTextField!.smartInsertDeleteType = .no
        }
        
        let stackViewRed = UIStackView()
        stackViewRed.spacing = 5
        stackViewRed.axis = .horizontal
        let labelRed = UILabel()
        labelRed.text = NSLocalizedString("red", comment: "")
        stackViewRed.addArrangedSubview(labelRed)
        mCurrentCalendarSliderRed = UISlider()
        mCurrentCalendarSliderRed!.maximumValue = 255
        mCurrentCalendarSliderRed!.value = 200
        mCurrentCalendarSliderRed!.addTarget(self, action: #selector(refreshCalendarColorPreview), for: .valueChanged)
        stackViewRed.addArrangedSubview(mCurrentCalendarSliderRed!)
        
        let stackViewGreen = UIStackView()
        stackViewGreen.spacing = 5
        stackViewGreen.axis = .horizontal
        let labelGreen = UILabel()
        labelGreen.text = NSLocalizedString("green", comment: "")
        stackViewGreen.addArrangedSubview(labelGreen)
        mCurrentCalendarSliderGreen = UISlider()
        mCurrentCalendarSliderGreen!.maximumValue = 255
        mCurrentCalendarSliderGreen!.value = 200
        mCurrentCalendarSliderGreen!.addTarget(self, action: #selector(refreshCalendarColorPreview), for: .valueChanged)
        stackViewGreen.addArrangedSubview(mCurrentCalendarSliderGreen!)
        
        let stackViewBlue = UIStackView()
        stackViewBlue.spacing = 5
        stackViewBlue.axis = .horizontal
        let labelBlue = UILabel()
        labelBlue.text = NSLocalizedString("blue", comment: "")
        stackViewBlue.addArrangedSubview(labelBlue)
        mCurrentCalendarSliderBlue = UISlider()
        mCurrentCalendarSliderBlue!.maximumValue = 255
        mCurrentCalendarSliderBlue!.value = 200
        mCurrentCalendarSliderBlue!.addTarget(self, action: #selector(refreshCalendarColorPreview), for: .valueChanged)
        stackViewBlue.addArrangedSubview(mCurrentCalendarSliderBlue!)
        
        let stackViewColorsInner = UIStackView()
        stackViewColorsInner.axis = .vertical
        stackViewColorsInner.addArrangedSubview(stackViewRed)
        stackViewColorsInner.addArrangedSubview(stackViewGreen)
        stackViewColorsInner.addArrangedSubview(stackViewBlue)
        
        mCurrentCalendarColorPreview = UIView()
        mCurrentCalendarColorPreview!.backgroundColor = UIColor.blue
        NSLayoutConstraint.activate([
            mCurrentCalendarColorPreview!.widthAnchor.constraint(equalToConstant: 30),
            mCurrentCalendarSliderRed!.widthAnchor.constraint(equalTo: mCurrentCalendarSliderGreen!.widthAnchor),
            mCurrentCalendarSliderGreen!.widthAnchor.constraint(equalTo: mCurrentCalendarSliderBlue!.widthAnchor)
        ])
        
        let stackViewColorsOuter = UIStackView()
        stackViewColorsOuter.axis = .horizontal
        stackViewColorsOuter.distribution = .fill
        stackViewColorsOuter.setContentHuggingPriority(.defaultLow, for: .vertical)
        stackViewColorsOuter.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        stackViewColorsOuter.addArrangedSubview(stackViewColorsInner)
        stackViewColorsOuter.addArrangedSubview(mCurrentCalendarColorPreview!)
        
        let stackView = UIStackView()
        stackView.frame.size = vc.preferredContentSize
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = 5
        stackView.addArrangedSubview(mCurrentCalendarTextField!)
        stackView.addArrangedSubview(stackViewColorsOuter)
        stackView.addArrangedSubview(UIView())
        
        vc.view.addSubview(stackView)
        let alert = UIAlertController(
            title: NSLocalizedString(edit ? "edit_calendar" : "new_calendar", comment: ""),
            message: nil, preferredStyle: UIAlertController.Style.alert
        )
        alert.setValue(vc, forKey: "contentViewController")
        return alert
    }
    @objc func refreshCalendarColorPreview() {
           mCurrentCalendarColorPreview?.backgroundColor = UIColor(
               red: CGFloat(self.mCurrentCalendarSliderRed!.value / 255),
               green: CGFloat(self.mCurrentCalendarSliderGreen!.value / 255),
               blue: CGFloat(self.mCurrentCalendarSliderBlue!.value / 255),
               alpha: 1
           )
    }
    @IBAction func onClickAddCalendar(_ sender: UIButton) {
        if(!mDefaults.bool(forKey: "unlocked-cl")) {
            purchaseDialog()
            return
        }
        
        let alert = createCalendarAlert(edit: false)
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { (_) in
            if(self.mCurrentCalendarTextField!.text == nil || self.mCurrentCalendarTextField!.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                self.messageBox(title: NSLocalizedString("error", comment: ""), text: NSLocalizedString("name_cannot_be_empty", comment: ""))
                return
            }
            let c = CustomerCalendar()
            c.mId = CustomerCalendar.generateID()
            c.mTitle = self.mCurrentCalendarTextField!.text!
            c.mColor = UIColor(
                red: CGFloat(self.mCurrentCalendarSliderRed!.value / 255),
                green: CGFloat(self.mCurrentCalendarSliderGreen!.value / 255),
                blue: CGFloat(self.mCurrentCalendarSliderBlue!.value / 255),
                alpha: 1
            ).toHexString()
            _ = self.mDb.insertCalendar(c: c)
            self.reloadCalendars()
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        self.present(alert, animated: true)
        refreshCalendarColorPreview()
    }
    @IBAction func onClickEditCalendar(_ sender: UIButton) {
        let alert = createCalendarAlert(edit: true)
        mCurrentCalendarTextField?.text = mCurrentCalendar?.mTitle
        mCurrentCalendarSliderRed?.value = Float(UIColor(hex: mCurrentCalendar!.mColor).red()) * 255
        mCurrentCalendarSliderGreen?.value = Float(UIColor(hex: mCurrentCalendar!.mColor).green()) * 255
        mCurrentCalendarSliderBlue?.value = Float(UIColor(hex: mCurrentCalendar!.mColor).blue()) * 255
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { (_) in
            if(self.mCurrentCalendarTextField!.text == nil || self.mCurrentCalendarTextField!.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "") {
                self.messageBox(title: NSLocalizedString("error", comment: ""), text: NSLocalizedString("name_cannot_be_empty", comment: ""))
                return
            }
            self.mCurrentCalendar!.mTitle = self.mCurrentCalendarTextField!.text!
            self.mCurrentCalendar!.mColor = UIColor(
                red: CGFloat(self.mCurrentCalendarSliderRed!.value / 255),
                green: CGFloat(self.mCurrentCalendarSliderGreen!.value / 255),
                blue: CGFloat(self.mCurrentCalendarSliderBlue!.value / 255),
                alpha: 1
            ).toHexString()
            self.mCurrentCalendar!.mLastModified = Date()
            _ = self.mDb.updateCalendar(c: self.mCurrentCalendar!)
            self.reloadCalendars()
        }))
        alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
        self.present(alert, animated: true)
        refreshCalendarColorPreview()
    }
    @IBAction func onClickRemoveCalendar(_ sender: UIButton) {
        if(mCurrentCalendar != nil) {
            let alert = UIAlertController(
                title: NSLocalizedString("are_you_sure", comment: ""),
                message: mCurrentCalendar!.mTitle,
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("cancel", comment: ""), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: NSLocalizedString("delete", comment: ""), style: .destructive, handler: { (_) in
                self.mDb.removeCalendar(id: self.mCurrentCalendar!.mId)
                self.reloadCalendars()
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // text field max length
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let textFieldText = textField.text,
            let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + string.count
        return count <= 20
    }
    
}
