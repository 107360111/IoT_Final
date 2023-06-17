//
//  UIViewController+FF.swift
//  IoT_Final
//
//  Created by mmslab406-mini2018-2 on 2023/6/12.
//

import Foundation
import UIKit


extension UIViewController {
    
    enum Animator {
        case enlarge
        case fade
        case fadeOut
        case pushFromBottom
        case pushFromLeft
    }
    
    func suspend(RSSINumber: Int, type: SuspendType) {
        if type == .none {
          return
        }
        
        self.view.layer.masksToBounds = true
        UIView.animate(withDuration: 0.25, animations: {
          self.view.layer.cornerRadius = radious / 2.0
          self.view.frame = CGRect.init(origin: SuspendTool.sharedInstance.origin, size: CGSize.init(width: radious, height: radious))
          self.view.layoutIfNeeded()
        }) { (complete) in
          if type == .single {
              SuspendTool.replaceSuspendWindow(rootViewController: self, RSSINumber: RSSINumber)
          } else {
            SuspendTool.showSuspendWindow(rootViewController: self, RSSINumber: RSSINumber)
          }
        }
    }
    
    func spread(from point: CGPoint) {
      if let isContain = self.navigationController?.viewControllers.contains(self), isContain {
        return
      }
      self.view.frame = CGRect.init(origin: point, size: CGSize.init(width: radious, height: radious))
      UIViewController.currentViewController().navigationController?.pushViewController(self, animated: false)
      UIView.animate(withDuration: 0.25, animations: {
        self.view.layer.cornerRadius = 0
        self.view.frame = UIScreen.main.bounds
        self.view.layoutIfNeeded()
      })
    }
    
    static func currentViewController() -> UIViewController {
      var rootViewController: UIViewController? = nil
      for window in UIApplication.shared.windows {
        if (window.rootViewController != nil) {
          rootViewController = window.rootViewController
          break
        }
      }
      var viewController = rootViewController
      while (true) {
        if viewController?.presentedViewController != nil {
          viewController = viewController!.presentedViewController
        } else if viewController!.isKind(of: UINavigationController.self) {
          viewController = (viewController as! UINavigationController).visibleViewController
        } else if viewController!.isKind(of: UITabBarController.self) {
          viewController = (viewController as! UITabBarController).selectedViewController
        } else {
          break
        }
      }
      return viewController!
    }
    
    // MARK: -- W --
    
    func showWarningDialogVC(isCentral: Bool, isFindDevice: Bool, isOverDistance: Bool) {
        let VC = WarningDialogVC(isCentral: isCentral, isFindDevice: isFindDevice, isOverDistance: isOverDistance)
        
        VC.dialogShow(vc: self)
    }
    
    
    // MARK: -- Universal --
    
    func removePresented(animator: Animator = .enlarge, completion: (() -> Void)? = nil) {
        guard let presented = self.presentedViewController else { return }
        presented.dialogDismiss(animator: animator, completion: completion)
    }
    
    func dialogShow(vc: UIViewController, animator: Animator = .enlarge, completion: (() -> Void)? = nil) {
        self.modalPresentationStyle = .overFullScreen
        
        switch animator {
        case .enlarge, .pushFromBottom:
            // 防止閃爍
            self.view.isHidden = true
            vc.present(self, animated: false) {
                self.view.isHidden = false
                let backgroundColor: UIColor = self.view.backgroundColor ?? UIColor(red: 00, green: 00, blue: 00, alpha: 0.25)
                self.view.backgroundColor = .clear
                self.view.alpha = animator == .enlarge ? 0 : 1
                self.view.transform = animator == .enlarge ? CGAffineTransform(scaleX: 0.2, y: 0.2) : CGAffineTransform(translationX: 0, y: self.view.bounds.height)
                
                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: animator == .enlarge ? 0.35 : 0.45 , delay: 0.0, animations: {
                    self.view.alpha = 1
                    self.view.transform = CGAffineTransform.identity
                }, completion: { _ in
                    UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0.0) {
                        self.view.backgroundColor = backgroundColor
                    }
                })
                if let completion = completion {
                    completion()
                }
            }
            
        case .pushFromLeft:
            self.view.isHidden = true
            vc.present(self, animated: false) {
                self.view.isHidden = false
                self.view.transform = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.45, delay: 0.0, animations: {
                    self.view.transform = CGAffineTransform.identity
                })
                if let completion = completion {
                    completion()
                }
            }
            
        case .fade:
            let transition = CATransition()
            transition.duration = 0.1
            transition.type = CATransitionType.fade
            transition.subtype = CATransitionSubtype.fromBottom
            self.view.window?.layer.add(transition, forKey: kCATransition)
            vc.present(self, animated: false) {
                self.view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.view.alpha = 0
                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.1, delay: 0.0, animations: {
                    self.view.alpha = 1
                    self.view.transform = CGAffineTransform.identity
                })
                if let completion = completion {
                    completion()
                }
            }
            
        case .fadeOut:
            self.view.isHidden = true
            vc.present(self, animated: false) {
                self.view.isHidden = false
                self.view.alpha = 0
                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.6, delay: 0.0, animations: {
                    self.view.alpha = 1
                })
                if let completion = completion {
                    completion()
                }
            }
        }
    }
    
    func dialogDismiss(animator: Animator = .enlarge, completion: (() -> Void)? = nil) {
        switch animator {
        case .enlarge, .pushFromBottom:
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.05, delay: 0.0, animations: {
                self.view.backgroundColor = .clear
            }, completion: { _ in
                UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0.0, animations: {
                    self.view.transform = animator == .enlarge ? CGAffineTransform(scaleX: 0.01, y: 0.01) : CGAffineTransform(translationX: 0, y: self.view.bounds.height)
                }, completion: { _ in
                    self.dismiss(animated: false, completion: completion)
                })
            })
            
        case .pushFromLeft:
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.3, delay: 0.0, animations: {
                self.view.transform = CGAffineTransform(translationX: self.view.bounds.width, y: 0)
            }, completion: { _ in
                self.dismiss(animated: false, completion: completion)
            })
            
        case .fade:
            let transition = CATransition()
            transition.duration = 0.25
            transition.type = CATransitionType.fade
            transition.subtype = CATransitionSubtype.fromTop
            self.view.window?.layer.add(transition, forKey: kCATransition)
            self.dismiss(animated: false, completion: completion)
            
        case .fadeOut:
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: 0.5, delay: 0.0, animations: {
                self.view.alpha = 0
            }, completion: { _ in
                self.dismiss(animated: false, completion: completion)
            })
        }
    }
}
