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
    
    class TYPE {
        static var TEXT = 0
        static var TEXT_MULTILINE = 1
        static var NUMBER = 2
        static var DROPDOWN = 3
        static var DATE = 3
    }
    
    init() {}
    init(title:String, value:String) {
        mTitle = title
        mValue = value
    }
    init(id:Int64, title:String, type:Int) {
        mId = id
        mTitle = title
        mType = type
    }
}
