//
//  CalendarCsvWriter.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation

class CalendarCsvWriter {
    
    static var DELIMITER = ","
    
    var mAppointments: [CustomerAppointment] = []
    
    init(appointments: [CustomerAppointment]) {
        mAppointments = appointments
    }
    
    func buildCsvContent() -> String {
        let mDb = CustomerDatabase()
        var content = ""
        
        let headers = [
            "id", "title", "notes", "time_start", "time_end", "fullday", "customer", "customer_id", "location", "last_modified"
        ]
        content += putLine(fields: headers)
        
        for c in mAppointments {
            var customerText = ""
            if(c.mCustomerId != nil) {
                if let c = mDb.getCustomer(id: c.mCustomerId!, showDeleted: false) {
                    customerText = c.getFullName(lastNameFirst: false)
                }
            } else {
                customerText = c.mCustomer
            }
            
            let fields:[String] = [
                String(c.mId),
                c.mTitle,
                c.mNotes,
                c.mTimeStart==nil ? "" : CustomerDatabase.dateToStringRaw(date: c.mTimeStart!),
                c.mTimeEnd==nil ? "" : CustomerDatabase.dateToStringRaw(date: c.mTimeEnd!),
                c.mFullday ? "1" : "0",
                customerText,
                c.mCustomerId==nil ? "" : String(c.mCustomerId!),
                c.mLocation,
                CustomerDatabase.dateToString(date: c.mLastModified)
            ]
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
