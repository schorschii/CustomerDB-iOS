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
        var content = ""
        
        let headers = [
            "id", "title", "notes", "time_start", "time_end", "fullday", "customer", "customer_id", "location", "last_modified"
        ]
        content += putLine(fields: headers)
        
        for c in mAppointments {
            let fields:[String] = [
                String(c.mId),
                c.mTitle,
                c.mNotes,
                c.mTimeStart==nil ? "" : CustomerDatabase.dateToString(date: c.mTimeStart!),
                c.mTimeEnd==nil ? "" : CustomerDatabase.dateToString(date: c.mTimeEnd!),
                c.mFullday ? "1" : "0",
                c.mCustomer,
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
