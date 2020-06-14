//
//  FilterViewPickerController.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class SortPickerController: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var mSortFields: [KeyValueItem] = [
        KeyValueItem("first_name", NSLocalizedString("first_name", comment: "")),
        KeyValueItem("last_name", NSLocalizedString("last_name", comment: ""))
    ]
    var mOrders: [String] = [
        NSLocalizedString("ascending", comment: ""),
        NSLocalizedString("descending", comment: "")
    ]
    
    var mSelectedSortField = ""
    var mSelectedOrderAsc = true
    
    init(db: CustomerDatabase) {
        for field in db.getCustomFields() {
            mSortFields.append(KeyValueItem(field.mTitle, field.mTitle))
        }
        
        mSelectedSortField = mSortFields[0].key
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if(component == 0) {
            return mSortFields.count
        } else if(component == 1) {
            return mOrders.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if(component == 0) {
            return mSortFields[row].value
        } else if(component == 1) {
            return mOrders[row]
        }
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if(component == 0) {
            mSelectedSortField = mSortFields[row].key
        } else if(component == 1) {
            mSelectedOrderAsc = (row == 0)
        }
    }

}
