//
//  CustomerDetailsViewController.swift
//  Copyright © 2019 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit
import MessageUI
import CoreLocation
import MapKit

class CustomerDetailsViewController : UIViewController, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var imageViewImage: UIImageView!
    @IBOutlet weak var labelLastModified: UILabel!
    @IBOutlet weak var stackViewAttributes: UIStackView!
    @IBOutlet weak var stackViewPhoneHome: UIStackView!
    @IBOutlet weak var stackViewPhoneMobile: UIStackView!
    @IBOutlet weak var stackViewPhoneWork: UIStackView!
    @IBOutlet weak var stackViewEmail: UIStackView!
    @IBOutlet weak var stackViewAddress: UIStackView!
    @IBOutlet weak var stackViewGroup: UIStackView!
    @IBOutlet weak var stackViewNotes: UIStackView!
    @IBOutlet weak var stackViewNewsletter: UIStackView!
    @IBOutlet weak var stackViewBirthday: UIStackView!
    
    @IBOutlet weak var labelPhoneHome: UILabel!
    @IBOutlet weak var labelPhoneMobile: UILabel!
    @IBOutlet weak var labelPhoneWork: UILabel!
    @IBOutlet weak var labelEmail: UILabel!
    @IBOutlet weak var labelAddress: UILabel!
    @IBOutlet weak var labelGroup: UILabel!
    @IBOutlet weak var labelNotes: UILabel!
    @IBOutlet weak var labelNewsletter: UILabel!
    @IBOutlet weak var labelBirthday: UILabel!
    @IBOutlet weak var buttonEdit: UIButton!
    
    let mDb = CustomerDatabase()
    
    var mCurrentCustomerId:Int64 = -1
    private var mCurrentCustomer:Customer? = nil
    
    override func viewDidLoad() {
        initColor()
        
        if(!UserDefaults.standard.bool(forKey: "show-phone-field")) {
            stackViewPhoneHome.isHidden = true
            stackViewPhoneMobile.isHidden = true
            stackViewPhoneWork.isHidden = true
        }
        if(!UserDefaults.standard.bool(forKey: "show-email-field")) {
            stackViewEmail.isHidden = true
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
        
        loadCustomer()
    }
    
    func initColor() {
        buttonEdit.backgroundColor = UINavigationBar.appearance().barTintColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadCustomer()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CustomerEditViewController {
            vc.mCurrentCustomer = mCurrentCustomer
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
                    else if let bvc = mnvc.viewControllers.last as? CustomerBirthdayTableViewController {
                        bvc.reloadCustomers()
                    }
                }
            }
        }
    }
    
    func loadCustomer() {
        // query customer with image
        mCurrentCustomer = mDb.getCustomer(id: mCurrentCustomerId)
        if(mCurrentCustomer == nil) {
            exitViewController()
            return
        }
        
        if(mCurrentCustomer!.mImage != nil && mCurrentCustomer!.mImage!.count != 0) {
            imageViewImage.image = UIImage(data: mCurrentCustomer!.mImage!)
        }
        
        var additionalInfoString = ""
        if(mCurrentCustomer!.mNewsletter) {
            additionalInfoString += NSLocalizedString("Yes", comment: "")
        } else {
            additionalInfoString += NSLocalizedString("No", comment: "")
        }
        additionalInfoString += " / "
        if(mCurrentCustomer!.mConsentImage != nil && mCurrentCustomer!.mConsentImage!.count != 0) {
            additionalInfoString += NSLocalizedString("Yes", comment: "")
        } else {
            additionalInfoString += NSLocalizedString("No", comment: "")
        }
        
        labelName.text = mCurrentCustomer?.getFullName(lastNameFirst: false)
        labelPhoneHome.text = mCurrentCustomer?.mPhoneHome
        labelPhoneMobile.text = mCurrentCustomer?.mPhoneMobile
        labelPhoneWork.text = mCurrentCustomer?.mPhoneWork
        labelEmail.text = mCurrentCustomer?.mEmail
        labelAddress.text = mCurrentCustomer?.getAddressString()
        labelGroup.text = mCurrentCustomer?.mGroup
        labelNotes.text = mCurrentCustomer?.mNotes
        labelNewsletter.text = additionalInfoString
        if(mCurrentCustomer?.mBirthday == nil) {
            labelBirthday.text = ""
        } else {
            labelBirthday.text = mCurrentCustomer?.getBirthdayString()
        }
        labelLastModified.text = CustomerDatabase.dateToDisplayString(date: mCurrentCustomer!.mLastModified)
        
        for view in stackViewAttributes.arrangedSubviews {
            view.removeFromSuperview()
        }
        for field in mDb.getCustomFields() {
            var finalText = mCurrentCustomer?.getCustomFieldString(key: field.mTitle) ?? ""
            
            // convert date to display format
            if(field.mType == CustomField.TYPE.DATE) {
                let date = CustomerDatabase.parseDate(strDate: finalText)
                if(date != nil) {
                    finalText = CustomerDatabase.dateToDisplayStringWithoutTime(date: date!)
                }
            }
            
            insertDetail(title: field.mTitle, text: finalText)
        }
    }
    
    @IBAction func onClickMore(_ sender: UIBarButtonItem) {
        let printAction = UIAlertAction(
            title: NSLocalizedString("print_customer", comment: ""),
            style: .default) { (action) in
                
        }
        printAction.setValue(UIImage(named:"baseline_print_black_24pt"), forKey: "image")
        let deleteAction = UIAlertAction(
            title: NSLocalizedString("delete_customer", comment: ""),
            style: .destructive) { (action) in
                self.mDb.removeCustomer(id: self.mCurrentCustomer?.mId ?? -1)
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
            message: NSLocalizedString("ID:", comment: "")+" "+String(mCurrentCustomer!.mId),
            preferredStyle: .actionSheet
        )
        //alert.addAction(printAction) // ToDo
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        // On iPad, action sheets must be presented from a popover.
        alert.popoverPresentationController?.barButtonItem = sender
        self.present(alert, animated: true)
    }
    @IBAction func onClickExport(_ sender: UIBarButtonItem) {
        let exportVcfAction = UIAlertAction(
            title: NSLocalizedString("export_vcf", comment: ""),
            style: .default) { (action) in
                self.exportVcf(sender)
        }
        let exportCsvAction = UIAlertAction(
            title: NSLocalizedString("export_csv", comment: ""),
            style: .default) { (action) in
                self.exportCsv(sender)
        }
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("close", comment: ""),
            style: .cancel) { (action) in
        }
        
        let alert = UIAlertController(
            title: NSLocalizedString("export_single_customer_record", comment: ""),
            message: NSLocalizedString("export_single_customer_record_description", comment: ""),
            preferredStyle: .actionSheet
        )
        alert.addAction(exportVcfAction)
        alert.addAction(exportCsvAction)
        alert.addAction(cancelAction)
        
        // On iPad, action sheets must be presented from a popover.
        alert.popoverPresentationController?.barButtonItem = sender
        self.present(alert, animated: true)
    }
    
    func exportCsv(_ sender: UIBarButtonItem) {
        let csv = CsvWriter(customers: [mCurrentCustomer!], customFields: self.mDb.getCustomFields())
        
        let fileurl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("export."+String(mCurrentCustomer!.mId)+".csv")

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
    
    func exportVcf(_ sender: UIBarButtonItem) {
        let vcf = VcfWriter(customers: [mCurrentCustomer!])
        
        let fileurl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("export."+String(mCurrentCustomer!.mId)+".vcf")

        do {
            try vcf.buildVcfContent().write(to: fileurl, atomically: true, encoding: .utf8)

            let activityController = UIActivityViewController(
                activityItems: [fileurl], applicationActivities: nil
            )
            activityController.popoverPresentationController?.barButtonItem = sender
            self.present(activityController, animated: true, completion: nil)

        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    @IBAction func onClickEdit(_ sender: UIButton) {
        performSegue(withIdentifier: "segueCustomerEdit", sender: nil)
    }
    
    @IBAction func onClickPhoneHome(_ sender: UIButton) {
        telephoneActionSelection(number: mCurrentCustomer!.mPhoneHome)
    }
    @IBAction func onClickPhoneMobile(_ sender: UIButton) {
        telephoneActionSelection(number: mCurrentCustomer!.mPhoneMobile)
    }
    @IBAction func onClickPhoneWork(_ sender: UIButton) {
        telephoneActionSelection(number: mCurrentCustomer!.mPhoneWork)
    }
    @IBAction func onClickEmail(_ sender: UIButton) {
        let textAction = UIAlertAction(
            title: NSLocalizedString("send_message", comment: ""),
            style: .default) { (action) in
                if(MFMailComposeViewController.canSendMail()) {
                    // iOS mail app
                    let composeVC = MFMailComposeViewController()
                    composeVC.mailComposeDelegate = self
                    // Configure the fields of the interface.
                    composeVC.setToRecipients([self.mCurrentCustomer!.mEmail])
                    //composeVC.setSubject("Message Subject")
                    //composeVC.setMessageBody("Message content.", isHTML: false)
                    // Present the view controller modally.
                    self.present(composeVC, animated: true, completion: nil)
                } else {
                    // 3rd party mail app
                    let activityViewController = UIActivityViewController(
                        activityItems: [""], applicationActivities: nil)
                    // This line remove the arrow of the popover to show in iPad
                    activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection()
                    activityViewController.popoverPresentationController?.sourceView = self.view

                    // Anything you want to exclude
                    activityViewController.excludedActivityTypes = [
                        UIActivity.ActivityType.postToWeibo,
                        UIActivity.ActivityType.print,
                        UIActivity.ActivityType.assignToContact,
                        UIActivity.ActivityType.saveToCameraRoll,
                        UIActivity.ActivityType.addToReadingList,
                        UIActivity.ActivityType.postToFlickr,
                        UIActivity.ActivityType.postToVimeo,
                        UIActivity.ActivityType.postToTencentWeibo
                    ]

                    self.present(activityViewController, animated: true, completion: nil)
                }
        }
        let copyAction = UIAlertAction(
            title: NSLocalizedString("copy_to_clipboard", comment: ""),
            style: .default) { (action) in
                UIPasteboard.general.string = self.mCurrentCustomer!.mEmail
        }
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("close", comment: ""),
            style: .cancel) { (action) in
        }
        let alert = UIAlertController(
            title: mCurrentCustomer!.mEmail, message: nil, preferredStyle: .alert
        )
        alert.addAction(textAction)
        alert.addAction(copyAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }
    @IBAction func onClickAddress(_ sender: UIButton) {
        let viewAction = UIAlertAction(
            title: NSLocalizedString("open_map", comment: ""),
            style: .default) { (action) in
                self.coordinates(forAddress: self.mCurrentCustomer!.getAddressString()) {
                    (location) in
                    guard let location = location else {
                        return
                    }
                    self.openMapForPlace(lat: location.latitude, long: location.longitude)
                }
        }
        let copyAction = UIAlertAction(
            title: NSLocalizedString("copy_to_clipboard", comment: ""),
            style: .default) { (action) in
                UIPasteboard.general.string = self.mCurrentCustomer!.getAddressString()
        }
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("close", comment: ""),
            style: .cancel) { (action) in
        }
        let alert = UIAlertController(
            title: mCurrentCustomer!.getAddressString(), message: nil, preferredStyle: .alert
        )
        alert.addAction(viewAction)
        alert.addAction(copyAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }
    
    func telephoneActionSelection(number: String) {
        let callAction = UIAlertAction(
            title: NSLocalizedString("start_call", comment: ""),
            style: .default) { (action) in
                if let url = URL(string: "tel://\(number)"), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
        }
        let textAction = UIAlertAction(
            title: NSLocalizedString("send_message", comment: ""),
            style: .default) { (action) in
                if(MFMessageComposeViewController.canSendText()) {
                    let controller = MFMessageComposeViewController()
                    //controller.body = "Message Body"
                    controller.recipients = [number]
                    controller.messageComposeDelegate = self
                    self.present(controller, animated: true, completion: nil)
                }
        }
        let copyAction = UIAlertAction(
            title: NSLocalizedString("copy_to_clipboard", comment: ""),
            style: .default) { (action) in
                UIPasteboard.general.string = number
        }
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("close", comment: ""),
            style: .cancel) { (action) in
        }
        let alert = UIAlertController(
            title: number, message: nil, preferredStyle: .alert
        )
        alert.addAction(callAction)
        alert.addAction(textAction)
        alert.addAction(copyAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true)
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        //... handle sms screen actions
        self.dismiss(animated: true, completion: nil)
    }
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        // Check the result or perform other tasks.
        controller.dismiss(animated: true, completion: nil)
    }
    
    func openMapForPlace(lat:Double = 0, long:Double = 0, placeName:String = "") {
        let latitude: CLLocationDegrees = lat
        let longitude: CLLocationDegrees = long

        let regionDistance:CLLocationDistance = 100
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let regionSpan = MKCoordinateRegion(center: coordinates, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = placeName
        mapItem.openInMaps(launchOptions: options)
    }
    func coordinates(forAddress address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) {
            (placemarks, error) in
            guard error == nil else {
                print("Geocoding error: \(error!)")
                completion(nil)
                return
            }
            completion(placemarks?.first?.location?.coordinate)
        }
    }
    
    func insertDetail(title:String?, text:String?) {
        var finalText = text
        if(title == nil) { return }
        if(finalText == nil) { finalText = "" }
        let labelTitle = UILabel()
        if #available(iOS 13.0, *) {
            labelTitle.textColor = UIColor.secondaryLabel
        } else {
            labelTitle.textColor = UIColor.gray
        }
        labelTitle.text = title
        
        let labelText = UICopyLabel()
        labelText.text = finalText
        labelText.numberOfLines = 10
        
        let stackView = UIStackView(arrangedSubviews: [labelTitle, labelText])
        stackView.axis = .vertical
        
        stackViewAttributes.addArrangedSubview(stackView)
    }
}
