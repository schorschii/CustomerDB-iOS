//
//  InsertNumber.swift
//  Copyright © 2021 Georg Sieber. All rights reserved.
//

import Foundation

class CallDirectoryNumber {
    var mId: Int64 = -1
    var mCustomerId: Int64 = -1
    var mDisplayName: String = ""
    var mPhoneNumber: String = ""
    
    init() {}
    init(phoneNumber:String) {
        mPhoneNumber = phoneNumber
    }
    init(displayName:String, phoneNumber:String) {
        mDisplayName = displayName
        mPhoneNumber = phoneNumber
    }
    init(customerId:Int64, displayName:String, phoneNumber:String) {
        mCustomerId = customerId
        mDisplayName = displayName
        mPhoneNumber = phoneNumber
    }
    init(id:Int64, customerId:Int64, displayName:String, phoneNumber:String) {
        mId = id
        mCustomerId = customerId
        mDisplayName = displayName
        mPhoneNumber = phoneNumber
    }
}
