//
//  BasicViewController.swift
//  IoT_Final
//
//  Created by mmslab406-mini2018-2 on 2023/6/2.
//

import UIKit
import CoreBluetooth

class BasicViewController: UIViewController {
    var centralManager: CBCentralManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }
}
