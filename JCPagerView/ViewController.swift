//
//  ViewController.swift
//  JCPagerView
//
//  Created by zhangjc on 2025/1/6.
//

import UIKit

class ViewController: UIViewController, PagerViewDelegate, PagerViewDataSource {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let btn = UIButton(type: .system)
        btn.backgroundColor = .red
        btn.frame = CGRect(x: 100, y: 100, width: 80, height: 50)
        btn.addTarget(self, action: #selector(openPop), for: .touchUpInside)
        btn.setTitle("展示", for: .normal)
        view.addSubview(btn)        
    }
    
    
    @objc
    func openPop() {
        let hoverView = JCPopView(frame: view.bounds)
        hoverView.alpha = 0

        view.addSubview(hoverView)
        hoverView.updateItems(["111", "222", "333", "444", "555", "666", "777", "888"], index: 0)
        // 动画
        UIView.animate(withDuration: 0.25) {
            hoverView.alpha = 1
        }
    }
  
}

