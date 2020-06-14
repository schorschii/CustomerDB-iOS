//
//  CustomerDatabaseApi.swift
//  Copyright © 2019 Georg Sieber. All rights reserved.
//

import Foundation

protocol RequestFinishedListener {
    func queueFinished(success:Bool, message:String?)
}

class CustomerDatabaseApi {
    
    static var MANAGED_API = "https://customerdb.sieber.systems/api.php"
    
    var mUrl = ""
    var mUsername = ""
    var mPassword = ""
    var mReceipt:String? = "nil"
    
    var delegate: RequestFinishedListener? = nil
    var queueFinished: (() -> ())? = nil
    
    let mDb:CustomerDatabase
    
    init(db:CustomerDatabase, username:String, password:String) {
        mDb = db
        mUrl = CustomerDatabaseApi.MANAGED_API
        mUsername = username
        mPassword = password
        initReceipt()
    }
    init(db:CustomerDatabase, url:String, username:String, password:String) {
        mDb = db
        mUrl = url
        mUsername = username
        mPassword = password
        initReceipt()
    }
    
    func initReceipt() {
        let receiptPath = Bundle.main.appStoreReceiptURL?.path
        if FileManager.default.fileExists(atPath: receiptPath!) {
            var receiptData:NSData?
            do {
                receiptData = try NSData(
                    contentsOf: Bundle.main.appStoreReceiptURL!,
                    options: NSData.ReadingOptions.alwaysMapped
                )
                let base64encodedReceipt = receiptData?.base64EncodedString(
                    options: NSData.Base64EncodingOptions.endLineWithCarriageReturn
                )
                mReceipt = base64encodedReceipt
            } catch {
                print("RECEIPT ERROR: " + error.localizedDescription)
            }
        }
    }
    
    func sync() {
        putCustomers()
    }
    
    private func putCustomers() {
        var customersDataArray:[[String:Any?]] = []
        for customer in mDb.getAllCustomers() {
            customersDataArray.append([
                "id": customer.mId,
                "title": customer.mTitle,
                "first_name": customer.mFirstName,
                "last_name": customer.mLastName,
                "phone_home": customer.mPhoneHome,
                "phone_mobile": customer.mPhoneMobile,
                "phone_work": customer.mPhoneWork,
                "email": customer.mEmail,
                "street": customer.mStreet,
                "zipcode": customer.mZipcode,
                "city": customer.mCity,
                "country": customer.mCountry,
                "birthday": customer.mBirthday==nil ? nil : CustomerDatabase.dateToString(date: customer.mBirthday!),
                "customer_group": customer.mGroup,
                "newsletter": customer.mNewsletter,
                "notes": customer.mNotes,
                "custom_fields": customer.mCustomFields,
                "image": customer.mImage==nil ? nil : customer.mImage!.base64EncodedString(),
                "consent": customer.mConsentImage==nil ? nil : customer.mConsentImage!.base64EncodedString(),
                "last_modified": CustomerDatabase.dateToString(date: customer.mLastModified),
                "removed": customer.mRemoved
            ])
        }
        
        var vouchersDataArray:[[String:Any?]] = []
        for voucher in mDb.getVouchers(showDeleted: true) {
            vouchersDataArray.append([
                "id": voucher.mId,
                "original_value": voucher.mOriginalValue,
                "current_value": voucher.mCurrentValue,
                "voucher_no": voucher.mVoucherNo,
                "from_customer": voucher.mFromCustomer,
                "for_customer": voucher.mForCustomer,
                "issued": CustomerDatabase.dateToString(date: voucher.mIssued),
                "valid_until": ((voucher.mValidUntil == nil) ? nil : CustomerDatabase.dateToString(date: voucher.mValidUntil!)),
                "redeemed": ((voucher.mRedeemed == nil) ? nil : CustomerDatabase.dateToString(date: voucher.mRedeemed!)),
                "notes": voucher.mNotes,
                "last_modified": CustomerDatabase.dateToString(date: voucher.mLastModified),
                "removed": voucher.mRemoved
            ])
        }
        
        let json: [String:Any?] = [
            "jsonrpc": "2.0",
            "id": 1,
            "method": "customerdb.put",
            "params": [
                "username": mUsername,
                "password": mPassword,
                "appstore_receipt": mReceipt,
                "customers": customersDataArray,
                "vouchers": vouchersDataArray
                ] as [String:Any?]
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        let url = URL(string: mUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        //print(String(data: jsonData!, encoding: .utf8)!)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                if(self.delegate != nil) {
                    self.delegate?.queueFinished(success: false, message: error?.localizedDescription)
                }
                return
            }
            //print(String(decoding:data, as: UTF8.self))
            self.parsePutCustomersResponse(response:data)
        }

        task.resume()
    }
    func parsePutCustomersResponse(response:Data) {
        do {
            if let response = try JSONSerialization.jsonObject(with: response, options: []) as? [String : Any] {
                if let result = response["result"] as? Bool {
                    if(result == true) {
                        readCustomers()
                        return
                    }
                } else {
                    if let message = response["error"] as? String {
                        if(delegate != nil) {
                            delegate?.queueFinished(success: false, message: message)
                        }
                        return
                    }
                }
            }
        } catch {}

        if(delegate != nil) {
            delegate?.queueFinished(success: false, message: String(data:response, encoding: .utf8))
        }
    }
    
    private func readCustomers() {
        let json: [String:Any?] = [
            "jsonrpc":"2.0",
            "id":1,
            "method":"customerdb.read",
            "params":[
                "username": mUsername,
                "password": mPassword,
                "appstore_receipt": mReceipt
            ] as [String:Any?]
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)

        let url = URL(string: mUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                if(self.delegate != nil) {
                    self.delegate?.queueFinished(success: false, message: error?.localizedDescription)
                }
                return
            }
            //print(String(decoding:data, as: UTF8.self))
            self.parseReadCustomersResponse(response:data)
        }

        task.resume()
    }
    func parseReadCustomersResponse(response:Data) {
        do {
            if let response = try JSONSerialization.jsonObject(with: response, options: []) as? [String : Any] {
                if let result = response["result"] as? [String:Any] {
                    if let customers = result["customers"] as? [[String:Any]] {
                        for customer in customers {
                            let id = customer["id"] as! Int64
                            let title = customer["title"] as! String
                            let firstName = customer["first_name"] as! String
                            let lastName = customer["last_name"] as! String
                            let phoneHome = customer["phone_home"] as! String
                            let phoneMobile = customer["phone_mobile"] as! String
                            let phoneWork = customer["phone_work"] as! String
                            let email = customer["email"] as! String
                            let street = customer["street"] as! String
                            let zipcode = customer["zipcode"] as! String
                            let city = customer["city"] as! String
                            let country = customer["country"] as! String
                            let strBirthday = customer["birthday"] as? String
                            //let birthday = CustomerDatabase.parseDate(strDate: strBirthday)
                            let customerGroup = customer["customer_group"] as! String
                            let newsletter = customer["newsletter"] as! Int
                            let notes = customer["notes"] as! String
                            let customFields = customer["custom_fields"] as! String
                            let base64Image = customer["image"] as? String
                            var image:Data? = nil
                            if(base64Image != nil) {
                                image = Data(base64Encoded: base64Image!, options: .ignoreUnknownCharacters)
                            }
                            let base64ConsentImage = customer["consent"] as? String
                            var consentImage:Data? = nil
                            if(base64ConsentImage != nil) {
                                consentImage = Data(base64Encoded: base64ConsentImage!, options: .ignoreUnknownCharacters)
                            }
                            let strLastModified = customer["last_modified"] as! String
                            //let lastModified = CustomerDatabase.parseDate(strDate: strLastModified) ?? Date()
                            let removed = customer["removed"] as! Int
                            _ = mDb.insertUpdateCustomerRecord(
                                id: id,
                                title: title,
                                firstName: firstName,
                                lastName: lastName,
                                phoneHome: phoneHome,
                                phoneMobile: phoneMobile,
                                phoneWork: phoneWork,
                                email: email,
                                street: street,
                                zipcode: zipcode,
                                city: city,
                                country: country,
                                birthday: strBirthday,
                                notes: notes,
                                newsletter: newsletter,
                                group: customerGroup,
                                customFields: customFields,
                                image: image,
                                consentImage: consentImage,
                                lastModified: strLastModified,
                                removed: removed
                            )
                        }
                    }
                    
                    if let vouchers = result["vouchers"] as? [[String:Any]] {
                        for voucher in vouchers {
                            let id = voucher["id"] as! Int64
                            let originalValue = voucher["original_value"] as! Double
                            let currentValue = voucher["current_value"] as! Double
                            let voucherNo = voucher["voucher_no"] as! String
                            let fromCustomer = voucher["from_customer"] as! String
                            let forCustomer = voucher["for_customer"] as! String
                            let strIssued = voucher["issued"] as! String
                            //let issued = CustomerDatabase.parseDate(strDate: strIssued) ?? Date()
                            let strValidUntil = voucher["valid_until"] as? String
                            //let validUntil = CustomerDatabase.parseDate(strDate: strValidUntil)
                            let strRedeemed = voucher["redeemed"] as? String
                            //let redeemed = CustomerDatabase.parseDate(strDate: strRedeemed)
                            let notes = voucher["notes"] as! String
                            let strLastModified = voucher["last_modified"] as! String
                            //let lastModified = CustomerDatabase.parseDate(strDate: strLastModified) ?? Date()
                            let removed = voucher["removed"] as! Int
                            _ = mDb.insertUpdateVoucherRecord(
                                id: id,
                                originalValue: originalValue,
                                currentValue: currentValue,
                                voucherNo: voucherNo,
                                fromCustomer: fromCustomer,
                                forCustomer: forCustomer,
                                issued: strIssued,
                                validUntil: strValidUntil,
                                redeemed: strRedeemed,
                                notes: notes,
                                lastModified: strLastModified,
                                removed: removed
                            )
                        }
                    }
                    
                    if(delegate != nil) {
                        UserDefaults.standard.set(false, forKey: "unsynced-changes")
                        delegate?.queueFinished(success: true, message: nil)
                    }
                    return
                } else {
                    if let message = response["error"] as? String {
                        if(delegate != nil) {
                            delegate?.queueFinished(success: false, message: message)
                        }
                        return
                    }
                }
            }
        } catch {}
        
        if(delegate != nil) {
            delegate?.queueFinished(success: false, message: String(data:response, encoding: .utf8))
        }
    }
    
    func tryInt32(_ inVal:Int) -> Int32 {
        if(inVal < 0) {
            return 0
        } else {
            return Int32(inVal)
        }
    }
    
}
