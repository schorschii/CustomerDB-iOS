//
//  Created by Schorschii on 17.02.22.
//  Copyright © 2022 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class TextViewViewController : UIViewController {
    @IBOutlet weak var navigationBar: UINavigationBar!
    @IBOutlet weak var textViewText: UITextView!
    
    var mText = ""
    var mTitle = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(mTitle != nil && mTitle != "") {
            navigationBar.topItem?.title = mTitle
        }
        if(mText != nil) {
            textViewText.text = mText
        }
    }

    @IBAction func onClickDone(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}
