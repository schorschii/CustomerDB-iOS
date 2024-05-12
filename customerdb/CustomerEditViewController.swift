//
//  CustomerEditViewController.swift
//  Copyright © 2019 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit
import UniformTypeIdentifiers

class CustomerEditViewController : UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIDocumentPickerDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackViewImage: UIStackView!
    @IBOutlet weak var imageViewImage: UIImageView!
    @IBOutlet weak var textFieldTitle: UITextField!
    @IBOutlet weak var textFieldFirstName: UITextField!
    @IBOutlet weak var textFieldLastName: UITextField!
    @IBOutlet weak var textFieldPhoneHome: UITextField!
    @IBOutlet weak var textFieldPhoneMobile: UITextField!
    @IBOutlet weak var textFieldPhoneWork: UITextField!
    @IBOutlet weak var textFieldEmail: UITextField!
    @IBOutlet weak var textViewStreet: UITextView!
    @IBOutlet weak var textFieldZipcode: UITextField!
    @IBOutlet weak var textFieldCity: UITextField!
    @IBOutlet weak var textFieldCountry: UITextField!
    @IBOutlet weak var textFieldGroup: UITextField!
    @IBOutlet weak var textViewNotes: UITextView!
    @IBOutlet weak var switchNewsletter: UISwitch!
    @IBOutlet weak var switchConsent: UISwitch!
    @IBOutlet weak var textFieldBirthday: UITextField!
    @IBOutlet weak var stackViewAttributes: UIStackView!
    @IBOutlet weak var stackViewFiles: UIStackView!
    @IBOutlet weak var stackViewConsent: UIStackView!
    @IBOutlet weak var stackViewContact: UIStackView!
    @IBOutlet weak var stackViewAddress: UIStackView!
    @IBOutlet weak var stackViewGroup: UIStackView!
    @IBOutlet weak var stackViewNotes: UIStackView!
    @IBOutlet weak var stackViewNewsletter: UIStackView!
    @IBOutlet weak var stackViewBirthday: UIStackView!
    @IBOutlet weak var stackViewFilesContainer: UIStackView!
    @IBOutlet weak var buttonAddFile: UIButton!
    
    let mDb = CustomerDatabase()
    
    var mCurrentCustomer:Customer? = nil
    var mDisplayAttributes:[CustomField] = []
    var mIsNewCustomer = true
    var mCurrentCustomerImage:Data? = nil
    var mCurrentCustomerBirthday:Date? = nil
    var mIsInputOnlyModeActive = false
    
    override func viewDidLoad() {
        if(splitViewController!.isCollapsed ||
            (!splitViewController!.isCollapsed && mCurrentCustomer != nil)) {
            navigationItem.leftBarButtonItem = nil
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
        
        if(UserDefaults.standard.bool(forKey: "phone-allow-chars")) {
            textFieldPhoneHome.keyboardType = .default
            textFieldPhoneMobile.keyboardType = .default
            textFieldPhoneWork.keyboardType = .default
        }
        if(UserDefaults.standard.bool(forKey: "iom") && UserDefaults.standard.bool(forKey: "show-consent-field")) {
            mIsInputOnlyModeActive = true
            stackViewConsent.isHidden = false
        }
        if(!UserDefaults.standard.bool(forKey: "show-customer-picture")) {
            stackViewImage.isHidden = true
        }
        if(!UserDefaults.standard.bool(forKey: "show-phone-field")) {
            textFieldPhoneHome.isHidden = true
            textFieldPhoneMobile.isHidden = true
            textFieldPhoneWork.isHidden = true
        }
        if(!UserDefaults.standard.bool(forKey: "show-email-field")) {
            textFieldEmail.isHidden = true
        }
        if(!UserDefaults.standard.bool(forKey: "show-phone-field") && !UserDefaults.standard.bool(forKey: "show-email-field")) {
            stackViewContact.isHidden = true
        }
        if(!UserDefaults.standard.bool(forKey: "show-address-field")) {
            stackViewAddress.isHidden = true
        }
        if(!UserDefaults.standard.bool(forKey: "show-group-field")) {
            stackViewGroup.isHidden = true
        }
        if(!UserDefaults.standard.bool(forKey: "show-note-field")) {
            stackViewNotes.isHidden = true
        }
        if(!UserDefaults.standard.bool(forKey: "show-newsletter-field")) {
            stackViewNewsletter.isHidden = true
        }
        if(!UserDefaults.standard.bool(forKey: "show-birthday-field")) {
            stackViewBirthday.isHidden = true
        }
        if(!UserDefaults.standard.bool(forKey: "show-files")) {
            stackViewFilesContainer.isHidden = true
        }
        
        // load default values
        textFieldTitle.text = UserDefaults.standard.string(forKey: "default-customer-title") ?? ""
        textFieldCity.text = UserDefaults.standard.string(forKey: "default-customer-city") ?? ""
        textFieldCountry.text = UserDefaults.standard.string(forKey: "default-customer-country") ?? ""
        textFieldGroup.text = UserDefaults.standard.string(forKey: "default-customer-group") ?? ""
        
        GuiHelper.adjustTextviewStyle(control: textViewStreet, viewController: self)
        GuiHelper.adjustTextviewStyle(control: textViewNotes, viewController: self)
        
        // birthday date picker view
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: NSLocalizedString("done", comment: ""), style: .plain, target: self, action: #selector(CustomerEditViewController.dismissKeyboard))
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        let datePickerView = UIDatePicker()
        datePickerView.datePickerMode = .date
        if #available(iOS 13.4, *) {
            datePickerView.preferredDatePickerStyle = .wheels
        }
        textFieldBirthday.inputAccessoryView = toolBar
        textFieldBirthday.inputView = datePickerView
        if let bday = mCurrentCustomer?.mBirthday {
            datePickerView.date = bday
        }
        datePickerView.addTarget(self, action: #selector(handleDatePicker(sender:)), for: .valueChanged)
        
        // dismiss keyboard when clicking anywhere
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CustomerEditViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        //textFieldTitle.addTarget(self, action: #selector(onEnterPressed), for: .primaryActionTriggered)
        
        loadCustomer()
    }
    
    @objc func onEnterPressed(sender:UITextField) {
        print(sender)
        // Try to find next responder
        if let nextField = sender.superview?.viewWithTag(sender.tag + 1) as? UITextField {
              nextField.becomeFirstResponder()
        } else {
            // Not found, so remove keyboard.
            sender.resignFirstResponder()
        }
    }
    
    @objc func handleDatePicker(sender: UIDatePicker) {
        mCurrentCustomerBirthday = sender.date
        textFieldBirthday.text = CustomerDatabase.dateToDisplayStringWithoutTime(date: sender.date)
    }
    @IBAction func onClickBirthdayRemove(_ sender: UIButton) {
        mCurrentCustomerBirthday = nil
        textFieldBirthday.text = ""
    }
    
    @IBAction func onClickClose(_ sender: UIBarButtonItem) {
        exitViewController()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
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
    
    func loadCustomer() {
        for view in stackViewAttributes.arrangedSubviews {
            view.removeFromSuperview()
        }
        
        if(mCurrentCustomer == nil) {
            navigationItem.title = NSLocalizedString("new_customer", comment: "")
            mCurrentCustomer = Customer()
            mIsNewCustomer = true
        } else {
            mIsNewCustomer = false
            
            textFieldTitle.text = mCurrentCustomer?.mTitle
            textFieldFirstName.text = mCurrentCustomer?.mFirstName
            textFieldLastName.text = mCurrentCustomer?.mLastName
            textFieldPhoneHome.text = mCurrentCustomer?.mPhoneHome
            textFieldPhoneMobile.text = mCurrentCustomer?.mPhoneMobile
            textFieldPhoneWork.text = mCurrentCustomer?.mPhoneWork
            textFieldEmail.text = mCurrentCustomer?.mEmail
            textViewStreet.text = mCurrentCustomer?.mStreet
            textFieldZipcode.text = mCurrentCustomer?.mZipcode
            textFieldCity.text = mCurrentCustomer?.mCity
            textFieldCountry.text = mCurrentCustomer?.mCountry
            textFieldGroup.text = mCurrentCustomer?.mGroup
            textViewNotes.text = mCurrentCustomer?.mNotes
            if(mCurrentCustomer != nil) {
                switchNewsletter.isOn = mCurrentCustomer!.mNewsletter
            }
            mCurrentCustomerBirthday = mCurrentCustomer?.mBirthday
            if(mCurrentCustomer?.mBirthday != nil) {
                textFieldBirthday.text = CustomerDatabase.dateToDisplayStringWithoutTime(date: mCurrentCustomer!.mBirthday!)
            }
            mCurrentCustomerImage = mCurrentCustomer?.mImage
            if(mCurrentCustomerImage != nil && mCurrentCustomerImage?.count != 0) {
                imageViewImage.image = UIImage(data: mCurrentCustomerImage!)
            }
        }
        
        mDisplayAttributes = []
        for field in mDb.getCustomFields() {
            // get field value
            var attribute = mCurrentCustomer?.getCustomField(key: field.mTitle)
            if(attribute == nil) {
                attribute = CustomField(title: field.mTitle, value: "")
            }
            attribute!.mType = field.mType
            
            // convert date to display format
            if(attribute!.mType == CustomField.TYPE.DATE) {
                let date = CustomerDatabase.parseDateRaw(strDate: attribute!.mValue)
                if(date != nil) {
                    attribute!.mValue = CustomerDatabase.dateToDisplayStringWithoutTime(date: date!)
                }
            }
            
            // load presets
            if(field.mType == CustomField.TYPE.DROPDOWN) {
                var parsedData: [KeyValueItem] = []
                for field in mDb.getCustomFieldPresets(customFieldId: field.mId) {
                    parsedData.append(KeyValueItem(String(field.mId), field.mTitle))
                }
                attribute!.mPresetPickerController = PickerDataController(data: parsedData)
            }
            
            // add to view
            attribute!.mTextFieldHandle = insertDetail(customField: attribute!)
            mDisplayAttributes.append(attribute!)
        }
        
        refreshFiles()
    }
    func refreshFiles() {
        for view in stackViewFiles.arrangedSubviews {
            view.removeFromSuperview()
        }
        if let files = mCurrentCustomer?.getFiles() {
            for (index, file) in files.enumerated() {
                if file.mContent == nil { continue }
                insertFile(file: file, index: index)
            }
        }
    }
    
    var imagePicker = UIImagePickerController()
    @IBAction func onImageClick(_ sender: UITapGestureRecognizer) {
        let alert = UIAlertController(
            title: NSLocalizedString("image", comment: ""),
            message: nil,
            preferredStyle: .actionSheet
        )
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("image_from_camera", comment: ""),
                style: .default,
                handler: { alert in
                    self.imagePicker = ImagePickerCustomerPicture()
                    self.imagePicker.delegate = self
                    self.imagePicker.sourceType = .camera
                    self.imagePicker.allowsEditing = false
                    self.present(self.imagePicker, animated: true, completion: nil)
            }))
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("choose_from_gallery", comment: ""),
                style: .default,
                handler: { alert in
                    self.imagePicker = ImagePickerCustomerPicture()
                    self.imagePicker.delegate = self
                    self.imagePicker.sourceType = .photoLibrary
                    self.imagePicker.allowsEditing = false
                    self.present(self.imagePicker, animated: true, completion: nil)
            }))
        }
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("cancel", comment: ""),
            style: .cancel,
            handler: nil)
        )
        alert.popoverPresentationController?.sourceView = sender.view
        self.present(alert, animated: true)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            if let compressedImage = resizeImage(image: image, targetSize: CGSize(width: 800, height: 600)) {
                if picker is ImagePickerCustomerPicture {
                    if let jpeg = compressedImage.jpegData(compressionQuality: 0.20) {
                        self.imageViewImage.image = compressedImage
                        mCurrentCustomerImage = jpeg
                    }
                }
                else if picker is ImagePickerCustomerFile {
                    if let jpeg = compressedImage.jpegData(compressionQuality: 0.60) {
                        DispatchQueue.main.async { // use DispatchQueue for potential alert dialog
                            self.addFile(name: NSLocalizedString("image", comment: "")+".jpg", content: jpeg)
                        }
                    }
                }
            }
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    @IBAction func onClickRemoveImage(_ sender: UIButton) {
        imageViewImage.image = UIImage(named: "person")
        mCurrentCustomerImage = nil
    }
    @IBAction func onClickDone(_ sender: UIBarButtonItem) {
        if(textFieldTitle.text! == "" && textFieldFirstName.text! == "" && textFieldLastName.text! == "") {
            let alert = UIAlertController(
                title: NSLocalizedString("name_empty", comment: ""),
                message: NSLocalizedString("please_fill_name", comment: ""),
                preferredStyle: .alert)
            let okAction = UIAlertAction(
                title: NSLocalizedString("ok", comment: ""),
                style: .cancel)
            alert.addAction(okAction)
            self.present(alert, animated: true)
            return
        }
        if(switchNewsletter.isOn && textFieldEmail.text! == "") {
            let alert = UIAlertController(
                title: NSLocalizedString("email_empty", comment: ""),
                message: NSLocalizedString("please_fill_email", comment: ""),
                preferredStyle: .alert)
            let okAction = UIAlertAction(
                title: NSLocalizedString("ok", comment: ""),
                style: .cancel)
            alert.addAction(okAction)
            self.present(alert, animated: true)
            return
        }
        if(mIsInputOnlyModeActive && !switchConsent.isOn) {
            let alert = UIAlertController(
                title: NSLocalizedString("data_processing_consent", comment: ""),
                message: NSLocalizedString("please_accept_data_processing", comment: ""),
                preferredStyle: .alert)
            let okAction = UIAlertAction(
                title: NSLocalizedString("ok", comment: ""),
                style: .cancel)
            alert.addAction(okAction)
            self.present(alert, animated: true)
            return
        }
        if(saveCustomer()) {
            exitViewController()
        }
    }
    
    func exitViewController() {
        triggerListUpdate()
        if(mIsNewCustomer) {
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
            // go back to details
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
    
    @IBAction func onClickAddFile(_ sender: UIButton) {
        if #available(iOS 11, *) {
            if(!UserDefaults.standard.bool(forKey: "unlocked-fs")) {
                let alert = UIAlertController(
                    title: NSLocalizedString("not_unlocked", comment: ""),
                    message: NSLocalizedString("unlock_feature_via_inapp", comment: ""),
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(
                    title: NSLocalizedString("ok", comment: ""),
                    style: .default,
                    handler: nil)
                )
                self.present(alert, animated: true)
                return
            }
            
            let alert = UIAlertController(
                title: nil, message: nil,
                preferredStyle: .actionSheet
            )
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                alert.addAction(UIAlertAction(
                    title: NSLocalizedString("image_from_camera", comment: ""),
                    style: .default,
                    handler: { alert in
                        self.imagePicker = ImagePickerCustomerFile()
                        self.imagePicker.delegate = self
                        self.imagePicker.sourceType = .camera
                        self.imagePicker.allowsEditing = false
                        self.present(self.imagePicker, animated: true, completion: nil)
                }))
            }
            if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
                alert.addAction(UIAlertAction(
                    title: NSLocalizedString("choose_from_gallery", comment: ""),
                    style: .default,
                    handler: { alert in
                        self.imagePicker = ImagePickerCustomerFile()
                        self.imagePicker.delegate = self
                        self.imagePicker.sourceType = .photoLibrary
                        self.imagePicker.allowsEditing = false
                        self.present(self.imagePicker, animated: true, completion: nil)
                }))
            }
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("choose_from_files", comment: ""),
                style: .default,
                handler: { alert in
                    let documentPicker: UIDocumentPickerViewController
                    if #available(iOS 14.0, *) {
                        documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data], asCopy: false)
                    } else {
                        documentPicker = UIDocumentPickerViewController(documentTypes: ["public.data"], in: .import)
                    }
                    documentPicker.delegate = self
                    self.present(documentPicker, animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("cancel", comment: ""),
                style: .cancel,
                handler: nil)
            )
            alert.popoverPresentationController?.sourceView = sender
            self.present(alert, animated: true)
        } else {
            let alert = UIAlertController(
                title: NSLocalizedString("not_supported", comment: ""),
                message: NSLocalizedString("file_selection_not_supported", comment: ""),
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(
                title: NSLocalizedString("ok", comment: ""),
                style: .default,
                handler: nil)
            )
            self.present(alert, animated: true)
        }
    }
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        do {
            for url in urls {
                if(url.startAccessingSecurityScopedResource()) {
                    try addFile(name: url.lastPathComponent, content: Data(contentsOf: url))
                    url.stopAccessingSecurityScopedResource()
                }
            }
        } catch let error {
            handleError(text: error.localizedDescription)
        }
    }
    func addFile(name: String, content: Data) {
        do {
            try mCurrentCustomer?.addFile(file: CustomerFile(name: name, content: content))
            refreshFiles()
        } catch Customer.FileErrors.fileTooBig {
            dialog(title: NSLocalizedString("error", comment: ""), text: NSLocalizedString("file_too_big", comment: ""))
        } catch Customer.FileErrors.fileLimitReached {
            dialog(title: NSLocalizedString("error", comment: ""), text: NSLocalizedString("file_limit_reached", comment: ""))
        } catch let error {
            dialog(title: NSLocalizedString("error", comment: ""), text: error.localizedDescription)
        }
    }
    
    func dialog(title: String, text: String) {
        let alert = UIAlertController(
            title: title, message: text, preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(
            title: NSLocalizedString("ok", comment: ""),
            style: .cancel) { (action) in
        })
        self.present(alert, animated: true)
    }
    
    func saveCustomer() -> Bool {
        if(mCurrentCustomer == nil) {
            if(mDb.getCustomers(search: nil, showDeleted: false, withFiles: false).count >= 500 && !UserDefaults.standard.bool(forKey: "unlocked-lc")) {
                let alert = UIAlertController(
                    title: NSLocalizedString("not_unlocked", comment: ""),
                    message: NSLocalizedString("unlock_500_via_inapp", comment: ""),
                    preferredStyle: .alert
                )
                /*
                alert.addAction(UIAlertAction(
                    title: NSLocalizedString("more", comment: ""),
                    style: .default) { (action) in
                        self.performSegue(withIdentifier: "segueInfo", sender: nil)
                })*/
                alert.addAction(UIAlertAction(
                    title: NSLocalizedString("close", comment: ""),
                    style: .cancel) { (action) in
                })
                self.present(alert, animated: true)
                return false
            }
            
            mCurrentCustomer = Customer()
        }
        
        mCurrentCustomer?.mTitle = textFieldTitle.text!
        mCurrentCustomer?.mFirstName = textFieldFirstName.text!
        mCurrentCustomer?.mLastName = textFieldLastName.text!
        mCurrentCustomer?.mPhoneHome = textFieldPhoneHome.text!
        mCurrentCustomer?.mPhoneMobile = textFieldPhoneMobile.text!
        mCurrentCustomer?.mPhoneWork = textFieldPhoneWork.text!
        mCurrentCustomer?.mEmail = textFieldEmail.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        mCurrentCustomer?.mStreet = textViewStreet.text!
        mCurrentCustomer?.mZipcode = textFieldZipcode.text!
        mCurrentCustomer?.mCity = textFieldCity.text!
        mCurrentCustomer?.mCountry = textFieldCountry.text!
        mCurrentCustomer?.mGroup = textFieldGroup.text!
        mCurrentCustomer?.mNotes = textViewNotes.text!
        mCurrentCustomer?.mNewsletter = switchNewsletter.isOn
        mCurrentCustomer?.mBirthday = mCurrentCustomerBirthday
        mCurrentCustomer?.mImage = mCurrentCustomerImage
        mCurrentCustomer?.mLastModified = Date()
        
        // update attributes from text fields
        for attribute in mDisplayAttributes {
            if let textField = attribute.mTextFieldHandle as? UITextField {
                // convert display date to storage format
                var finalValue = textField.text!
                if(attribute.mType == CustomField.TYPE.DATE) {
                    let date = CustomerDatabase.parseDisplayDateWithoutTime(strDate: finalValue)
                    if(date != nil) {
                        finalValue = CustomerDatabase.dateToStringRaw(date: date!)
                    }
                }
                mCurrentCustomer?.setCustomField(title:attribute.mTitle, value:finalValue)
            }
            else if let textView = attribute.mTextFieldHandle as? UITextView {
                mCurrentCustomer?.setCustomField(title:attribute.mTitle, value:textView.text!)
            }
        }
        
        var success = false
        if(mIsNewCustomer) {
            success = mDb.insertCustomer(c: mCurrentCustomer!)
        } else {
            success = mDb.updateCustomer(c: mCurrentCustomer!)
        }
        
        if(success) {
            mDb.updateCallDirectoryDatabase()
            setUnsyncedChanges()
        }
        
        return success
    }
    
    func insertDetail(customField:CustomField) -> UIView? {
        let finalText = customField.mValue
        let labelTitle = UILabel()
        if #available(iOS 13.0, *) {
            labelTitle.textColor = UIColor.secondaryLabel
        } else {
            labelTitle.textColor = UIColor.gray
        }
        labelTitle.text = customField.mTitle
        
        var inputView:UIView? = nil
        if(customField.mType == CustomField.TYPE.TEXT_MULTILINE) {
            let textView = UITextView()
            textView.isScrollEnabled = false
            textView.text = finalText
            textView.font = textFieldTitle.font
            GuiHelper.adjustTextviewStyle(control: textView, viewController: self)
            inputView = textView
        } else {
            let textField = UITextField()
            textField.text = finalText
            textField.borderStyle = .roundedRect
            textField.font = textFieldTitle.font
            if(customField.mType == CustomField.TYPE.NUMBER) {
                textField.keyboardType = .numbersAndPunctuation
            }
            else if(customField.mType == CustomField.TYPE.DATE) {
                let toolBar = UIToolbar()
                toolBar.sizeToFit()
                let doneButton = UIBarButtonItem(title: NSLocalizedString("done", comment: ""), style: .plain, target: self, action: #selector(CustomerEditViewController.dismissKeyboard))
                toolBar.setItems([doneButton], animated: false)
                toolBar.isUserInteractionEnabled = true
                let datePickerView = UITextFieldDatePicker()
                datePickerView.textFieldReference = textField
                datePickerView.datePickerMode = .date
                if #available(iOS 13.4, *) {
                    datePickerView.preferredDatePickerStyle = .wheels
                }
                textField.inputAccessoryView = toolBar
                textField.inputView = datePickerView
                if let date = CustomerDatabase.parseDisplayDateWithoutTime(strDate: finalText) {
                    datePickerView.date = date
                }
                datePickerView.addTarget(self, action: #selector(handleCustomDatePicker(sender:)), for: .valueChanged)
            }
            else if(customField.mType == CustomField.TYPE.DROPDOWN) {
                initDropDownStyle(textField: textField)
                
                let toolBar = UIToolbar()
                toolBar.sizeToFit()
                let doneButton = UIBarButtonItem(title: NSLocalizedString("done", comment: ""), style: .plain, target: self, action: #selector(CustomerEditViewController.dismissKeyboard))
                toolBar.setItems([doneButton], animated: false)
                toolBar.isUserInteractionEnabled = true
                
                customField.mPresetPickerController!.textField = textField
                let uiPicker = UIPickerView()
                uiPicker.delegate = customField.mPresetPickerController!
                textField.inputView = uiPicker
                textField.inputAccessoryView = toolBar
                if(customField.mPresetPickerController!.data.count > 0) {
                    // select first item
                    uiPicker.selectRow(0, inComponent: 0, animated: false)
                    // select given default if exists
                    for i in 0...customField.mPresetPickerController!.data.count-1 {
                        if(customField.mPresetPickerController!.data[i].value == finalText) {
                            uiPicker.selectRow(i, inComponent: 0, animated: false)
                            break
                        }
                    }
                }
            }
            inputView = textField
        }
        
        let stackView = UIStackView(arrangedSubviews: [labelTitle, inputView!])
        stackView.axis = .vertical
        
        stackViewAttributes.addArrangedSubview(stackView)
        
        return inputView
    }
    
    func insertFile(file:CustomerFile, index:Int) {
        let buttonFile = FileIndexButton(file: file, index: index)
        buttonFile.setTitle(file.mName, for: .normal)
        buttonFile.addTarget(self, action: #selector(onClickFile), for: .touchUpInside)
        
        let buttonRemove = FileIndexButton(file: file, index: index)
        buttonRemove.setImage(UIImage(named: "baseline_clear_black_24pt"), for: .normal)
        buttonRemove.addTarget(self, action: #selector(onClickFileRemove), for: .touchUpInside)
        buttonRemove.setContentHuggingPriority(.required, for: .horizontal)
        buttonRemove.setContentCompressionResistancePriority(.required, for: .horizontal)
        
        let imageClip = UIImageView(image: UIImage(named: "baseline_attach_file_black_24pt"))
        imageClip.tintColor = UIColor.init(hex: "#828282")
        imageClip.contentMode = .scaleAspectFill
        imageClip.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        imageClip.widthAnchor.constraint(equalToConstant: 10).isActive = true
        
        let stackView = UIStackView(arrangedSubviews: [imageClip, buttonFile, buttonRemove])
        stackView.axis = .horizontal
        stackView.spacing = 10
        
        stackViewFiles.addArrangedSubview(stackView)
    }
    @objc func onClickFile(sender: FileIndexButton!) {
        inputBox(title: NSLocalizedString("file_name", comment: ""), defaultText: sender.mFile!.mName, callback: { newText in
            if(newText != nil) {
                self.mCurrentCustomer?.renameFile(index: sender.mIndex, newName: newText!)
                self.refreshFiles()
            }
        })
    }
    @objc func onClickFileRemove(sender: FileIndexButton!) {
        mCurrentCustomer?.removeFile(index: sender.mIndex)
        refreshFiles()
    }
    
    func handleError(text: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: NSLocalizedString("error", comment: ""), message: text, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    func inputBox(title: String, defaultText: String, callback: @escaping (String?)->()) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField(configurationHandler: { (textField) -> Void in
            textField.text = defaultText
            textField.delegate = self
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
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let idx = textField.text!.lastIndex(of: ".") {
            textField.selectedTextRange = textField.textRange(
                from: textField.position(from: textField.beginningOfDocument, offset: 0)!,
                to: textField.position(from: textField.beginningOfDocument, offset: idx)!
            )
        }
        textField.becomeFirstResponder()
    }
    
    @objc func handleCustomDatePicker(sender: UITextFieldDatePicker) {
        if(sender.textFieldReference != nil) {
            sender.textFieldReference!.text = CustomerDatabase.dateToDisplayStringWithoutTime(date: sender.date)
        }
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Figure out what our orientation is, and use that to form the rectangle
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }

        // This is the rect that we've calculated out and this is what is actually used below
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)

        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
}

public extension String {
    func lastIndex(of char: Character) -> Int? {
        return lastIndex(of: char)?.utf16Offset(in: self)
    }
}

class FileIndexButton: UIButton {
    var mIndex:Int = -1
    var mFile:CustomerFile? = nil
    required init(file:CustomerFile, index:Int) {
        super.init(frame: .zero)
        mFile = file
        mIndex = index
        if #available(iOS 13.0, *) {
            setTitleColor(.link, for: .normal)
        } else {
            setTitleColor(UIColor.init(hex: "#0f7c9d"), for: .normal)
        }
        if #available(iOS 11.0, *) {
            contentHorizontalAlignment = .leading
        } else {
            contentHorizontalAlignment = .left
        }
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
class ImagePickerCustomerPicture: UIImagePickerController {
}
class ImagePickerCustomerFile: UIImagePickerController {
}
