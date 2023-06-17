//
//  ViewController.swift
//  IoT_Final
//
//  Created by mmslab406-mini2018-2 on 2023/6/2.
//

import UIKit
import Lottie

class ViewController: UIViewController {
    
    @IBOutlet var constraint_cen: UIStackView!
    @IBOutlet var constraint_per: UIStackView!
    
    @IBOutlet var view_central: UIStackView!
    @IBOutlet var view_perpheral: UIStackView!
    
    @IBOutlet var view_central_gif: UIView!
    @IBOutlet var view_perpheral_gif: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        constraint_cen.layer.borderColor = CGColor(red: 256, green: 256, blue: 256, alpha: 0.7)
        constraint_cen.layer.borderWidth = 1
        constraint_cen.layer.cornerRadius = 16
        
        constraint_per.layer.borderColor = CGColor(red: 256, green: 256, blue: 256, alpha: 0.7)
        constraint_per.layer.borderWidth = 1
        constraint_per.layer.cornerRadius = 16
        
        view_central.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapCentral)))
        
        view_perpheral.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapPerpheral)))
        
        GIFInit(gif: "central", view: view_central_gif)
        GIFInit(gif: "perpheral", view: view_perpheral_gif)
    }
    
    private func GIFInit(gif: String, view: UIView) {
        let animationView = LottieAnimationView(name: gif)
        let animationSize = min(view.frame.width, view.frame.height)
        animationView.frame = CGRect(x: 0, y: 0, width: animationSize, height: animationSize)
        animationView.contentMode = .scaleAspectFit
        
        animationView.loopMode = .loop
        animationView.animationSpeed = 0.7
        
        view.addSubview(animationView)
        
        animationView.play()
    }
    
    @objc private func tapCentral() {
        self.navigationController?.pushViewController(CentralVC(), animated: false)
    }
    
    @objc private func tapPerpheral() {
        self.navigationController?.pushViewController(PeriphralVC(), animated: false)
    }
}
