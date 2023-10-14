//
//  CustomerDetailsViewController.swift
//  Copyright © 2019 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit
import MessageUI
import CoreLocation
import MapKit
import QuickLook

class CustomerDetailsViewController : UIViewController, MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, QLPreviewControllerDataSource {
    
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
    @IBOutlet weak var stackViewFilesContainer: UIStackView!
    @IBOutlet weak var stackViewFiles: UIStackView!
    @IBOutlet weak var stackViewVouchers: UIStackView!
    @IBOutlet weak var stackViewAppointments: UIStackView!
    
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
        if(!UserDefaults.standard.bool(forKey: "show-customer-picture")) {
            imageViewImage.isHidden = true
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
        if(!UserDefaults.standard.bool(forKey: "show-files")) {
            stackViewFilesContainer.isHidden = true
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
        mCurrentCustomer = mDb.getCustomer(id: mCurrentCustomerId, showDeleted: false)
        if(mCurrentCustomer == nil) {
            exitViewController()
            return
        }
        
        if(mCurrentCustomer!.mImage != nil && mCurrentCustomer!.mImage!.count != 0) {
            imageViewImage.image = UIImage(data: mCurrentCustomer!.mImage!)
        }
        
        labelName.text = mCurrentCustomer?.getFullName(lastNameFirst: false)
        labelPhoneHome.text = mCurrentCustomer?.mPhoneHome
        labelPhoneMobile.text = mCurrentCustomer?.mPhoneMobile
        labelPhoneWork.text = mCurrentCustomer?.mPhoneWork
        labelEmail.text = mCurrentCustomer?.mEmail
        labelAddress.text = mCurrentCustomer?.getAddressString()
        labelGroup.text = mCurrentCustomer?.mGroup
        labelNotes.text = mCurrentCustomer?.mNotes
        labelNewsletter.text = mCurrentCustomer!.mNewsletter ? NSLocalizedString("Yes", comment: "") : NSLocalizedString("No", comment: "")
        if(mCurrentCustomer?.mBirthday == nil) {
            labelBirthday.text = ""
        } else {
            labelBirthday.text = mCurrentCustomer?.getBirthdayString()
        }
        labelLastModified.text = CustomerDatabase.dateToDisplayString(date: mCurrentCustomer!.mLastModified)
        
        let customFields = mDb.getCustomFields()
        for view in stackViewAttributes.arrangedSubviews {
            view.removeFromSuperview()
        }
        for field in customFields {
            var finalText = mCurrentCustomer?.getCustomFieldString(key: field.mTitle) ?? ""
                
            // convert date to display format
            if(field.mType == CustomField.TYPE.DATE) {
                let date = CustomerDatabase.parseDateRaw(strDate: finalText)
                if(date != nil) {
                    finalText = CustomerDatabase.dateToDisplayStringWithoutTime(date: date!)
                }
            }
                
            insertDetail(title: field.mTitle, text: finalText)
        }

        let files = mCurrentCustomer!.getFiles()
        for view in stackViewFiles.arrangedSubviews {
            view.removeFromSuperview()
        }
        for file in files {
            if file.mContent == nil { continue }
            insertFile(file: file)
        }
        
        let vouchers = mDb.getVouchersByCustomer(customerId: mCurrentCustomer!.mId)
        for view in stackViewVouchers.arrangedSubviews {
            view.removeFromSuperview()
        }
        for voucher in vouchers {
            insertVoucher(voucher: voucher)
        }
        
        let appointments = mDb.getAppointmentsByCustomer(customerId: mCurrentCustomer!.mId)
        for view in stackViewAppointments.arrangedSubviews {
            view.removeFromSuperview()
        }
        for appointment in appointments {
            insertAppointment(appointment: appointment)
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
                self.mDb.updateCallDirectoryDatabase()
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
        let csv = CustomerCsvWriter(customers: [mCurrentCustomer!], customFields: self.mDb.getCustomFields())
        
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
        let vcf = CustomerVcfWriter(customers: [mCurrentCustomer!])
        
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
                    composeVC.setSubject(UserDefaults.standard.string(forKey: "email-subject") ?? "")
                    composeVC.setMessageBody(UserDefaults.standard.string(forKey: "email-template") ?? "", isHTML: false)
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
                if(UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)) {
                    let strUrl = "comgooglemaps://?saddr=&daddr="+self.mCurrentCustomer!.getAddressString().addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!+"&directionsmode=driving"
                    print(strUrl)
                    if let url = URL(string: strUrl), !url.absoluteString.isEmpty {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                } else {
                    self.coordinates(forAddress: self.mCurrentCustomer!.getAddressString()) {
                        (location) in
                        if let location = location {
                            self.openMapForPlace(lat: location.latitude, long: location.longitude)
                        }
                    }
                }
        }
        let copyAction = UIAlertAction(
            title: NSLocalizedString("copy_to_clipboard", comment: ""),
            style: .default) { (action) in
                UIPasteboard.general.string = self.mCurrentCustomer!.getAddressString()
        }
        let copyPostalAddressAction = UIAlertAction(
            title: NSLocalizedString("copy_postal_address", comment: ""),
            style: .default) { (action) in
                UIPasteboard.general.string = self.mCurrentCustomer!.getFullName(lastNameFirst: false) + "\n" + self.mCurrentCustomer!.getAddressString()
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
        alert.addAction(copyPostalAddressAction)
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
        let labelTitle = SecondaryLabel()
        labelTitle.text = title
        
        let labelText = UICopyLabel()
        labelText.text = finalText
        labelText.numberOfLines = 10
        
        let stackView = UIStackView(arrangedSubviews: [labelTitle, labelText])
        stackView.axis = .vertical
        
        stackViewAttributes.addArrangedSubview(stackView)
    }
    
    func insertFile(file:CustomerFile) {
        let button = FileButton(file: file)
        button.addTarget(self, action: #selector(onClickFileButton), for: .touchUpInside)
        
        let imageClip = UIImageView(image: UIImage(named: "baseline_attach_file_black_24pt"))
        imageClip.tintColor = UIColor.init(hex: "#828282")
        imageClip.contentMode = .scaleAspectFill
        imageClip.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        let stackView = UIStackView(arrangedSubviews: [imageClip, button])
        stackView.axis = .horizontal
        stackView.spacing = 10
        
        stackViewFiles.addArrangedSubview(stackView)
    }
    
    func insertVoucher(voucher:Voucher) {
        let button = VoucherButton(voucher: voucher)
        button.addTarget(self, action: #selector(onClickVoucherButton), for: .touchUpInside)
        stackViewVouchers.addArrangedSubview(button)
    }
    
    func insertAppointment(appointment:CustomerAppointment) {
        let button = AppointmentButton(appointment: appointment)
        button.addTarget(self, action: #selector(onClickAppointmentButton), for: .touchUpInside)
        stackViewAppointments.addArrangedSubview(button)
    }
    
    var mCurrentFileUrl:URL?
    @objc func onClickFileButton(sender: FileButton!) {
        do {
            let tmpurl = try! FileManager.default.url(
                for: .documentDirectory, in: .userDomainMask,
                appropriateFor: nil, create: true
            ).appendingPathComponent("tmp")
            try FileManager.default.createDirectory(
                atPath: tmpurl.path, withIntermediateDirectories: true, attributes: nil
            )
            let fileurl = tmpurl.appendingPathComponent(sender.mFile!.mName)
            try sender.mFile?.mContent?.write(to: fileurl)
            mCurrentFileUrl = fileurl
            
            let previewController = QLPreviewController()
            previewController.dataSource = self
            present(previewController, animated: true)
        } catch {
            print(error)
        }
    }
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return mCurrentFileUrl! as QLPreviewItem
    }
    
    @objc func onClickVoucherButton(sender: VoucherButton!) {
        let detailViewController = storyboard?.instantiateViewController(withIdentifier:"VoucherDetailsNavigationViewController") as! UINavigationController
        if let vdvc = detailViewController.viewControllers.first as? VoucherDetailsViewController {
            vdvc.mCurrentVoucherId = sender.mVoucher!.mId
        }
        splitViewController?.showDetailViewController(detailViewController, sender: nil)
    }
    
    @objc func onClickAppointmentButton(sender: AppointmentButton!) {
        let detailViewController = storyboard?.instantiateViewController(withIdentifier:"AppointmentEditNavigationViewController") as! UINavigationController
        if let vdvc = detailViewController.viewControllers.first as? AppointmentEditViewController {
            vdvc.mCurrentAppointment = sender.mAppointment
        }
        splitViewController?.showDetailViewController(detailViewController, sender: nil)
    }
}

class SecondaryLabel: UILabel {
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        self.commonInit()

    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    func commonInit() {
        if #available(iOS 13.0, *) {
            textColor = UIColor.secondaryLabel
        } else {
            textColor = UIColor.gray
        }
    }
}

class FileButton: UIButton {
    var mFile: CustomerFile?
    required init(file:CustomerFile) {
        super.init(frame: .zero)
        mFile = file
        setTitle(file.mName, for: .normal)
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
class VoucherButton: UIButton {
    var mVoucher: Voucher?
    required init(voucher:Voucher) {
        super.init(frame: .zero)
        mVoucher = voucher
        let currency:String = UserDefaults.standard.string(forKey: "currency") ?? ""
        if(voucher.mVoucherNo != "") {
            setTitle("#"+voucher.mVoucherNo+" ("+Voucher.format(value: voucher.mCurrentValue)+" "+currency+")", for: .normal)
        } else {
            setTitle("#"+String(voucher.mId)+" ("+Voucher.format(value: voucher.mCurrentValue)+" "+currency+")", for: .normal)
        }
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
class AppointmentButton: UIButton {
    var mAppointment: CustomerAppointment?
    required init(appointment:CustomerAppointment) {
        super.init(frame: .zero)
        mAppointment = appointment
        setTitle(CustomerDatabase.dateToDisplayString(date: appointment.mTimeStart ?? Date())+" - "+appointment.mTitle, for: .normal)
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
extension String {
    func safeAddingPercentEncoding(withAllowedCharacters allowedCharacters: CharacterSet) -> String? {
        // using a copy to workaround magic: https://stackoverflow.com/q/44754996/1033581
        let allowedCharacters = CharacterSet(bitmapRepresentation: allowedCharacters.bitmapRepresentation)
        return addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }
}
