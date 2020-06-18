//
//  CustomerEditViewController.swift
//  Copyright © 2019 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class CustomerEditViewController : UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
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
    @IBOutlet weak var stackViewConsent: UIStackView!
    @IBOutlet weak var stackViewContact: UIStackView!
    @IBOutlet weak var stackViewAddress: UIStackView!
    @IBOutlet weak var stackViewGroup: UIStackView!
    @IBOutlet weak var stackViewNotes: UIStackView!
    @IBOutlet weak var stackViewNewsletter: UIStackView!
    @IBOutlet weak var stackViewBirthday: UIStackView!
    
    let mDb = CustomerDatabase()
    
    var mCurrentCustomer:Customer? = nil
    var mDisplayAttributes:[CustomField] = []
    var mIsNewCustomer = true
    var mCurrentCustomerImage:Data? = nil
    var mCurrentCustomerBirthday:Date? = nil
    var mIsInputOnlyModeActive = false
    
    static var BORDER_COLOR_LIGHT = UIColor(
        red: 215.0 / 255.0,
        green: 215.0 / 255.0,
        blue: 215.0 / 255.0,
        alpha: CGFloat(1.0)
    ).cgColor
    static var BORDER_COLOR_DARK = UIColor(
        red: 60.0 / 255.0,
        green: 60.0 / 255.0,
        blue: 60.0 / 255.0,
        alpha: CGFloat(1.0)
    ).cgColor
    var mBorderColor = CustomerEditViewController.BORDER_COLOR_LIGHT
    static var BORDER_WIDTH:CGFloat = 1.0
    static var BORDER_RADIUS:CGFloat = 5
    
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
        
        if #available(iOS 12.0, *) {
            if self.traitCollection.userInterfaceStyle == .dark {
                mBorderColor = CustomerEditViewController.BORDER_COLOR_DARK
            }
        }
        textViewStreet.layer.borderColor = mBorderColor
        textViewStreet.layer.borderWidth = CustomerEditViewController.BORDER_WIDTH
        textViewStreet.layer.cornerRadius = CustomerEditViewController.BORDER_RADIUS
        textViewNotes.layer.borderColor = mBorderColor
        textViewNotes.layer.borderWidth = CustomerEditViewController.BORDER_WIDTH
        textViewNotes.layer.cornerRadius = CustomerEditViewController.BORDER_RADIUS
        
        // birthday date picker view
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: NSLocalizedString("done", comment: ""), style: .plain, target: self, action: #selector(CustomerEditViewController.dismissKeyboard))
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        let datePickerView = UIDatePicker()
        datePickerView.datePickerMode = .date
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
    
    func loadCustomer() {
        for view in stackViewAttributes.arrangedSubviews {
            view.removeFromSuperview()
        }
        
        if(mCurrentCustomer == nil) {
            navigationItem.title = NSLocalizedString("new_customer", comment: "")
            mIsNewCustomer = true
        } else {
            mIsNewCustomer = false
        }
        
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
        
        mDisplayAttributes = []
        for field in mDb.getCustomFields() {
            var attribute = mCurrentCustomer?.getCustomField(key: field.mTitle)
            if(attribute == nil) {
                attribute = CustomField(title: field.mTitle, value: "")
            }
            attribute!.mType = field.mType
            
            // convert date to display format
            if(attribute!.mType == CustomField.TYPE.DATE) {
                let date = CustomerDatabase.parseDate(strDate: attribute!.mValue)
                if(date != nil) {
                    attribute!.mValue = CustomerDatabase.dateToDisplayStringWithoutTime(date: date!)
                }
            }
            
            attribute!.mTextFieldHandle = insertDetail(title: field.mTitle, text: attribute?.mValue, type: field.mType)
            mDisplayAttributes.append(attribute!)
        }
    }
    
    var imagePicker = UIImagePickerController()
    @IBAction func onImageClick(_ sender: UITapGestureRecognizer) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.allowsEditing = false
            present(imagePicker, animated: true, completion: nil)
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            if let compressedImage = resizeImage(image: image, targetSize: CGSize(width: 800, height: 600)) {
                if let jpeg = compressedImage.jpegData(compressionQuality: 0.20) {
                    self.imageViewImage.image = compressedImage
                    mCurrentCustomerImage = jpeg
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
    
    func saveCustomer() -> Bool {
        if(mCurrentCustomer == nil) {
            if(mDb.getCustomers(showDeleted: false).count >= 500 && !UserDefaults.standard.bool(forKey: "unlocked-lc")) {
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
                        finalValue = CustomerDatabase.dateToString(date: date!)
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
            setUnsyncedChanges()
        }
        
        return success
    }
    
    func insertDetail(title:String?, text:String?, type:Int) -> UIView? {
        var finalText = text
        if(title == nil) { return nil }
        if(finalText == nil) { finalText = "" }
        let labelTitle = UILabel()
        if #available(iOS 13.0, *) {
            labelTitle.textColor = UIColor.secondaryLabel
        } else {
            labelTitle.textColor = UIColor.gray
        }
        labelTitle.text = title
        
        var inputView:UIView? = nil
        if(type == CustomField.TYPE.TEXT_MULTILINE) {
            let textView = UITextView()
            textView.isScrollEnabled = false
            textView.text = finalText
            textView.font = textFieldTitle.font
            textView.layer.borderColor = mBorderColor
            textView.layer.borderWidth = CustomerEditViewController.BORDER_WIDTH
            textView.layer.cornerRadius = CustomerEditViewController.BORDER_RADIUS
            inputView = textView
        } else {
            let textField = UITextField()
            textField.text = finalText
            textField.borderStyle = .roundedRect
            textField.font = textFieldTitle.font
            if(type == CustomField.TYPE.NUMBER) {
                textField.keyboardType = .numbersAndPunctuation
            }
            else if(type == CustomField.TYPE.DATE) {
                let toolBar = UIToolbar()
                toolBar.sizeToFit()
                let doneButton = UIBarButtonItem(title: NSLocalizedString("done", comment: ""), style: .plain, target: self, action: #selector(CustomerEditViewController.dismissKeyboard))
                toolBar.setItems([doneButton], animated: false)
                toolBar.isUserInteractionEnabled = true
                let datePickerView = UITextFieldDatePicker()
                datePickerView.textFieldReference = textField
                datePickerView.datePickerMode = .date
                textField.inputAccessoryView = toolBar
                textField.inputView = datePickerView
                if let date = CustomerDatabase.parseDisplayDateWithoutTime(strDate: finalText!) {
                    datePickerView.date = date
                }
                datePickerView.addTarget(self, action: #selector(handleCustomDatePicker(sender:)), for: .valueChanged)
            }
            inputView = textField
        }
        
        let stackView = UIStackView(arrangedSubviews: [labelTitle, inputView!])
        stackView.axis = .vertical
        
        stackViewAttributes.addArrangedSubview(stackView)
        
        return inputView
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
