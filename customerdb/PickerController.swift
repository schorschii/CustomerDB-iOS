//
//  FilterViewPickerController.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class FilterPickerController: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var mGroups: [String] = [""]
    var mCities: [String] = [""]
    var mCountries: [String] = [""]
    
    var mSelectedGroup = ""
    var mSelectedCity = ""
    var mSelectedCountry = ""
    
    init(db: CustomerDatabase) {
        for customer in db.getCustomers(showDeleted: false, withFiles: false) {
            if(!mGroups.contains(customer.mGroup)) {
                mGroups.append(customer.mGroup)
            }
            if(!mCities.contains(customer.mCity)) {
                mCities.append(customer.mCity)
            }
            if(!mCountries.contains(customer.mCountry)) {
                mCountries.append(customer.mCountry)
            }
        }
        
        mSelectedGroup = mGroups[0]
        mSelectedCity = mCities[0]
        mSelectedCountry = mCountries[0]
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if(component == 0) {
            return mGroups.count
        } else if(component == 1) {
            return mCities.count
        } else if(component == 2) {
            return mCountries.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if(component == 0) {
            return mGroups[row]
        } else if(component == 1) {
            return mCities[row]
        } else if(component == 2) {
            return mCountries[row]
        }
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if(component == 0) {
            mSelectedGroup = mGroups[row]
        } else if(component == 1) {
            mSelectedCity = mCities[row]
        } else if(component == 2) {
            mSelectedCountry = mCountries[row]
        }
    }

}

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

class CustomerPickerController: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var mCustomers: [Customer] = []
    var mSelectedCustomer:Customer? = nil
    
    init(db: CustomerDatabase) {
        mCustomers = db.getCustomers(showDeleted: false, withFiles: false)
        if(mCustomers.count > 0) {
            mSelectedCustomer = mCustomers[0]
        }
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return mCustomers.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return mCustomers[row].getFullName(lastNameFirst: true)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        mSelectedCustomer = mCustomers[row]
    }

}
