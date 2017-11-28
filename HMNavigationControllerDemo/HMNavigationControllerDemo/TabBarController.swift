//
//  TabBarController.swift
//  HMNavigationControllerDemo
//
//  Created by haogaoming on 2017/11/27.
//  Copyright © 2017年 郝高明. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let nav1 = BaseNavigationController(rootViewController: ViewController())
//        nav1.disableDragBack = true
        nav1.tabBarItem.title = "首页1"
        
        let nav2 = BaseNavigationController(rootViewController: ViewController())
//        nav2.disableDragBack = true
        nav2.tabBarItem.title = "首页2"
        
        let nav3 = BaseNavigationController(rootViewController: ViewController())
//        nav3.disableDragBack = true
        nav3.tabBarItem.title = "首页3"
        
        self.viewControllers = [nav1,nav2,nav3]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
