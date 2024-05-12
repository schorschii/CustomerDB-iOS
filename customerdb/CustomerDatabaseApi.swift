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
    
    func sync(diffSince:Date?=nil) {
        putCustomers(diffSince: diffSince)
    }
    
    private func putCustomers(diffSince:Date?=nil) {
        var customersDataArray:[[String:Any?]] = []
        for customer in mDb.getCustomers(search: nil, showDeleted: true, withFiles: true, modifiedSince: diffSince) {
            var customerFilesDataArray:[[String:Any?]] = []
            for file in customer.getFiles() {
                if file.mContent != nil {
                    customerFilesDataArray.append([
                        "name": file.mName,
                        "content": file.mContent!.base64EncodedString()
                    ])
                }
            }
            let filesJson = (try? JSONSerialization.data(withJSONObject: customerFilesDataArray))!
            
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
                "birthday": customer.mBirthday==nil ? nil : CustomerDatabase.dateToStringRaw(date: customer.mBirthday!),
                "customer_group": customer.mGroup,
                "newsletter": customer.mNewsletter ? 1 : 0,
                "notes": customer.mNotes,
                "custom_fields": customer.mCustomFields,
                "image": customer.mImage==nil ? nil : customer.mImage!.base64EncodedString(),
                "consent": nil,
                "files": customerFilesDataArray.count==0 ? nil : String(decoding:filesJson, as:UTF8.self),
                "last_modified": CustomerDatabase.dateToString(date: customer.mLastModified),
                "removed": customer.mRemoved
            ])
        }
        
        var calendarsDataArray:[[String:Any?]] = []
        for calendar in mDb.getCalendars(showDeleted: true) {
            calendarsDataArray.append([
                "id": calendar.mId,
                "title": calendar.mTitle,
                "color": calendar.mColor,
                "notes": calendar.mNotes,
                "last_modified": CustomerDatabase.dateToString(date: calendar.mLastModified),
                "removed": calendar.mRemoved,
            ])
        }
        
        var appointmentsDataArray:[[String:Any?]] = []
        for appointment in mDb.getAppointments(calendarId: nil, day: nil, showDeleted: true, modifiedSince: diffSince) {
            appointmentsDataArray.append([
                "id": appointment.mId,
                "calendar_id": appointment.mCalendarId,
                "title": appointment.mTitle,
                "notes": appointment.mNotes,
                "time_start": ((appointment.mTimeStart == nil) ? nil : CustomerDatabase.dateToStringRaw(date: appointment.mTimeStart!)),
                "time_end": ((appointment.mTimeEnd == nil) ? nil : CustomerDatabase.dateToStringRaw(date: appointment.mTimeEnd!)),
                "fullday": appointment.mFullday,
                "customer": appointment.mCustomer,
                "customer_id": appointment.mCustomerId,
                "location": appointment.mLocation,
                "last_modified": CustomerDatabase.dateToString(date: appointment.mLastModified),
                "removed": appointment.mRemoved,
            ])
        }
        
        var vouchersDataArray:[[String:Any?]] = []
        for voucher in mDb.getVouchers(showDeleted: true, modifiedSince: diffSince) {
            vouchersDataArray.append([
                "id": voucher.mId,
                "original_value": voucher.mOriginalValue,
                "current_value": voucher.mCurrentValue,
                "voucher_no": voucher.mVoucherNo,
                "from_customer": voucher.mFromCustomer,
                "from_customer_id": voucher.mFromCustomerId,
                "for_customer": voucher.mForCustomer,
                "for_customer_id": voucher.mForCustomerId,
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
                "vouchers": vouchersDataArray,
                "calendars": calendarsDataArray,
                "appointments": appointmentsDataArray
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
            self.parsePutCustomersResponse(response:data, diffSince:diffSince)
        }

        task.resume()
    }
    func parsePutCustomersResponse(response:Data, diffSince:Date?) {
        do {
            if let response = try JSONSerialization.jsonObject(with: response, options: []) as? [String : Any] {
                if let result = response["result"] as? Bool {
                    if(result == true) {
                        readCustomers(diffSince: diffSince)
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
        } catch let error {
            print(error.localizedDescription)
            if(delegate != nil) {
                delegate?.queueFinished(success: false, message: error.localizedDescription)
            }
        }

        if(delegate != nil) {
            delegate?.queueFinished(success: false, message: String(data:response, encoding: .utf8))
        }
    }
    
    private func readCustomers(diffSince:Date?) {
        let json: [String:Any?] = [
            "jsonrpc":"2.0",
            "id":1,
            "method":"customerdb.read",
            "params":[
                "username": mUsername,
                "password": mPassword,
                "appstore_receipt": mReceipt,
                "diff_since": CustomerDatabase.dateToString(date: diffSince),
                "files": false
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
            mDb.beginTransaction()
            
            if let response = try JSONSerialization.jsonObject(with: response, options: []) as? [String : Any] {
                if let result = response["result"] as? [String:Any] {
                    if let customers = result["customers"] as? [[String:Any]] {
                        for customer in customers {
                            let c = Customer()
                            c.mFiles = []
                            for (key, value) in customer {
                                var parsedValue = ""
                                if let int64Value = value as? Int64 {
                                    parsedValue = String(int64Value)
                                } else if let strValue = value as? String {
                                    parsedValue = strValue
                                }
                                c.putAttribute(key: key, value: parsedValue)
                            }
                            if(mDb.getCustomer(id: c.mId, showDeleted: true) == nil) {
                                _ = mDb.insertCustomer(c: c, transact: false)
                            } else {
                                _ = mDb.updateCustomer(c: c, transact: false)
                            }
                            if(!(customer["files"] is NSNull)) {
                                try readCustomer(customerId: c.mId)
                            }
                        }
                    }
                    
                    if let calendars = result["calendars"] as? [[String:Any]] {
                        for calendar in calendars {
                            let c = CustomerCalendar()
                            for (key, value) in calendar {
                                var parsedValue = ""
                                if let int64Value = value as? Int64 {
                                    parsedValue = String(int64Value)
                                } else if let strValue = value as? String {
                                    parsedValue = strValue
                                }
                                c.putAttribute(key: key, value: parsedValue)
                            }
                            if(mDb.getCalendar(id: c.mId, showDeleted: true) == nil) {
                                _ = mDb.insertCalendar(c: c)
                            } else {
                                _ = mDb.updateCalendar(c: c)
                            }
                        }
                    }
                    
                    if let appointments = result["appointments"] as? [[String:Any]] {
                        for appointment in appointments {
                            let a = CustomerAppointment()
                            for (key, value) in appointment {
                                var parsedValue = ""
                                if let int64Value = value as? Int64 {
                                    parsedValue = String(int64Value)
                                } else if let strValue = value as? String {
                                    parsedValue = strValue
                                }
                                a.putAttribute(key: key, value: parsedValue)
                            }
                            if(mDb.getAppointment(id: a.mId, showDeleted: true) == nil) {
                                _ = mDb.insertAppointment(a: a)
                            } else {
                                _ = mDb.updateAppointment(a: a)
                            }
                        }
                    }
                    
                    if let vouchers = result["vouchers"] as? [[String:Any]] {
                        for voucher in vouchers {
                            let v = Voucher()
                            for (key, value) in voucher {
                                var parsedValue = ""
                                if let int64Value = value as? Int64 {
                                    parsedValue = String(int64Value)
                                } else if let doubleValue = value as? Double {
                                    parsedValue = String(doubleValue)
                                } else if let strValue = value as? String {
                                    parsedValue = strValue
                                }
                                v.putAttribute(key: key, value: parsedValue)
                            }
                            if(mDb.getVoucher(id: v.mId, showDeleted: true) == nil) {
                                _ = mDb.insertVoucher(v: v)
                            } else {
                                _ = mDb.updateVoucher(v: v)
                            }
                        }
                    }
                    
                    mDb.commitTransaction()
                    
                    if(delegate != nil) {
                        UserDefaults.standard.set(false, forKey: "unsynced-changes")
                        delegate?.queueFinished(success: true, message: nil)
                    }
                    return
                } else {
                    mDb.rollbackTransaction()
                    
                    if let message = response["error"] as? String {
                        if(delegate != nil) {
                            delegate?.queueFinished(success: false, message: message)
                        }
                        return
                    }
                }
            }
        } catch let error {
            mDb.rollbackTransaction()
            
            print(error.localizedDescription)
            if(delegate != nil) {
                delegate?.queueFinished(success: false, message: error.localizedDescription)
            }
        }
        
        if(delegate != nil) {
            delegate?.queueFinished(success: false, message: String(data:response, encoding: .utf8))
        }
    }
    
    private func readCustomer(customerId:Int64) throws {
        let json: [String:Any?] = [
            "jsonrpc":"2.0",
            "id":1,
            "method":"customerdb.read.customer",
            "params":[
                "username": mUsername,
                "password": mPassword,
                "appstore_receipt": mReceipt,
                "customer_id": customerId
            ] as [String:Any?]
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        
        let url = URL(string: mUrl)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let queue = OperationQueue()
        queue.name = "queue2"
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: queue)
        let c = Customer()
        let sem = DispatchSemaphore.init(value: 0) // wait before executing next to avoid multithread database access error
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                if(self.delegate != nil) {
                    self.delegate?.queueFinished(success: false, message: error?.localizedDescription)
                }
                sem.signal()
                return
            }
            //print(String(decoding:data, as: UTF8.self))
            do {
                if let response = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] {
                    if let result = response["result"] as? [String:Any] {
                        for (key, value) in result {
                            var parsedValue = ""
                            if let int64Value = value as? Int64 {
                                parsedValue = String(int64Value)
                            } else if let strValue = value as? String {
                                parsedValue = strValue
                            }
                            c.putAttribute(key: key, value: parsedValue)
                        }
                        _ = self.mDb.updateCustomer(c: c, transact: false)
                    }
                }
            } catch let error {
                print(error)
            }
            sem.signal()
        }
        
        task.resume()
        sem.wait()
    }
    
    func tryInt32(_ inVal:Int) -> Int32 {
        if(inVal < 0) {
            return 0
        } else {
            return Int32(inVal)
        }
    }
    
}
