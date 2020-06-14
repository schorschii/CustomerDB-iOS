//
//  FieldTypeViewPickerController.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class FieldTypePickerController: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {
    
    var mSelected = 0
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
