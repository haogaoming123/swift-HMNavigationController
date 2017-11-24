//
//  ViewController.swift
//  HMNavigationControllerDemo
//
//  Created by haogaoming on 2017/11/23.
//  Copyright © 2017年 郝高明. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.green
        
        let btn = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 30))
        btn.backgroundColor = UIColor.red
        btn.addTarget(self, action: #selector(click), for: .touchUpInside)
        self.view.addSubview(btn)
    }
    
    @objc func click() {
        self.navigationController?.pushViewController(TwoViewController(), animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

