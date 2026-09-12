//
//  Created by Schorschii on 17.02.22.
//  Copyright © 2022 Georg Sieber. All rights reserved.
//

import Foundation
import UIKit

class TextViewViewController : UIViewController {
    @IBOutlet weak var textViewText: UITextView!
    
    var mText = ""
    var mTitle = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(mTitle != "") {
            navigationItem.title = mTitle
            if #available(iOS 26.0, *) {
                navigationItem.largeTitle = mTitle
            }
        }
        textViewText.text = mText
    }

    @IBAction func onClickDone(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
}
