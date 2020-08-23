//
//  CsvWriter.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation

class VoucherCsvWriter {
    
    static var DELIMITER = ","
    
    var mVouchers: [Voucher] = []
    
    init(vouchers: [Voucher]) {
        mVouchers = vouchers
    }
    
    func buildCsvContent() -> String {
        var content = ""
        
        let headers = [
            "id", "voucher_no", "original_value", "current_value",
            "from_customer", "from_customer_id", "for_customer", "for_customer_id",
            "issued", "valid_until", "redeemed", "last_modified",
            "notes"
        ]
        
        content += putLine(fields: headers)
        
        for v in mVouchers {
            let fields:[String] = [
                String(v.mId), v.mVoucherNo,
                String(v.mOriginalValue), String(v.mCurrentValue),
                v.mFromCustomer,
                v.mFromCustomerId==nil ? "" : String(v.mFromCustomerId!),
                v.mForCustomer,
                v.mForCustomerId==nil ? "" : String(v.mForCustomerId!),
                CustomerDatabase.dateToString(date: v.mIssued),
                v.mValidUntil==nil ? "" : CustomerDatabase.dateToString(date: v.mValidUntil!),
                v.mRedeemed==nil ? "" : CustomerDatabase.dateToString(date: v.mRedeemed!),
                CustomerDatabase.dateToString(date: v.mLastModified),
                v.mNotes
            ]
            content += putLine(fields: fields)
        }
        
        return content
    }
    
    private func putLine(fields: [String]) -> String {
        var content = ""
        for field in fields {
            content += escapeField(value: field) + VoucherCsvWriter.DELIMITER
        }
        return content + "\n"
    }
    
    private func escapeField(value: String) -> String {
        return "\"" + value.replacingOccurrences(of: "\"", with: "'") + "\""
    }
    
}
