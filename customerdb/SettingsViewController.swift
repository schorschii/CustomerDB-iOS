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
    @IBOutlet weak var switchShowPhoneField: UISwitch!
    @IBOutlet weak var switchShowEmailField: UISwitch!
    @IBOutlet weak var switchShowAddressField: UISwitch!
    @IBOutlet weak var switchShowGroupField: UISwitch!
    @IBOutlet weak var switchShowNoteField: UISwitch!
    @IBOutlet weak var switchShowNewsletterField: UISwitch!
    @IBOutlet weak var switchShowBirthdayField: UISwitch!
    @IBOutlet weak var switchShowConsentField: UISwitch!
    @IBOutlet weak var textFieldCurrency: UITextField!
    @IBOutlet weak var textFieldAppPassword: UITextField!
    @IBOutlet weak var textFieldAppPasswordConfirm: UITextField!
    @IBOutlet weak var sliderRed: UISlider!
    @IBOutlet weak var sliderGreen: UISlider!
    @IBOutlet weak var sliderBlue: UISlider!
    @IBOutlet weak var viewColorPreview: UIView!
    @IBOutlet weak var textFieldCustomFields: UITextField!
    @IBOutlet weak var buttonChooseLogo: UIButton!
    @IBOutlet weak var buttonRemoveLogo: UIButton!
    @IBOutlet weak var buttonEditCustomField: UIButton!
    @IBOutlet weak var buttonRemoveCustomField: UIButton!
    
    static var DEFAULT_COLOR_R = 15
    static var DEFAULT_COLOR_G = 124
    static var DEFAULT_COLOR_B = 157
    
    let mDefaults = UserDefaults.standard
    let mDb = CustomerDatabase()
    
    var mMainViewControllerRef: MainViewController? = nil
    
    var mCustomFieldsController: PickerDataController? = nil
    var mCurrentCustomField: CustomField? = nil
    
    override func viewDidLoad() {
        navigationController?.navigationBar.barStyle = .default
        initDropDownStyle()
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
        switchShowPhoneField.isOn = mDefaults.bool(forKey: "show-phone-field")
        switchShowEmailField.isOn = mDefaults.bool(forKey: "show-email-field")
        switchShowAddressField.isOn = mDefaults.bool(forKey: "show-address-field")
        switchShowGroupField.isOn = mDefaults.bool(forKey: "show-group-field")
        switchShowNoteField.isOn = mDefaults.bool(forKey: "show-note-field")
        switchShowNewsletterField.isOn = mDefaults.bool(forKey: "show-newsletter-field")
        switchShowBirthdayField.isOn = mDefaults.bool(forKey: "show-birthday-field")
        switchShowConsentField.isOn = mDefaults.bool(forKey: "show-consent-field")
        textFieldCurrency.text = mDefaults.string(forKey: "currency")
        textFieldAppPassword.text = mDefaults.string(forKey: "iom-password")
        textFieldAppPasswordConfirm.text = mDefaults.string(forKey: "iom-password")
        sliderRed.isEnabled = mDefaults.bool(forKey: "unlocked-do")
        sliderGreen.isEnabled = mDefaults.bool(forKey: "unlocked-do")
        sliderBlue.isEnabled = mDefaults.bool(forKey: "unlocked-do")
        sliderRed.value = Float(mDefaults.integer(forKey: "color-red"))
        sliderGreen.value = Float(mDefaults.integer(forKey: "color-green"))
        sliderBlue.value = Float(mDefaults.integer(forKey: "color-blue"))
        
        updateColorPreview()
        onSyncModeChanged(segmentedControlSync)
        
        reloadCustomFields()
    }
    func saveSettings() -> Bool {
        if(textFieldAppPassword.text != textFieldAppPasswordConfirm.text) {
            let alert = UIAlertController(
                title: NSLocalizedString("passwords_do_not_match", comment: ""),
                message: NSLocalizedString("settings_were_not_saved", comment: ""),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("ok", comment: ""),
                style: .cancel) { (action) in
            })
            dismissKeyboard()
            self.present(alert, animated: true)
            return false
        }
        
        mDefaults.set(segmentedControlSync.selectedSegmentIndex, forKey: "sync-mode")
        mDefaults.set(textFieldSyncUrl.text!, forKey: "sync-url")
        mDefaults.set(textFieldSyncUsername.text!, forKey: "sync-username")
        mDefaults.set(textFieldSyncPassword.text!, forKey: "sync-password")
        mDefaults.set(switchAllowCharsInNumbers.isOn, forKey: "phone-allow-chars")
        mDefaults.set(switchShowPhoneField.isOn, forKey: "show-phone-field")
        mDefaults.set(switchShowEmailField.isOn, forKey: "show-email-field")
        mDefaults.set(switchShowAddressField.isOn, forKey: "show-address-field")
        mDefaults.set(switchShowGroupField.isOn, forKey: "show-group-field")
        mDefaults.set(switchShowNoteField.isOn, forKey: "show-note-field")
        mDefaults.set(switchShowNewsletterField.isOn, forKey: "show-newsletter-field")
        mDefaults.set(switchShowBirthdayField.isOn, forKey: "show-birthday-field")
        mDefaults.set(switchShowConsentField.isOn, forKey: "show-consent-field")
        mDefaults.set(textFieldCurrency.text!, forKey: "currency")
        mDefaults.set(textFieldAppPassword.text!, forKey: "iom-password")
        mDefaults.set(Int(sliderRed.value), forKey: "color-red")
        mDefaults.set(Int(sliderGreen.value), forKey: "color-green")
        mDefaults.set(Int(sliderBlue.value), forKey: "color-blue")

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
            }
        )
        self.createPicker(pickerDataController: self.mCustomFieldsController!, defaultValue: "")
        reloadCustomField()
    }
    func reloadCustomField() {
        if(self.mCurrentCustomField == nil) {
            textFieldCustomFields.text = ""
            buttonEditCustomField.isEnabled = false
            buttonRemoveCustomField.isEnabled = false
        } else {
            buttonEditCustomField.isEnabled = true
            self.buttonRemoveCustomField.isEnabled = true
        }
    }
    
    func initDropDownStyle() {
        let imgViewForDropDown = UIImageView()
        imgViewForDropDown.frame = CGRect(x: 0, y: 0, width: 30, height: 48)
        imgViewForDropDown.image = UIImage(named: "baseline_arrow_drop_down_circle_black_24pt")
        textFieldCustomFields.rightView = imgViewForDropDown
        textFieldCustomFields.rightViewMode = .always
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
                        self.mDb.deleteAllCustomer()
                        self.mDb.deleteAllVoucher()
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
    func createPicker(pickerDataController: PickerDataController, defaultValue: String) {
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
            if(textField.text == nil || textField.text == "") {
                return
            }
            let typeString = self.mFieldTypePickerController!.mTypes[self.mFieldTypePickerController!.mSelected]
            if(typeString == "field_alphanumeric") {
                self.addCustomField(title: textField.text!, type: CustomField.TYPE.TEXT)
            }
            else if(typeString == "field_alphanumeric_multiline") {
                self.addCustomField(title: textField.text!, type: CustomField.TYPE.TEXT_MULTILINE)
            }
            else if(typeString == "field_numeric") {
                self.addCustomField(title: textField.text!, type: CustomField.TYPE.NUMBER)
            }
            else if(typeString == "field_dropdown") {
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
        let alert = UIAlertController(title: NSLocalizedString("new_custom_field", comment: ""), message: nil, preferredStyle: UIAlertController.Style.alert)
        alert.setValue(vc, forKey: "contentViewController")
        alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: { (_) in
            if(textField.text == nil || textField.text == "") {
                return
            }
            let newFieldTitle = textField.text!
            // rebase custom fields
            if(textField.text != prevFieldTitle) {
                for customer in self.mDb.getCustomers(showDeleted: false) {
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
            let typeString = self.mFieldTypePickerController!.mTypes[self.mFieldTypePickerController!.mSelected]
            if(typeString == "field_alphanumeric") {
                _ = self.mDb.updateCustomField(cf: CustomField(id: prevFieldId, title: newFieldTitle, type: CustomField.TYPE.TEXT))
            }
            else if(typeString == "field_alphanumeric_multiline") {
                _ = self.mDb.updateCustomField(cf: CustomField(id: prevFieldId, title: newFieldTitle, type: CustomField.TYPE.TEXT_MULTILINE))
            }
            else if(typeString == "field_numeric") {
                _ = self.mDb.updateCustomField(cf: CustomField(id: prevFieldId, title: newFieldTitle, type: CustomField.TYPE.NUMBER))
            }
            else if(typeString == "field_dropdown") {
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
                message: "",
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
