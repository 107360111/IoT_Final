//
//  WarningDialogVC.swift
//  IoT_Final
//
//  Created by mmslab406-mini2018-2 on 2023/6/16.
//

import UIKit
import Lottie

protocol WarningDialogVCDelegate: AnyObject {
    func leave()
}

class WarningDialogVC: BasicVC {
    @IBOutlet var view_background: UIView!
    
    @IBOutlet var view_warning: UIView!
    
    @IBOutlet var label_title: UILabel!
    
    private var isCentral: Bool = true
    private var isFindDevice: Bool = false
    private var isOverDistance: Bool = false
    
    weak var delegate: WarningDialogVCDelegate?

    convenience init(isCentral: Bool, isFindDevice: Bool, isOverDistance: Bool) {
        self.init()
        self.isCentral = isCentral
        self.isFindDevice = isFindDevice
        self.isOverDistance = isOverDistance
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        componentInit()
    }
    
    private func componentInit() {
        view_background.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(leaveDialog)))
        labelInit()
        viewInit()
    }
    
    private func labelInit() {
        var titleStr = String()
        if isCentral {
            if isFindDevice {
                titleStr = "您已通知發送端"
            } else if isOverDistance {
                titleStr = "發送端裝置距離本裝置太遠了!"
            } else {
                titleStr = "資料錯誤"
            }
        } else {
            if isFindDevice {
                titleStr = "接收端裝置發送了訊息"
            } else if isOverDistance {
                titleStr = "您的裝置距離接收端裝置太遠了!"
            } else {
                titleStr = "資料錯誤"
            }
        }
        self.label_title.text = titleStr
    }
    
    private func viewInit() {
        
    }
    
    @objc private func leaveDialog() {
        dialogDismiss()
        self.delegate?.leave()
    }
}
