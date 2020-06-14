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
        for customer in db.getCustomers(showDeleted: false) {
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
