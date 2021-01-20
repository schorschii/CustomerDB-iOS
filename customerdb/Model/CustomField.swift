//
//  CustomerField.swift
//  Copyright © 2019 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class CustomField {
    var mId: Int64 = -1
    var mTitle: String = ""
    var mValue: String = ""
    var mType: Int = -1
    
    var mTextFieldHandle:UIView? = nil
    
    var mPresetPickerController:PickerDataController? = nil
    
    class TYPE {
        static var TEXT = 0
        static var NUMBER = 1
        static var DROPDOWN = 2
        static var DATE = 3
        static var TEXT_MULTILINE = 4
    }
    
    init() {}
    init(title:String, value:String) {
        mTitle = title
        mValue = value
    }
    init(title:String, value:String, type:Int) {
        mTitle = title
        mValue = value
        mType = type
    }
    init(id:Int64, title:String, type:Int) {
        mId = id
        mTitle = title
        mType = type
    }
}
