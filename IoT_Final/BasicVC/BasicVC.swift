//
//  BasicVC.swift
//  IoT_Final
//
//  Created by mmslab406-mini2018-2 on 2023/6/2.
//

import UIKit

class BasicVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowReceiver), name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideReceiver), name: UIWindow.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIWindow.keyboardWillHideNotification, object: nil)
    }
    
    /// 鍵盤升起
    func keyboardWillShow(duration: Double, height: CGFloat) {
    }
    
    /// 鍵盤下降
    func keyboardWillHide(duration: Double) {
    }
    
    @objc fileprivate func keyboardWillShowReceiver(notification: NSNotification) {
        let userInfo = notification.userInfo
        let keyboardFrame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue
        guard let duration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double, let size = keyboardFrame?.cgRectValue else { return }
        keyboardWillShow(duration: duration, height: size.height)
    }
    
    @objc fileprivate func keyboardWillHideReceiver(notification: NSNotification) {
        let userInfo = notification.userInfo
        guard let duration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        keyboardWillHide(duration: duration)
    }
}
