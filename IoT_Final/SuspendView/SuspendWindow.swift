//
//  SuspendWindow.swift
//  IoT_Final
//
//  Created by mmslab406-mini2018-2 on 2023/6/12.
//

import UIKit

let radious: CGFloat = 100

class SuspendWindow: UIWindow {
    fileprivate let RSSINumber: Int
    fileprivate let space: CGFloat = 10
    
    init(rootViewController: UIViewController ,RSSINumber: Int, frame: CGRect) {
        self.RSSINumber = RSSINumber
        super.init(frame: frame)
        self.rootViewController = rootViewController
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        self.backgroundColor = UIColor.clear
        self.windowLevel = UIWindow.Level.alert - 1
        self.screen = UIScreen.main
        self.isHidden = false
        
        let distanceLabel = UILabel.init()
        distanceLabel.isUserInteractionEnabled = true
        distanceLabel.frame = self.bounds
        distanceLabel.layer.cornerRadius = radious / 2.0
        distanceLabel.layer.borderColor = UIColor.lightGray.cgColor
        distanceLabel.layer.borderWidth = 5
        distanceLabel.layer.masksToBounds = true
        distanceLabel.textColor = UIColor.white
        distanceLabel.text = "\(self.RSSIChangeToDispatch(RSSI: RSSINumber) / 10) m"
        self.addSubview(distanceLabel)
        
        let panGesture = UIPanGestureRecognizer.init(target: self, action: #selector(didPan(_:)))
        self.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(didTap(_:)))
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc fileprivate func didTap(_ tapGesture: UITapGestureRecognizer) {
        SuspendTool.sharedInstance.origin = self.frame.origin
        self.rootViewController?.spread(from: self.self.frame.origin)
        SuspendTool.remove(suspendWindow: self)
    }
    
    @objc fileprivate func didPan(_ panGesture: UIPanGestureRecognizer) {
        let point = panGesture.translation(in: panGesture.view)
        var originX = self.frame.origin.x + point.x
        if originX < space {
            originX = space
        } else if originX > UIScreen.main.bounds.width - radious - space {
            originX = UIScreen.main.bounds.width - radious - space
        }
        var originY = self.frame.origin.y + point.y
        if originY < space {
            originY = space
        } else if originY > UIScreen.main.bounds.height - radious - space {
            originY = UIScreen.main.bounds.height - radious - space
        }
        self.frame = CGRect.init(x: originX, y: originY, width: self.bounds.width, height: self.bounds.height)
        if panGesture.state == UIGestureRecognizer.State.cancelled || panGesture.state == UIGestureRecognizer.State.ended || panGesture.state == UIGestureRecognizer.State.failed {
            self.adjustFrameAfterPan()
        }
        panGesture.setTranslation(CGPoint.zero, in: self)
    }
    
    fileprivate func adjustFrameAfterPan() {
        var originX: CGFloat = space
        if self.center.x < UIScreen.main.bounds.width / 2 {
            originX = space
        } else if self.center.x >= UIScreen.main.bounds.width / 2 {
            originX = UIScreen.main.bounds.width - radious - space
        }
        UIView.animate(withDuration: 0.25, animations: {
            self.frame = CGRect.init(x: originX, y: self.frame.origin.y, width: self.frame.size.width, height: self.frame.size.height)
        }) { (complete) in
            SuspendTool.setLatestOrigin(origin: self.frame.origin)
        }
    }
    
    fileprivate func RSSIChangeToDispatch(RSSI: Int) -> Double {
        return pow(10, ((-56-Double(RSSI)) / (10 * 2))) * 3.2808
    }
}
