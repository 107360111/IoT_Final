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
    
    @IBOutlet var view_gif: UIView!
    @IBOutlet var constraint_gif_width: NSLayoutConstraint!
    
    @IBOutlet var label_title: UILabel!
    
    private var isCentral: Bool = true
    private var isFindDevice: Bool = false
    private var isOverDistance: Bool = false
    
    private var animationView = LottieAnimationView()
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        animationView.play()
    }
    
    private func componentInit() {
        constraint_gif_width.constant = UIDevice.current.userInterfaceIdiom == .pad ? 450 : 200
        labelInit()
        viewInit()
        gifViewInit()
    }
    
    private func labelInit() {
        let titleStr =
        (isCentral && isOverDistance) ? "警告，Peripheral裝置距離您的裝置太遠了!" :
        (!isCentral && isFindDevice) ? "您接收到來自Central裝置的通知訊息" :
        (!isCentral && isOverDistance) ? "警告，您的裝置距離Central裝置太遠了!" :
        String()

        if !titleStr.isEmpty {
            label_title.text = titleStr
        } else {
            label_title.isHidden = true
        }
    }
    
    private func viewInit() {
        view_warning.backgroundColor = UIColor.clear
        view_background.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(leaveDialog)))
    }
    
    private func gifViewInit() {
        let gifName = (!isCentral && isFindDevice) ? "peripheral_CallBell" : "warning"
        animationView = LottieAnimationView(name: gifName)
        animationView.frame = CGRect(x: 0, y: 0, width: constraint_gif_width.constant, height: constraint_gif_width.constant)
        animationView.contentMode = .scaleAspectFit
                
        animationView.loopMode = .loop
        animationView.animationSpeed = (!isCentral && isOverDistance) ? 0.8 : 0.5
        
        view_gif.addSubview(animationView)
    }
    
    @objc private func leaveDialog() {
        delegate?.leave()
        dialogDismiss()
    }
}
