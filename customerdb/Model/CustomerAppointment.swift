//
//  CustomerAppointment.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation

class CustomerAppointment {

    var mId:Int64 = -1
    var mCalendarId:Int64 = -1
    var mTitle = ""
    var mNotes = "";
    var mTimeStart:Date? = nil
    var mTimeEnd:Date? = nil
    var mFullday = false
    var mCustomer = ""
    var mCustomerId:Int64? = nil
    var mLocation = ""
    var mLastModified = Date()
    var mRemoved = 0

    var mColor = ""

    init() {
        mId = Int64(Customer.generateID())
    }
    init(id:Int64, calendarId:Int64, title:String, notes:String, timeStart:Date?, timeEnd:Date?, fullday:Bool, customer:String, customerId:Int64?, location:String, lastModified:Date, removed:Int) {
        mId = id
        mCalendarId = calendarId
        mTitle = title
        mNotes = notes
        mTimeStart = timeStart
        mTimeEnd = timeEnd
        mFullday = fullday
        mCustomer = customer
        mCustomerId = customerId
        mLocation = location
        mLastModified = lastModified
        mRemoved = removed
    }

    static func generateID() -> Int64 {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddkkmmss"
        let strId = dateFormatter.string(from: Date()) + String(Int.random(in: 1..<100))
        return Int64(strId) ?? -1
    }
    static func generateID(suffix: Int) -> Int64 {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddkkmmss"
        let strId = dateFormatter.string(from: Date()) + String(suffix)
        return Int64(strId) ?? -1
    }

    func putAttribute(key:String, value:String) {
        switch(key) {
            case "id":
                mId = Int64(value) ?? -1; break
            case "calendar_id":
                mCalendarId = Int64(value) ?? -1; break
            case "title":
                mTitle = value; break
            case "notes":
                mNotes = value; break
            case "time_start":
                if let date = CustomerDatabase.parseDateRaw(strDate: value) {
                    mTimeStart = date
                }
                break;
            case "time_end":
                if let date = CustomerDatabase.parseDateRaw(strDate: value) {
                    mTimeEnd = date
                }
                break;
            case "fullday":
                mRemoved = (value=="1" ? 1 : 0); break
            case "customer":
                mCustomer = value; break
            case "customer_id":
                mCustomerId = Int64(value); break
            case "location":
                mLocation = value; break
            case "last_modified":
                if let lastMofified = CustomerDatabase.parseDate(strDate: value) {
                    mLastModified = lastMofified
                }
                break;
            case "removed":
                mRemoved = (value=="1" ? 1 : 0); break
            default:
                break
        }
    }

    func getStartTimeInMinutes() -> Int {
        let hour = Calendar.current.component(.hour, from: mTimeStart!)
        let min = Calendar.current.component(.minute, from: mTimeStart!)
        return (hour * 60) + min
    }
    func getEndTimeInMinutes() -> Int {
        let hour = Calendar.current.component(.hour, from: mTimeEnd!)
        let min = Calendar.current.component(.minute, from: mTimeEnd!)
        return (hour * 60) + min
    }

}
