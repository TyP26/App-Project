//
//  CheckBox.swift
//  schoolApp1
//
//  Created by Matthias Park 2025 on 8/2/23.
//

import UIKit

class CheckBox: UIButton {
    // Int property
    var grade: Int
    
    // Images
    private let checkedImage = UIImage(systemName: "checkmark.square.fill")!
    private let uncheckedImage = UIImage(systemName: "square")!
    
    // Bool property
    var isChecked: Bool = false {
        didSet {
            if isChecked {
                setImage(checkedImage, for: UIControl.State.normal)
            }
            else {
                setImage(uncheckedImage, for: UIControl.State.normal)
            }
        }
    }
    
    init(with grade: Int) {
        self.grade = grade
        super.init(frame: CGRect())
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
//        self.addTarget(self, action: #selector(checkBoxPressed), for: .touchUpInside)
        isChecked = false
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchLocation = touches.first?.location(in: self.superview)
        if self.frame.contains(touchLocation!) {
            isChecked = !isChecked
        }
    }
}
