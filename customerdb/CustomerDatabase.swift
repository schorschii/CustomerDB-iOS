//
//  CustomerDatabase.swift - sqlite interface
//  Copyright © 2019 Georg Sieber. All rights reserved.
//

import Foundation
import SQLite3

class CustomerDatabase {
    
    static var DB_FILE = "customerdb.sqlite"
    static var CREATE_DB_STATEMENTS = [
        "CREATE TABLE IF NOT EXISTS customer (id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR NOT NULL, first_name VARCHAR NOT NULL, last_name VARCHAR NOT NULL, phone_home VARCHAR NOT NULL, phone_mobile VARCHAR NOT NULL, phone_work VARCHAR NOT NULL, email VARCHAR NOT NULL, street VARCHAR NOT NULL, zipcode VARCHAR NOT NULL, city VARCHAR NOT NULL, country VARCHAR NOT NULL, birthday DATETIME, notes VARCHAR NOT NULL, newsletter INTEGER DEFAULT 0 NOT NULL, customer_group VARCHAR NOT NULL, custom_fields VARCHAR NOT NULL, image BLOB, consent BLOB, last_modified DATETIME NOT NULL, removed INTEGER DEFAULT 0 NOT NULL);",
        "CREATE TABLE IF NOT EXISTS customer_extra_fields (id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR UNIQUE NOT NULL, type INTEGER NOT NULL, last_modified DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL, removed INTEGER DEFAULT 0 NOT NULL);",
        "CREATE TABLE IF NOT EXISTS customer_extra_presets (id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR NOT NULL, extra_field_id INTEGER NOT NULL);",
        
        "CREATE TABLE IF NOT EXISTS voucher (id INTEGER PRIMARY KEY AUTOINCREMENT, current_value REAL NOT NULL, original_value REAL NOT NULL, voucher_no VARCHAR NOT NULL, from_customer VARCHAR NOT NULL, for_customer VARCHAR NOT NULL, issued DATETIME NOT NULL, valid_until DATETIME DEFAULT NULL, redeemed DATETIME DEFAULT NULL, last_modified DATETIME NOT NULL, notes VARCHAR NOT NULL, removed INTEGER DEFAULT 0 NOT NULL);",
        
        //"CREATE TABLE IF NOT EXISTS calendar (id INTEGER PRIMARY KEY AUTOINCREMENT, title VARCHAR, color VARCHAR, last_modified INTEGER, removed INTEGER DEFAULT 0);",
        //"CREATE TABLE IF NOT EXISTS calendar_item (id INTEGER PRIMARY KEY AUTOINCREMENT, calendar_id INTEGER, fullday INTEGER, start INTEGER, end INTEGER, title VARCHAR, notes VARCHAR, customer INTEGER, last_modified INTEGER, removed INTEGER DEFAULT 0);",
    ]
    
    var db: OpaquePointer?
    
    init() {
        let fileurl = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent(CustomerDatabase.DB_FILE)
        
        if(sqlite3_open(fileurl.path, &db) != SQLITE_OK) {
            print("error opening database "+fileurl.path)
        }
        for query in CustomerDatabase.CREATE_DB_STATEMENTS {
            if(sqlite3_exec(db, query, nil,nil,nil) != SQLITE_OK) {
                print("error creating table: "+String(cString: sqlite3_errmsg(db)!))
            }
        }
    }
    
    static var STORAGE_FORMAT = "yyyy-MM-dd HH:mm:ss"
    static func dateToDisplayString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
    static func dateToDisplayStringWithoutTime(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: date)
    }
    static func dateToString(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = CustomerDatabase.STORAGE_FORMAT
        return dateFormatter.string(from: date)
    }/*
    static func unixTimeToString(unixTimestamp: Int) -> String {
        return CustomerDatabase.dateToString(date: Date(timeIntervalSince1970: Double(unixTimestamp)))
    }*/
    static func parseDisplayDateWithoutTime(strDate: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        return dateFormatter.date(from:strDate)
    }
    static func parseDate(strDate: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = CustomerDatabase.STORAGE_FORMAT
        return dateFormatter.date(from:strDate)
    }
    static func parseDateToTimestamp(strDate: String) -> Int {
        return Int((CustomerDatabase.parseDate(strDate: strDate) ?? Date()).timeIntervalSince1970)
    }
    
    // Customer Operations
    func getCustomers(showDeleted:Bool) -> [Customer] {
        var customers:[Customer] = []
        var stmt:OpaquePointer?
        var sql = "SELECT id, title, first_name, last_name, phone_home, phone_mobile, phone_work, email, street, zipcode, city, country, birthday, customer_group, newsletter, notes, custom_fields, last_modified, removed FROM customer WHERE removed = 0 ORDER BY last_name, first_name"
        if(showDeleted) {
            sql = "SELECT id, title, first_name, last_name, phone_home, phone_mobile, phone_work, email, street, zipcode, city, country, birthday, customer_group, newsletter, notes, custom_fields, last_modified, removed FROM customer ORDER BY last_name, first_name"
        }
        if sqlite3_prepare(self.db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                var birthday:Date? = nil
                if(sqlite3_column_text(stmt, 12) != nil) {
                    birthday = CustomerDatabase.parseDate(strDate: String(cString: sqlite3_column_text(stmt, 12)))
                }
                customers.append(
                    Customer(
                        id: Int64(sqlite3_column_int64(stmt, 0)),
                        title: String(cString: sqlite3_column_text(stmt, 1)),
                        firstName: String(cString: sqlite3_column_text(stmt, 2)),
                        lastName: String(cString: sqlite3_column_text(stmt, 3)),
                        phoneHome: String(cString: sqlite3_column_text(stmt, 4)),
                        phoneMobile: String(cString: sqlite3_column_text(stmt, 5)),
                        phoneWork: String(cString: sqlite3_column_text(stmt, 6)),
                        email: String(cString: sqlite3_column_text(stmt, 7)),
                        street: String(cString: sqlite3_column_text(stmt, 8)),
                        zipcode: String(cString: sqlite3_column_text(stmt, 9)),
                        city: String(cString: sqlite3_column_text(stmt, 10)),
                        country: String(cString: sqlite3_column_text(stmt, 11)),
                        birthday: birthday,
                        group: String(cString: sqlite3_column_text(stmt, 13)),
                        newsletter: Int(sqlite3_column_int(stmt, 14)) > 0,
                        notes: String(cString: sqlite3_column_text(stmt, 15)),
                        customFields: String(cString: sqlite3_column_text(stmt, 16)),
                        lastModified: CustomerDatabase.parseDate(strDate: String(cString: sqlite3_column_text(stmt, 17))) ?? Date(),
                        removed: Int(sqlite3_column_int(stmt, 18))
                    )
                )
            }
        }
        return customers
    }
    func getCustomer(id:Int64) -> Customer? {
        var customer:Customer? = nil
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "SELECT id, title, first_name, last_name, phone_home, phone_mobile, phone_work, email, street, zipcode, city, country, birthday, customer_group, newsletter, notes, custom_fields, image, consent, last_modified, removed FROM customer WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, id)
            while sqlite3_step(stmt) == SQLITE_ROW {
                var birthday:Date? = nil
                var image:Data? = nil
                var consent:Data? = nil
                if(sqlite3_column_text(stmt, 12) != nil) {
                    birthday = CustomerDatabase.parseDate(strDate: String(cString: sqlite3_column_text(stmt, 12)))
                }
                if let pointer = sqlite3_column_blob(stmt, 17) {
                    let length = Int(sqlite3_column_bytes(stmt, 17))
                    image = Data(bytes: pointer, count: length)
                }
                if let pointer = sqlite3_column_blob(stmt, 18) {
                    let length = Int(sqlite3_column_bytes(stmt, 18))
                    consent = Data(bytes: pointer, count: length)
                }
                customer = (
                    Customer(
                        id: Int64(sqlite3_column_int64(stmt, 0)),
                        title: String(cString: sqlite3_column_text(stmt, 1)),
                        firstName: String(cString: sqlite3_column_text(stmt, 2)),
                        lastName: String(cString: sqlite3_column_text(stmt, 3)),
                        phoneHome: String(cString: sqlite3_column_text(stmt, 4)),
                        phoneMobile: String(cString: sqlite3_column_text(stmt, 5)),
                        phoneWork: String(cString: sqlite3_column_text(stmt, 6)),
                        email: String(cString: sqlite3_column_text(stmt, 7)),
                        street: String(cString: sqlite3_column_text(stmt, 8)),
                        zipcode: String(cString: sqlite3_column_text(stmt, 9)),
                        city: String(cString: sqlite3_column_text(stmt, 10)),
                        country: String(cString: sqlite3_column_text(stmt, 11)),
                        birthday: birthday,
                        group: String(cString: sqlite3_column_text(stmt, 13)),
                        newsletter: Int(sqlite3_column_int(stmt, 14)) > 0,
                        notes: String(cString: sqlite3_column_text(stmt, 15)),
                        customFields: String(cString: sqlite3_column_text(stmt, 16)),
                        image: image,
                        consentImage: consent,
                        lastModified: CustomerDatabase.parseDate(strDate: String(cString: sqlite3_column_text(stmt, 19))) ?? Date(),
                        removed: Int(sqlite3_column_int(stmt, 20))
                    )
                )
            }
        }
        return customer
    }
    func updateCustomer(c: Customer) -> Bool {
        sqlite3_exec(self.db, "BEGIN EXCLUSIVE TRANSACTION", nil, nil, nil)
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "UPDATE customer SET title = ?, first_name = ?, last_name = ?, phone_home = ?, phone_mobile = ?, phone_work = ?, email = ?, street = ?, zipcode = ?, city = ?, country = ?, birthday = ?, notes = ?, newsletter = ?, customer_group = ?, custom_fields = ?, image = ?, consent = ?, last_modified = ? WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            let title = c.mTitle as NSString
            let firstName = c.mFirstName as NSString
            let lastName = c.mLastName as NSString
            let phoneHome = c.mPhoneHome as NSString
            let phoneMobile = c.mPhoneMobile as NSString
            let phoneWork = c.mPhoneWork as NSString
            let email = c.mEmail as NSString
            let street = c.mStreet as NSString
            let zipcode = c.mZipcode as NSString
            let city = c.mCity as NSString
            let country = c.mCountry as NSString
            let birthday:NSString? = (c.mBirthday==nil) ? nil : CustomerDatabase.dateToString(date: c.mBirthday!) as NSString
            let notes = c.mNotes as NSString
            let group = c.mGroup as NSString
            let customFields = c.mCustomFields as NSString
            let lastModified = CustomerDatabase.dateToString(date: c.mLastModified) as NSString
            sqlite3_bind_text(stmt, 1, title.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 2, firstName.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, lastName.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, phoneHome.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, phoneMobile.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 6, phoneWork.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 7, email.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 8, street.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 9, zipcode.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 10, city.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 11, country.utf8String, -1, nil)
            if(birthday == nil) {
                sqlite3_bind_null(stmt, 12)
            } else {
                sqlite3_bind_text(stmt, 12, birthday!.utf8String, -1, nil)
            }
            sqlite3_bind_text(stmt, 13, notes.utf8String, -1, nil)
            sqlite3_bind_int(stmt, 14, c.mNewsletter ? 1 : 0)
            sqlite3_bind_text(stmt, 15, group.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 16, customFields.utf8String, -1, nil)
            if(c.mImage == nil) {
                sqlite3_bind_null(stmt, 17)
            } else {
                let tempData: NSMutableData = NSMutableData(length: 0)!
                tempData.append(c.mImage!)
                sqlite3_bind_blob(stmt, 17, tempData.bytes, Int32(tempData.length), nil)
            }
            if(c.mConsentImage == nil) {
                sqlite3_bind_null(stmt, 18)
            } else {
                let tempData: NSMutableData = NSMutableData(length: 0)!
                tempData.append(c.mConsentImage!)
                sqlite3_bind_blob(stmt, 18, tempData.bytes, Int32(tempData.length), nil)
            }
            sqlite3_bind_text(stmt, 19, lastModified.utf8String, -1, nil)
            sqlite3_bind_int64(stmt, 20, c.mId)
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
        sqlite3_exec(self.db, "COMMIT TRANSACTION", nil, nil, nil)
        return true
    }
    func insertCustomer(c: Customer) -> Bool {
        sqlite3_exec(self.db, "BEGIN EXCLUSIVE TRANSACTION", nil, nil, nil)
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "INSERT INTO customer (id, title, first_name, last_name, phone_home, phone_mobile, phone_work, email, street, zipcode, city, country, birthday, notes, newsletter, customer_group, custom_fields, image, consent, last_modified, removed) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,0)", -1, &stmt, nil) == SQLITE_OK {
            let title = c.mTitle as NSString
            let firstName = c.mFirstName as NSString
            let lastName = c.mLastName as NSString
            let phoneHome = c.mPhoneHome as NSString
            let phoneMobile = c.mPhoneMobile as NSString
            let phoneWork = c.mPhoneWork as NSString
            let email = c.mEmail as NSString
            let street = c.mStreet as NSString
            let zipcode = c.mZipcode as NSString
            let city = c.mCity as NSString
            let country = c.mCountry as NSString
            let notes = c.mNotes as NSString
            let group = c.mGroup as NSString
            let customFields = c.mCustomFields as NSString
            let lastModified = CustomerDatabase.dateToString(date: c.mLastModified) as NSString
            sqlite3_bind_int64(stmt, 1, c.mId)
            sqlite3_bind_text(stmt, 2, title.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 3, firstName.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, lastName.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, phoneHome.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 6, phoneMobile.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 7, phoneWork.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 8, email.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 9, street.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 10, zipcode.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 11, city.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 12, country.utf8String, -1, nil)
            if(c.mBirthday == nil) {
                sqlite3_bind_null(stmt, 13)
            } else {
                sqlite3_bind_text(stmt, 13, CustomerDatabase.dateToString(date: c.mBirthday!), -1, nil)
            }
            sqlite3_bind_text(stmt, 14, notes.utf8String, -1, nil)
            sqlite3_bind_int(stmt, 15, c.mNewsletter ? 1 : 0)
            sqlite3_bind_text(stmt, 16, group.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 17, customFields.utf8String, -1, nil)
            if(c.mImage == nil) {
                sqlite3_bind_null(stmt, 18)
            } else {
                let tempData: NSMutableData = NSMutableData(length: 0)!
                tempData.append(c.mImage!)
                sqlite3_bind_blob(stmt, 18, tempData.bytes, Int32(tempData.length), nil)
            }
            if(c.mConsentImage == nil) {
                sqlite3_bind_null(stmt, 19)
            } else {
                let tempData: NSMutableData = NSMutableData(length: 0)!
                tempData.append(c.mConsentImage!)
                sqlite3_bind_blob(stmt, 19, tempData.bytes, Int32(tempData.length), nil)
            }
            sqlite3_bind_text(stmt, 20, lastModified.utf8String, -1, nil)
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
        sqlite3_exec(self.db, "COMMIT TRANSACTION", nil, nil, nil)
        return true
    }
    func removeCustomer(id: Int64) {
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "UPDATE customer SET title = '', first_name = '', last_name = '', custom_fields = '', image = '', consent = '', last_modified = ?, removed = 1 WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            let lastModified = CustomerDatabase.dateToString(date: Date()) as NSString
            sqlite3_bind_text(stmt, 1, lastModified.utf8String, -1, nil)
            sqlite3_bind_int64(stmt, 2, id)
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
    }
    func deleteAllCustomer() {
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "DELETE FROM customer WHERE 1=1", -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
    }
    
    // direct customer access for API
    func getAllCustomers() -> [Customer] {
        var customers:[Customer] = []
        var stmt:OpaquePointer?
        let sql = "SELECT id, title, first_name, last_name, phone_home, phone_mobile, phone_work, email, street, zipcode, city, country, birthday, customer_group, newsletter, notes, custom_fields, image, consent, last_modified, removed FROM customer"
        if sqlite3_prepare(self.db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                var birthday:Date? = nil
                if(sqlite3_column_text(stmt, 12) != nil) {
                    birthday = CustomerDatabase.parseDate(strDate: String(cString: sqlite3_column_text(stmt, 12)))
                }
                var image:Data? = nil
                if let pointer = sqlite3_column_blob(stmt, 17) {
                    let length = Int(sqlite3_column_bytes(stmt, 17))
                    image = Data(bytes: pointer, count: length)
                }
                var consent:Data? = nil
                if let pointer = sqlite3_column_blob(stmt, 18) {
                    let length = Int(sqlite3_column_bytes(stmt, 18))
                    consent = Data(bytes: pointer, count: length)
                }
                customers.append(
                    Customer(
                        id: Int64(sqlite3_column_int64(stmt, 0)),
                        title: String(cString: sqlite3_column_text(stmt, 1)),
                        firstName: String(cString: sqlite3_column_text(stmt, 2)),
                        lastName: String(cString: sqlite3_column_text(stmt, 3)),
                        phoneHome: String(cString: sqlite3_column_text(stmt, 4)),
                        phoneMobile: String(cString: sqlite3_column_text(stmt, 5)),
                        phoneWork: String(cString: sqlite3_column_text(stmt, 6)),
                        email: String(cString: sqlite3_column_text(stmt, 7)),
                        street: String(cString: sqlite3_column_text(stmt, 8)),
                        zipcode: String(cString: sqlite3_column_text(stmt, 9)),
                        city: String(cString: sqlite3_column_text(stmt, 10)),
                        country: String(cString: sqlite3_column_text(stmt, 11)),
                        birthday: birthday,
                        group: String(cString: sqlite3_column_text(stmt, 13)),
                        newsletter: Int(sqlite3_column_int(stmt, 14)) > 0,
                        notes: String(cString: sqlite3_column_text(stmt, 15)),
                        customFields: String(cString: sqlite3_column_text(stmt, 16)),
                        image: image,
                        consentImage: consent,
                        lastModified: CustomerDatabase.parseDate(strDate: String(cString: sqlite3_column_text(stmt, 19))) ?? Date(),
                        removed: Int(sqlite3_column_int(stmt, 20))
                    )
                )
            }
        }
        return customers
    }
    func insertUpdateCustomerRecord(id:Int64, title:String, firstName:String, lastName:String, phoneHome:String, phoneMobile:String, phoneWork:String, email:String, street:String, zipcode:String, city:String, country:String, birthday:String?, notes:String, newsletter:Int, group:String, customFields:String, image:Data?, consentImage:Data?, lastModified:String, removed:Int) -> Bool {
        let title2 = title as NSString
        let firstName2 = firstName as NSString
        let lastName2 = lastName as NSString
        let phoneHome2 = phoneHome as NSString
        let phoneMobile2 = phoneMobile as NSString
        let phoneWork2 = phoneWork as NSString
        let email2 = email as NSString
        let street2 = street as NSString
        let zipcode2 = zipcode as NSString
        let city2 = city as NSString
        let country2 = country as NSString
        let birthday2:NSString? = (birthday==nil) ? nil : birthday! as NSString
        let notes2 = notes as NSString
        let group2 = group as NSString
        let customFields2 = customFields as NSString
        let lastModified2 = lastModified as NSString
        sqlite3_exec(self.db, "BEGIN EXCLUSIVE TRANSACTION", nil, nil, nil)
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "SELECT id FROM customer WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, id)
            if(sqlite3_step(stmt) == SQLITE_ROW) {
                sqlite3_finalize(stmt)
                // update
                var stmt2:OpaquePointer?
                if sqlite3_prepare(self.db, "UPDATE customer SET title = ?, first_name = ?, last_name = ?, phone_home = ?, phone_mobile = ?, phone_work = ?, email = ?, street = ?, zipcode = ?, city = ?, country = ?, birthday = ?, notes = ?, newsletter = ?, customer_group = ?, custom_fields = ?, image = ?, consent = ?, last_modified = ?, removed = ? WHERE id = ? AND last_modified < ?", -1, &stmt2, nil) == SQLITE_OK {
                    sqlite3_bind_text(stmt2, 1, title2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 2, firstName2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 3, lastName2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 4, phoneHome2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 5, phoneMobile2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 6, phoneWork2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 7, email2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 8, street2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 9, zipcode2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 10, city2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 11, country2.utf8String, -1, nil)
                    if(birthday2 == nil) {
                        sqlite3_bind_null(stmt2, 12)
                    } else {
                        sqlite3_bind_text(stmt2, 12, birthday2!.utf8String, -1, nil)
                    }
                    sqlite3_bind_text(stmt2, 13, notes2.utf8String, -1, nil)
                    sqlite3_bind_int(stmt2, 14, Int32(newsletter))
                    sqlite3_bind_text(stmt2, 15, group2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 16, customFields2.utf8String, -1, nil)
                    if(image == nil) {
                        sqlite3_bind_null(stmt2, 17)
                    } else {
                        let tempData: NSMutableData = NSMutableData(length: 0)!
                        tempData.append(image!)
                        sqlite3_bind_blob(stmt2, 17, tempData.bytes, Int32(tempData.length), nil)
                    }
                    if(consentImage == nil) {
                        sqlite3_bind_null(stmt2, 18)
                    } else {
                        let tempData: NSMutableData = NSMutableData(length: 0)!
                        tempData.append(consentImage!)
                        sqlite3_bind_blob(stmt2, 18, tempData.bytes, Int32(tempData.length), nil)
                    }
                    sqlite3_bind_text(stmt2, 19, lastModified2.utf8String, -1, nil)
                    sqlite3_bind_int(stmt2, 20, Int32(removed))
                    sqlite3_bind_int64(stmt2, 21, id)
                    sqlite3_bind_text(stmt2, 22, lastModified2.utf8String, -1, nil)
                    if sqlite3_step(stmt2) == SQLITE_DONE {
                        sqlite3_finalize(stmt2)
                    }
                }
            } else {
                // insert
                var stmt2:OpaquePointer?
                if sqlite3_prepare(self.db, "INSERT INTO customer (id, title, first_name, last_name, phone_home, phone_mobile, phone_work, email, street, zipcode, city, country, birthday, notes, newsletter, customer_group, custom_fields, image, consent, last_modified, removed) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", -1, &stmt2, nil) == SQLITE_OK {
                    sqlite3_bind_int64(stmt2, 1, id)
                    sqlite3_bind_text(stmt2, 2, title2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 3, firstName2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 4, lastName2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 5, phoneHome2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 6, phoneMobile2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 7, phoneWork2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 8, email2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 9, street2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 10, zipcode2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 11, city2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 12, country2.utf8String, -1, nil)
                    if(birthday2 == nil) {
                        sqlite3_bind_null(stmt2, 13)
                    } else {
                        sqlite3_bind_text(stmt2, 13, birthday2!.utf8String, -1, nil)
                    }
                    sqlite3_bind_text(stmt2, 14, notes2.utf8String, -1, nil)
                    sqlite3_bind_int(stmt2, 15, Int32(newsletter))
                    sqlite3_bind_text(stmt2, 16, group2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 17, customFields2.utf8String, -1, nil)
                    if(image == nil) {
                        sqlite3_bind_null(stmt2, 18)
                    } else {
                        let tempData: NSMutableData = NSMutableData(length: 0)!
                        tempData.append(image!)
                        sqlite3_bind_blob(stmt2, 18, tempData.bytes, Int32(tempData.length), nil)
                    }
                    if(consentImage == nil) {
                        sqlite3_bind_null(stmt2, 19)
                    } else {
                        let tempData: NSMutableData = NSMutableData(length: 0)!
                        tempData.append(consentImage!)
                        sqlite3_bind_blob(stmt2, 19, tempData.bytes, Int32(tempData.length), nil)
                    }
                    sqlite3_bind_text(stmt2, 20, lastModified2.utf8String, -1, nil)
                    sqlite3_bind_int(stmt2, 21, Int32(removed))
                    if sqlite3_step(stmt2) == SQLITE_DONE {
                        sqlite3_finalize(stmt2)
                    }
                }
            }
        }
        sqlite3_exec(self.db, "COMMIT TRANSACTION", nil, nil, nil)
        return true
    }
    
    // Custom Field Operations
    func getCustomFields() -> [CustomField] {
        var fields:[CustomField] = []
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "SELECT id, title, type FROM customer_extra_fields", -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                fields.append(
                    CustomField(
                        id: Int64(sqlite3_column_int(stmt, 0)),
                        title: String(cString: sqlite3_column_text(stmt, 1)),
                        type: Int(sqlite3_column_int(stmt, 2))
                    )
                )
            }
        }
        return fields
    }
    func getCustomField(id:Int) -> CustomField? {
        var customField:CustomField? = nil
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "SELECT id, title, type FROM customer_extra_fields WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(id))
            while sqlite3_step(stmt) == SQLITE_ROW {
                customField = (
                    CustomField(
                        id: Int64(sqlite3_column_int(stmt, 0)),
                        title: String(cString: sqlite3_column_text(stmt, 1)),
                        type: Int(sqlite3_column_int(stmt, 2))
                    )
                )
            }
        }
        return customField
    }
    func updateCustomField(cf: CustomField) -> Bool {
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "UPDATE customer_extra_fields SET title = ?, type = ? WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            let title = cf.mTitle as NSString
            sqlite3_bind_text(stmt, 1, title.utf8String, -1, nil)
            sqlite3_bind_int(stmt, 2, Int32(cf.mType))
            sqlite3_bind_int64(stmt, 3, cf.mId)
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
        return true
    }
    func insertCustomField(cf: CustomField) -> Bool {
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "INSERT INTO customer_extra_fields (title, type) VALUES (?,?)", -1, &stmt, nil) == SQLITE_OK {
            let key = cf.mTitle as NSString
            sqlite3_bind_text(stmt, 1, key.utf8String, -1, nil)
            sqlite3_bind_int(stmt, 2, Int32(cf.mType))
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
        return true
    }
    func removeCustomField(id: Int64) {
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "DELETE FROM customer_extra_fields WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, id)
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
    }
    
    // Voucher Operations
    func getVouchers(showDeleted:Bool) -> [Voucher] {
        var vouchers:[Voucher] = []
        var stmt:OpaquePointer?
        var sql = "SELECT id, original_value, current_value, voucher_no, from_customer, for_customer, issued, valid_until, redeemed, notes, last_modified, removed FROM voucher WHERE removed = 0 ORDER BY issued DESC"
        if(showDeleted) {
            sql = "SELECT id, original_value, current_value, voucher_no, from_customer, for_customer, issued, valid_until, redeemed, notes, last_modified, removed FROM voucher ORDER BY issued DESC"
        }
        if sqlite3_prepare(self.db, sql, -1, &stmt, nil) == SQLITE_OK {
            while sqlite3_step(stmt) == SQLITE_ROW {
                var validUntil:Date? = nil
                if(sqlite3_column_text(stmt, 7) != nil) {
                    validUntil = CustomerDatabase.parseDate(strDate: String(cString: sqlite3_column_text(stmt, 7)))
                }
                var redeemed:Date? = nil
                if(sqlite3_column_text(stmt, 8) != nil) {
                    redeemed = CustomerDatabase.parseDate(strDate: String(cString: sqlite3_column_text(stmt, 8)))
                }
                vouchers.append(
                    Voucher(
                        id: Int64(sqlite3_column_int64(stmt, 0)),
                        originalValue: Double(sqlite3_column_double(stmt, 1)),
                        currentValue: Double(sqlite3_column_double(stmt, 2)),
                        voucherNo: String(cString: sqlite3_column_text(stmt, 3)),
                        fromCustomer: String(cString: sqlite3_column_text(stmt, 4)),
                        forCustomer: String(cString: sqlite3_column_text(stmt, 5)),
                        issued: CustomerDatabase.parseDate(strDate: String(cString: sqlite3_column_text(stmt, 6))) ?? Date(),
                        validUntil: validUntil,
                        redeemed: redeemed,
                        notes: String(cString: sqlite3_column_text(stmt, 9)),
                        lastModified: CustomerDatabase.parseDate(strDate: String(cString: sqlite3_column_text(stmt, 10))) ?? Date(),
                        removed: Int(sqlite3_column_int(stmt, 11))
                    )
                )
            }
        }
        return vouchers
    }
    func getVoucher(id:Int64) -> Voucher? {
        var voucher:Voucher? = nil
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "SELECT id, original_value, current_value, voucher_no, from_customer, for_customer, issued, valid_until, redeemed, notes, last_modified, removed FROM voucher WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, id)
            while sqlite3_step(stmt) == SQLITE_ROW {
                var validUntil:Date? = nil
                if(sqlite3_column_text(stmt, 7) != nil) {
                    validUntil = CustomerDatabase.parseDate(strDate: String(cString: sqlite3_column_text(stmt, 7)))
                }
                var redeemed:Date? = nil
                if(sqlite3_column_text(stmt, 8) != nil) {
                    redeemed = CustomerDatabase.parseDate(strDate: String(cString: sqlite3_column_text(stmt, 8)))
                }
                voucher = (
                    Voucher(
                        id: Int64(sqlite3_column_int64(stmt, 0)),
                        originalValue: Double(sqlite3_column_double(stmt, 1)),
                        currentValue: Double(sqlite3_column_double(stmt, 2)),
                        voucherNo: String(cString: sqlite3_column_text(stmt, 3)),
                        fromCustomer: String(cString: sqlite3_column_text(stmt, 4)),
                        forCustomer: String(cString: sqlite3_column_text(stmt, 5)),
                        issued: CustomerDatabase.parseDate(strDate: String(cString: sqlite3_column_text(stmt, 6))) ?? Date(),
                        validUntil: validUntil,
                        redeemed: redeemed,
                        notes: String(cString: sqlite3_column_text(stmt, 9)),
                        lastModified: CustomerDatabase.parseDate(strDate: String(cString: sqlite3_column_text(stmt, 10))) ?? Date(),
                        removed: Int(sqlite3_column_int(stmt, 11))
                    )
                )
            }
        }
        return voucher
    }
    func updateVoucher(v: Voucher) -> Bool {
        sqlite3_exec(self.db, "BEGIN EXCLUSIVE TRANSACTION", nil, nil, nil)
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "UPDATE voucher SET original_value = ?, current_value = ?, voucher_no = ?, from_customer = ?, for_customer = ?, issued = ?, valid_until = ?, redeemed = ?, notes = ?, last_modified = ? WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            let voucherNo = v.mVoucherNo as NSString
            let fromCustomer = v.mFromCustomer as NSString
            let forCustomer = v.mForCustomer as NSString
            let issued:NSString = CustomerDatabase.dateToString(date: v.mIssued) as NSString
            let validUntil:NSString? = (v.mValidUntil==nil) ? nil : CustomerDatabase.dateToString(date: v.mValidUntil!) as NSString
            let redeemed:NSString? = (v.mRedeemed==nil) ? nil : CustomerDatabase.dateToString(date: v.mRedeemed!) as NSString
            let notes = v.mNotes as NSString
            let lastModified = CustomerDatabase.dateToString(date: v.mLastModified) as NSString
            sqlite3_bind_double(stmt, 1, v.mOriginalValue)
            sqlite3_bind_double(stmt, 2, v.mCurrentValue)
            sqlite3_bind_text(stmt, 3, voucherNo.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 4, fromCustomer.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, forCustomer.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 6, issued.utf8String, -1, nil)
            if(validUntil == nil) {
                sqlite3_bind_null(stmt, 7)
            } else {
                sqlite3_bind_text(stmt, 7, validUntil!.utf8String, -1, nil)
            }
            if(redeemed == nil) {
                sqlite3_bind_null(stmt, 8)
            } else {
                sqlite3_bind_text(stmt, 8, redeemed!.utf8String, -1, nil)
            }
            sqlite3_bind_text(stmt, 9, notes.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 10, lastModified.utf8String, -1, nil)
            sqlite3_bind_int64(stmt, 11, v.mId)
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
        sqlite3_exec(self.db, "COMMIT TRANSACTION", nil, nil, nil)
        return true
    }
    func insertVoucher(v: Voucher) -> Bool {
        sqlite3_exec(self.db, "BEGIN EXCLUSIVE TRANSACTION", nil, nil, nil)
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "INSERT INTO voucher (id, original_value, current_value, voucher_no, from_customer, for_customer, issued, valid_until, redeemed, notes, last_modified, removed) VALUES (?,?,?,?,?,?,?,?,?,?,?,0)", -1, &stmt, nil) == SQLITE_OK {
            let voucherNo = v.mVoucherNo as NSString
            let fromCustomer = v.mFromCustomer as NSString
            let forCustomer = v.mForCustomer as NSString
            let issued:NSString = CustomerDatabase.dateToString(date: v.mIssued) as NSString
            let validUntil:NSString? = (v.mValidUntil==nil) ? nil : CustomerDatabase.dateToString(date: v.mValidUntil!) as NSString
            let redeemed:NSString? = (v.mRedeemed==nil) ? nil : CustomerDatabase.dateToString(date: v.mRedeemed!) as NSString
            let notes = v.mNotes as NSString
            let lastModified = CustomerDatabase.dateToString(date: v.mLastModified) as NSString
            sqlite3_bind_int64(stmt, 1, v.mId)
            sqlite3_bind_double(stmt, 2, v.mOriginalValue)
            sqlite3_bind_double(stmt, 3, v.mCurrentValue)
            sqlite3_bind_text(stmt, 4, voucherNo.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 5, fromCustomer.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 6, forCustomer.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 7, issued.utf8String, -1, nil)
            if(validUntil == nil) {
                sqlite3_bind_null(stmt, 8)
            } else {
                sqlite3_bind_text(stmt, 8, validUntil!.utf8String, -1, nil)
            }
            if(redeemed == nil) {
                sqlite3_bind_null(stmt, 9)
            } else {
                sqlite3_bind_text(stmt, 9, redeemed!.utf8String, -1, nil)
            }
            sqlite3_bind_text(stmt, 10, notes.utf8String, -1, nil)
            sqlite3_bind_text(stmt, 11, lastModified.utf8String, -1, nil)
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
        sqlite3_exec(self.db, "COMMIT TRANSACTION", nil, nil, nil)
        return true
    }
    func removeVoucher(id: Int64) {
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "UPDATE voucher SET original_value = -1, current_value = -1, from_customer = '', for_customer = '', issued = 0, valid_until = 0, redeemed = 0, notes = '', last_modified = ?, removed = 1 WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            let lastModified = CustomerDatabase.dateToString(date: Date()) as NSString
            sqlite3_bind_text(stmt, 1, lastModified.utf8String, -1, nil)
            sqlite3_bind_int64(stmt, 2, id)
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
    }
    func deleteAllVoucher() {
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "DELETE FROM voucher WHERE 1=1", -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_DONE {
                sqlite3_finalize(stmt)
            }
        }
    }
    func insertUpdateVoucherRecord(id:Int64, originalValue:Double, currentValue:Double, voucherNo:String, fromCustomer:String, forCustomer:String, issued:String, validUntil:String?, redeemed:String?, notes:String, lastModified:String, removed:Int) -> Bool {
        let voucherNo2 = voucherNo as NSString
        let fromCustomer2 = fromCustomer as NSString
        let forCustomer2 = forCustomer as NSString
        let notes2 = notes as NSString
        let issued2 = issued as NSString
        let validUntil2 = validUntil as NSString?
        let redeemed2 = redeemed as NSString?
        let lastModified2 = lastModified as NSString
        sqlite3_exec(self.db, "BEGIN EXCLUSIVE TRANSACTION", nil, nil, nil)
        var stmt:OpaquePointer?
        if sqlite3_prepare(self.db, "SELECT id FROM voucher WHERE id = ?", -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int64(stmt, 1, id)
            if(sqlite3_step(stmt) == SQLITE_ROW) {
                // update
                var stmt2:OpaquePointer?
                if sqlite3_prepare(self.db, "UPDATE voucher SET original_value = ?, current_value = ?, voucher_no = ?, from_customer = ?, for_customer = ?, issued = ?, valid_until = ?, redeemed = ?, notes = ?, last_modified = ?, removed = ? WHERE id = ? AND last_modified < ?", -1, &stmt2, nil) == SQLITE_OK {
                    sqlite3_bind_double(stmt2, 1, originalValue)
                    sqlite3_bind_double(stmt2, 2, currentValue)
                    sqlite3_bind_text(stmt2, 3, voucherNo2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 4, fromCustomer2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 5, forCustomer2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 6, issued2.utf8String, -1, nil)
                    if(validUntil2 == nil) {
                        sqlite3_bind_null(stmt2, 7)
                    } else {
                        sqlite3_bind_text(stmt2, 7, validUntil2?.utf8String, -1, nil)
                    }
                    if(redeemed == nil) {
                        sqlite3_bind_null(stmt2, 8)
                    } else {
                        sqlite3_bind_text(stmt2, 8, redeemed2?.utf8String, -1, nil)
                    }
                    sqlite3_bind_text(stmt2, 9, notes2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 10, lastModified2.utf8String, -1, nil)
                    sqlite3_bind_int(stmt2, 11, Int32(removed))
                    sqlite3_bind_int64(stmt2, 12, id)
                    sqlite3_bind_text(stmt2, 13, lastModified2.utf8String, -1, nil)
                    if sqlite3_step(stmt2) == SQLITE_DONE {
                        sqlite3_finalize(stmt2)
                    }
                }
            } else {
                // insert
                var stmt2:OpaquePointer?
                if sqlite3_prepare(self.db, "INSERT INTO voucher (id, original_value, current_value, voucher_no, from_customer, for_customer, issued, valid_until, redeemed, notes, last_modified, removed) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)", -1, &stmt2, nil) == SQLITE_OK {
                    sqlite3_bind_int64(stmt2, 1, id)
                    sqlite3_bind_double(stmt2, 2, originalValue)
                    sqlite3_bind_double(stmt2, 3, currentValue)
                    sqlite3_bind_text(stmt2, 4, voucherNo2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 5, fromCustomer2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 6, forCustomer2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 7, issued2.utf8String, -1, nil)
                    if(validUntil2 == nil) {
                        sqlite3_bind_null(stmt2, 8)
                    } else {
                        sqlite3_bind_text(stmt2, 8, validUntil2?.utf8String, -1, nil)
                    }
                    if(redeemed == nil) {
                        sqlite3_bind_null(stmt2, 9)
                    } else {
                        sqlite3_bind_text(stmt2, 9, redeemed2?.utf8String, -1, nil)
                    }
                    sqlite3_bind_text(stmt2, 10, notes2.utf8String, -1, nil)
                    sqlite3_bind_text(stmt2, 11, lastModified2.utf8String, -1, nil)
                    sqlite3_bind_int(stmt2, 12, Int32(removed))
                    if sqlite3_step(stmt2) == SQLITE_DONE {
                        sqlite3_finalize(stmt2)
                    }
                }
            }
            sqlite3_finalize(stmt)
        }
        sqlite3_exec(self.db, "COMMIT TRANSACTION", nil, nil, nil)
        return true
    }
}
