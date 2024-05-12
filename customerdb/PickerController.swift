//
//  FilterViewPickerController.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class FilterPickerController: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    
    static var ALL = NSLocalizedString("all", comment: "")
    static var EMPTY = NSLocalizedString("empty", comment: "")
    
    var mGroups: [String] = [ ALL, EMPTY ]
    var mCities: [String] = [ ALL, EMPTY ]
    var mCountries: [String] = [ ALL, EMPTY ]
    
    var mSelectedGroup: String? = ""
    var mSelectedCity: String? = ""
    var mSelectedCountry: String? = ""
    
    init(db: CustomerDatabase) {
        for customer in db.getCustomers(search: nil, showDeleted: false, withFiles: false) {
            if(!mGroups.contains(customer.mGroup) && customer.mGroup != "") {
                mGroups.append(customer.mGroup)
            }
            if(!mCities.contains(customer.mCity) && customer.mCity != "") {
                mCities.append(customer.mCity)
            }
            if(!mCountries.contains(customer.mCountry) && customer.mCountry != "") {
                mCountries.append(customer.mCountry)
            }
        }
        
        mSelectedGroup = FilterPickerController.realString(mGroups[0])
        mSelectedCity = FilterPickerController.realString(mCities[0])
        mSelectedCountry = FilterPickerController.realString(mCountries[0])
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
            mSelectedGroup = FilterPickerController.realString(mGroups[row])
        } else if(component == 1) {
            mSelectedCity = FilterPickerController.realString(mCities[row])
        } else if(component == 2) {
            mSelectedCountry = FilterPickerController.realString(mCountries[row])
        }
    }
    
    private static func realString(_ string: String) -> String? {
        if(string == FilterPickerController.ALL) {
            return nil
        } else if(string == FilterPickerController.EMPTY) {
            return ""
        } else {
            return string
        }
    }

}

class SortPickerController: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var mSortFields: [KeyValueItem] = [
        KeyValueItem("first_name", NSLocalizedString("first_name", comment: "")),
        KeyValueItem("last_name", NSLocalizedString("last_name", comment: "")),
        KeyValueItem("last_modified", NSLocalizedString("last_modified", comment: ""))
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
        mCustomers = db.getCustomers(search: nil, showDeleted: false, withFiles: false)
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

class FieldTypePickerController: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    
    private var mSelected = 0
    var mTypes: [String] = [
        "field_alphanumeric",
        "field_alphanumeric_multiline",
        "field_numeric",
        "field_drop_down",
        "field_date"
    ]

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return mTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return NSLocalizedString(mTypes[row], comment: "")
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        mSelected = row
    }

}

class PickerDataController: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    var textField: UITextField? = nil
    var pickerView: UIPickerView? = nil
    
    var data: [KeyValueItem]
    var changed: ((_ item: KeyValueItem)->()?)? = nil
    
    init(data: [KeyValueItem]) {
        self.data = data
    }
    init(pickerView: UIPickerView, data: [KeyValueItem]) {
        self.pickerView = pickerView
        self.data = data
    }
    init(textField: UITextField, data: [KeyValueItem]) {
        self.textField = textField
        self.data = data
    }
    init(textField: UITextField, data: [KeyValueItem], changed: @escaping (_ item:KeyValueItem)->()) {
        self.textField = textField
        self.data = data
        self.changed = changed
    }
    
    func getPickerView() -> UIPickerView {
        if(pickerView != nil) {
            return pickerView!
        } else if(textField != nil) {
            return textField?.inputView as! UIPickerView
        } else {
            return UIPickerView()
        }
    }
    
    func getSelectedRow() -> Int {
        return getPickerView().selectedRow(inComponent: 0)
    }
    func getSelectedKey() -> String {
        return data[getSelectedRow()].key
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return data.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return data[row].value
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if(row <= data.count-1) {
            if(textField != nil) {
                textField!.text = data[row].value
            }
            self.changed?(data[row])
        }
    }
}
