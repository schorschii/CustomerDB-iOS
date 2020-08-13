//
//  CustomerCalendar.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation

class CustomerCalendar {

    var mId:Int64 = -1
    var mTitle = ""
    var mColor = ""
    var mNotes = ""
    var mLastModified = Date()
    var mRemoved = 0

    init() {
    }
    init(id:Int64, title:String, color:String, notes:String, lastModified:Date, removed:Int) {
        mId = id
        mTitle = title
        mColor = color
        mNotes = notes
        mLastModified = lastModified
        mRemoved = removed
    }

    static func generateID() -> Int64 {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddkkmmss"
        let strId = dateFormatter.string(from: Date()) + String(Int.random(in: 1..<100))
        return Int64(strId) ?? -1
    }

    func putAttribute(key:String, value:String) {
        switch(key) {
            case "id":
                mId = Int64(value) ?? -1; break
            case "title":
                mTitle = value; break
            case "color":
                mColor = value; break
            case "notes":
                mNotes = value; break
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

}
