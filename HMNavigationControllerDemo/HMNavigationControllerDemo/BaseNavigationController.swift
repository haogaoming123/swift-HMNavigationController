//
//  BaseNavigationController.swift
//  HMNavigationControllerDemo
//
//  Created by haogaoming on 2017/11/24.
//  Copyright © 2017年 郝高明. All rights reserved.
//

import UIKit

/// keywindow常量
fileprivate let KeyWindow = UIApplication.shared.keyWindow
/// width常量
fileprivate let screenWidth = UIScreen.main.bounds.size.width
/// 最小移动距离
fileprivate let moveMinX = (0.3 * screenWidth)

/// 全屏滑动时的状态
enum NavMovingStateEnumes: Int {
    case stanby = 0     //默认状态
    case dragBegan      //开始滑动
    case dragChanged    //滑动改变了
    case dragEnd        //滑动结束
    case decelerating   //滑动减速
}

extension UIViewController
{
    /// 是否开启全屏滑动返回
    open var disableDragBack: Bool {
        get{
            return objc_getAssociatedObject(self, "_disableDragBack") as! Bool
        }
        set{
            objc_setAssociatedObject(self, "_disableDragBack", newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
    }
}

class BaseNavigationController: UINavigationController
{
    /// 存储截屏图片的字典
    lazy var screenShotsDict: [String:UIImage] = [:]
    
    /// 移动的状态
    lazy var movingState: NavMovingStateEnumes = .stanby
    
    /// 显示上一个页面的截屏
    lazy var lastScreenShotView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    /// 显示上一个页面的截屏黑色背景
    lazy var backgroundView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height))
        view.backgroundColor = UIColor.black
        self.view.addSubview(view)
        //添加Shotview
        self.lastScreenShotView.frame = view.bounds
        view.addSubview(self.lastScreenShotView)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if disableDragBack {
            //为导航器添加拖拽手势
            let pan = UIPanGestureRecognizer(target: self, action: #selector(paningGestureReceive(_:)))
            pan.delegate = self
            self.view.addGestureRecognizer(pan)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

// MARK: - 重写navigationController方法
extension BaseNavigationController
{
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if viewControllers.count > 0 {
            screenShotsDict[pointer(topViewController)] = capture()
        }
        super.pushViewController(viewController, animated: animated)
    }
    
    override func popViewController(animated: Bool) -> UIViewController? {
        let poppedVC = super.popViewController(animated: animated)
        screenShotsDict.removeValue(forKey: pointer(poppedVC))
        return poppedVC
    }
    
    override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        let popedVCS = super.popToViewController(viewController, animated: animated)
        if popedVCS != nil {
            for vc in popedVCS! {
                screenShotsDict.removeValue(forKey: pointer(vc))
            }
        }
        screenShotsDict.removeValue(forKey: pointer(topViewController))
        return popedVCS
    }
    
    override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        let popedVCS = super.popToRootViewController(animated: animated)
        if popedVCS != nil {
            for vc in popedVCS! {
                screenShotsDict.removeValue(forKey: pointer(vc))
            }
        }
        screenShotsDict.removeValue(forKey: pointer(topViewController))
        return popedVCS
    }
    
    /// 重置页面的截屏(新增了页面会缺失截屏)
    override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        if let viewcontroller = topViewController {
            if viewControllers.contains(viewcontroller) {
                screenShotsDict[pointer(viewcontroller)] = capture()
            }
        }
        super.setViewControllers(viewControllers, animated: animated)
        
        var newDic: [String:UIImage] = [:]
        for vc in viewControllers {
            let obj = screenShotsDict[pointer(vc)]
            if obj != nil {
                newDic[pointer(vc)] = obj!
            }
        }
        screenShotsDict = newDic
    }
}

// MARK: - 滑动手势相关
extension BaseNavigationController: UIGestureRecognizerDelegate
{
    /// 滑动手势的事件
    ///
    /// - Parameter gesture: 手势
    @objc func paningGestureReceive(_ gesture: UIPanGestureRecognizer) {
        if self.viewControllers.count < 1 || self.disableDragBack == false {
            return
        }
        if gesture.state == .began {
            if movingState == .stanby {
                //默认状态下
                movingState = .dragBegan
                backgroundView.isHidden = false
                lastScreenShotView.image = lastScreenShot()
            }
        }else if gesture.state == .ended || gesture.state == .cancelled {
            if movingState == .dragBegan || movingState == .dragChanged {
                movingState = .dragEnd
                panGestureRecognizerDidFinish(gesture)
            }
        }else if gesture.state == .changed {
            if movingState == .dragBegan || movingState == .dragChanged {
                movingState = .dragChanged
                moveViewWithX(gesture.translation(in: KeyWindow).x)
            }
        }
    }
    
    //不响应的手势则传递下去
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // 手势落点在屏幕右边1/3, 不响应手势
        if touch.location(in: nil).x >= screenWidth * 2 / 3 {
            return false
        }
        return (self.viewControllers.count > 1 && self.disableDragBack)
    }
    
    //适配cell左滑删除的手势冲突
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // 手势不是 UIPanGestureRecognizer
        guard let ges = otherGestureRecognizer as? UIPanGestureRecognizer else { return false }
        // 手势落点在屏幕左边1/3
        if ges.location(in: nil).x <= screenWidth / 3 {
            return false
        }
        // 手势是 上下滑动
        let offset = ges.location(in: nil)
        if fabs(offset.x) <= fabs(offset.y) {
            return false
        }
        // 手势是 右滑
        if offset.x >= 0 {
            return false
        }
        // 应该是左滑了
        return true
    }
}

// MARK: - 滑动过程中的操作
extension BaseNavigationController
{
    /// 滑动结束的操作
    ///
    /// - Parameter pan: 滑动手势
    func panGestureRecognizerDidFinish(_ pan:UIPanGestureRecognizer) {
        //设置的拖拽衰减时间
        let decelerationTime: CGFloat = 0.4
        //获取手指离开时候的速率
        let velocityX = pan.velocity(in: KeyWindow).x
        //手指拖拽的距离
        let translationX = pan.translation(in: KeyWindow).x
        //按照一定decelerationTime的衰减时间，计算出来的目标位置
        let targetX = min(screenWidth , max(0, translationX + velocityX * decelerationTime / 2))
        //是否POP
        let pop = targetX > moveMinX
        //设置动画初始化速率为当前瘦子离开的速率
        let initialSpringVelocity = fabs(velocityX) / (pop ? screenWidth - translationX : translationX)
        
        movingState = .decelerating
        let frame = CGRect(x: 0, y: self.view.frame.origin.y, width: self.view.frame.size.width, height: self.view.frame.size.height)
        var adjustTabbarFrame = false
        if tabBarController != nil {
            if frame.equalTo(tabBarController!.view.frame) {
                adjustTabbarFrame = true
            }
            var superView = self.view
            while superView != tabBarController?.view && superView != nil {
                if !frame.equalTo(tabBarController!.view.frame) {
                    adjustTabbarFrame = false
                    break
                }
                superView = superView?.superview
            }
        }
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: initialSpringVelocity,
                       options: .curveEaseOut, animations: {
                        self.moveViewWithX(pop ? screenWidth : CGFloat(0))
        }) { (_) in
            self.backgroundView.isHidden = true
            if pop {
                _ = self.popViewController(animated: false)
            }
            self.view.frame = frame
            if adjustTabbarFrame {
                var superview = self.view
                while superview != self.tabBarController?.view && superview != nil {
                    superview?.frame = frame
                    superview = superview?.superview
                }
            }
            
            self.movingState = .stanby
            
            DispatchQueue.main.asyncAfter(deadline: .now()+(pop ? 0.3 : 0), execute: {
                //移动键盘
                let version = Float(UIDevice.current.systemVersion)
                if version != nil && version! >= Float(9) {
                    //ios9以上
                    let array = UIApplication.shared.windows as NSArray
                    array.enumerateObjects({ (obj, idx, stop) in
                        if let window = obj as? UIWindow {
                            if self.shouldMoveWith(window) {
                                window.transform = CGAffineTransform.identity
                            }
                        }
                    })
                }else {
                    //ios9以下
                    if UIApplication.shared.windows.count > 1 {
                        UIApplication.shared.windows[1].transform = CGAffineTransform.identity
                    }
                }
            })
        }
    }
    
    /// 设置移动
    ///
    /// - Parameter x: 移动距离
    func moveViewWithX(_ x: CGFloat) {
        // 设置水平位移在 [0, screenWidth] 之间
        let moveX = max(0, min(x, screenWidth))
        // 设置frame的x
        self.view.frame = CGRect(x: moveX, y: self.view.frame.origin.y, width: self.view.frame.size.width, height: self.view.frame.size.height)
        // 设置上一个截屏的缩放比例
        let scale = moveX / screenWidth * 0.05 + 0.95
        lastScreenShotView.transform = CGAffineTransform(scaleX: scale, y: scale)
        
        //移动键盘
        let version = Float(UIDevice.current.systemVersion)
        if version != nil && version! >= Float(9) {
            //ios9以上
            let array = UIApplication.shared.windows as NSArray
            array.enumerateObjects({ (obj, idx, stop) in
                if let window = obj as? UIWindow {
                    if self.shouldMoveWith(window) {
                        window.transform = CGAffineTransform(translationX: moveX, y: 0)
                    }
                }
            })
        }else {
            //ios9以下
            if UIApplication.shared.windows.count > 1 {
                UIApplication.shared.windows[1].transform = CGAffineTransform(translationX: moveX, y: 0)
            }
        }
    }
    
    /// 是否应该移动window
    func shouldMoveWith(_ window: UIWindow) -> Bool {
        let windowName = NSStringFromClass(window.classForCoder) as NSString
        return (windowName.length == 22 && windowName.hasPrefix("UI") && windowName.hasSuffix("RemoteKeyboardWindow")) || (windowName.length == 19 && windowName.hasPrefix("UI") && windowName.hasSuffix("TextEffectsWindow"))
    }
}

// MARK: - 无相关类工具：截屏、取地址
extension BaseNavigationController
{
    //截屏操作
    func capture() -> UIImage {
        var scaptureView = self.view!
        if tabBarController != nil {
            scaptureView = tabBarController!.view
        }
        //开始截屏
        UIGraphicsBeginImageContextWithOptions(scaptureView.bounds.size, scaptureView.isOpaque, 0)
        scaptureView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
    
    func pointer(_ objet: UIViewController?) -> String {
       return ""
    }
    
    /// 获取前一个页面的截屏
    ///
    /// - Returns: 截屏image
    func lastScreenShot() -> UIImage? {
        let lastVC = viewControllers[viewControllers.count - 2]
        return screenShotsDict[pointer(lastVC)]
    }
}
