//
//  Voucher.swift
//  Copyright © 2019 Georg Sieber. All rights reserved.
//

import Foundation

class Voucher {
    var mId:Int64 = -1
    var mOriginalValue = 0.0
    var mCurrentValue = 0.0
    var mVoucherNo = ""
    var mFromCustomer = ""
    var mForCustomer = ""
    var mIssued:Date = Date()
    var mValidUntil:Date? = nil
    var mRedeemed:Date? = nil
    var mNotes = ""
    var mLastModified:Date = Date()
    var mRemoved = 0
    
    init() {
        mId = Int64(Voucher.generateID())
    }
    init(id:Int64, originalValue:Double, currentValue:Double, voucherNo:String, fromCustomer:String, forCustomer:String, issued:Date, validUntil:Date?, redeemed:Date?, notes:String, lastModified: Date, removed:Int) {
        mId = id
        mOriginalValue = originalValue
        mCurrentValue = currentValue
        mVoucherNo = voucherNo
        mFromCustomer = fromCustomer
        mForCustomer = forCustomer
        mIssued = issued
        mValidUntil = validUntil
        mRedeemed = redeemed
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
    
    static func format(value:Double) -> String {
        return String(format: "%0.2f", value)
    }
}
