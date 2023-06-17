//
//  BLEListTableViewCell.swift
//  IoT_Final
//
//  Created by mmslab406-mini2018-2 on 2023/6/2.
//

import UIKit
import CoreBluetooth

class BLEListTableViewCell: UITableViewCell {
    @IBOutlet var label_name: UILabel!
    @IBOutlet var imageView_rssi: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func setCell(name: String, rssi: Int) {
        self.label_name.text = name
        self.imageView_rssi.image = UIImage(named: changeIconByRSSI(rssi: rssi))
    }
    
    private func changeIconByRSSI(rssi: Int) -> String {
        switch rssi {
        case -15 ..< 0:
            return "level1"
        case -30 ..< -15:
            return "level2"
        case -50 ..< -30:
            return "level3"
        case -70 ..< -50:
            return "level4"
        case -90 ..< -70:
            return "level5"
        default:
            return "level6"
        }
    }
}
