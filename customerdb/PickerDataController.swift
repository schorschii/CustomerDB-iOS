//
//  PickerDataController.swift
//  Copyright © 2020 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class PickerDataController: NSObject, UIPickerViewDelegate, UIPickerViewDataSource {
    var textField: UITextField? = nil
    var pickerView: UIPickerView? = nil
    
    var data: [KeyValueItem]
    var changed: ((_ item: KeyValueItem)->()?)? = nil
    
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
