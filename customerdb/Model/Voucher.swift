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
    var mFromCustomerId:Int64? = nil
    var mForCustomer = ""
    var mForCustomerId:Int64? = nil
    var mIssued:Date = Date()
    var mValidUntil:Date? = nil
    var mRedeemed:Date? = nil
    var mNotes = ""
    var mLastModified:Date = Date()
    var mRemoved = 0
    
    init() {
        mId = Int64(Voucher.generateID())
    }
    init(id:Int64, originalValue:Double, currentValue:Double, voucherNo:String, fromCustomer:String, fromCustomerId:Int64?, forCustomer:String, forCustomerId:Int64?, issued:Date, validUntil:Date?, redeemed:Date?, notes:String, lastModified: Date, removed:Int) {
        mId = id
        mOriginalValue = originalValue
        mCurrentValue = currentValue
        mVoucherNo = voucherNo
        mFromCustomer = fromCustomer
        mFromCustomerId = fromCustomerId
        mForCustomer = forCustomer
        mForCustomerId = forCustomerId
        mIssued = issued
        mValidUntil = validUntil
        mRedeemed = redeemed
        mNotes = notes
        mLastModified = lastModified
        mRemoved = removed
    }
    
    func putAttribute(key:String, value:String) {
        switch(key) {
        case "id":
            mId = Int64(value) ?? -1; break
        case "current_value":
            mCurrentValue = Double(value) ?? 0; break
        case "original_value":
            mOriginalValue = Double(value) ?? 0; break
        case "voucher_no":
            mVoucherNo = value; break
        case "from_customer":
            mFromCustomer = value; break
        case "from_customer_id":
            mFromCustomerId = Int64(value); break
        case "for_customer":
            mForCustomer = value; break
        case "for_customer_id":
            mForCustomerId = Int64(value); break
        case "issued":
            if let date = CustomerDatabase.parseDate(strDate: value) {
                mIssued = date
            }
            break
        case "redeemed":
            if let date = CustomerDatabase.parseDate(strDate: value) {
                mRedeemed = date
            }
            break
        case "valid_until":
            if let date = CustomerDatabase.parseDate(strDate: value) {
                mValidUntil = date
            }
            break
        case "notes":
            mNotes = value; break
        case "last_modified":
            if let lastMofified = CustomerDatabase.parseDate(strDate: value) {
                mLastModified = lastMofified
            }
            break
        case "removed":
            mRemoved = (value=="1" ? 1 : 0); break
        default:
            break
        }
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
    
    static func format(value:Double) -> String {
        return String(format: "%0.2f", value)
    }
}
