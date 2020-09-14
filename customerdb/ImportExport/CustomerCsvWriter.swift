//
//  CsvWriter.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation

class CustomerCsvWriter {
    
    static var DELIMITER = ","
    
    var mCustomers: [Customer] = []
    var mCustomFields: [CustomField] = []
    
    init(customers: [Customer], customFields: [CustomField]) {
        mCustomers = customers
        mCustomFields = customFields
    }
    
    func buildCsvContent() -> String {
        var content = ""
        
        var headers = [
            "id", "title", "first_name", "last_name",
            "phone_home", "phone_mobile", "phone_work", "email",
            "street", "zipcode", "city", "country", "customer_group",
            "newsletter", "birthday", "last_modified", "notes"
        ]
        for customField in mCustomFields {
            headers.append(customField.mTitle)
        }
        
        content += putLine(fields: headers)
        
        for c in mCustomers {
            var fields:[String] = [
                String(c.mId), c.mTitle, c.mFirstName, c.mLastName,
                c.mPhoneHome, c.mPhoneMobile, c.mPhoneWork, c.mEmail,
                c.mStreet, c.mZipcode, c.mCity, c.mCountry, c.mGroup,
                c.mNewsletter ? "1" : "0",
                c.mBirthday==nil ? "" : CustomerDatabase.dateToStringRaw(date: c.mBirthday!),
                CustomerDatabase.dateToString(date: c.mLastModified),
                c.mNotes
            ]
            for customField in mCustomFields {
                fields.append(c.getCustomFieldString(key: customField.mTitle) ?? "")
            }
            content += putLine(fields: fields)
        }
        
        return content
    }
    
    private func putLine(fields: [String]) -> String {
        var content = ""
        for field in fields {
            content += escapeField(value: field) + CustomerCsvWriter.DELIMITER
        }
        return content + "\n"
    }
    
    private func escapeField(value: String) -> String {
        return "\"" + value.replacingOccurrences(of: "\"", with: "'") + "\""
    }
    
}
