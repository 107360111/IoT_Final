//
//  SuspendTool.swift
//  IoT_Final
//
//  Created by mmslab406-mini2018-2 on 2023/6/12.
//

import Foundation
import UIKit

enum SuspendType {
    case none
    case single
    case multi
}

class SuspendTool: NSObject {
    static let sharedInstance = SuspendTool()
    private var suspendWindows: [SuspendWindow] = []
  //  var semicircle: Semicircle?
    var origin: CGPoint = CGPoint.init(x: 10, y: 300)

    static func showSuspendWindow(rootViewController: UIViewController, RSSINumber: Int) {
      let tool = SuspendTool.sharedInstance
      let window = SuspendWindow.init(rootViewController: rootViewController, RSSINumber: RSSINumber, frame: CGRect.init(origin: tool.origin, size: CGSize.init(width: radious, height: radious)))
      window.show()
      tool.suspendWindows.append(window)
    }
    
    static func replaceSuspendWindow(rootViewController: UIViewController, RSSINumber: Int) {
      let tool = SuspendTool.sharedInstance
      tool.suspendWindows.removeAll()
      let window = SuspendWindow.init(rootViewController: rootViewController, RSSINumber: RSSINumber, frame: CGRect.init(origin: tool.origin, size: CGSize.init(width: radious, height: radious)))
      window.show()
      tool.suspendWindows.append(window)
    }

    static func remove(suspendWindow: SuspendWindow) {
      UIView.animate(withDuration: 0.25, animations: {
        suspendWindow.alpha = 0
      }) { (complete) in
          if let index = SuspendTool.sharedInstance.suspendWindows.firstIndex(of: suspendWindow) {
          SuspendTool.sharedInstance.suspendWindows.remove(at: index)
        }
      }
    }
    
    static func setLatestOrigin(origin: CGPoint) {
      SuspendTool.sharedInstance.origin = origin
    }
}
