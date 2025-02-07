//
//  JCPopView.swift
//  ZjcDemo
//
//  Created by zhangjc on 2024/12/20.
//

import Foundation
import UIKit

// stackView
class JCPopView: UIView, PagerViewDelegate, PagerViewDataSource {
    
    var videos: [String]?
    
    lazy var pager: PagerView = {
        let view = PagerView.init(frame: CGRect(x: 0, y: ( frame.height - 400) / 2.0, width: frame.width, height: 400))
        view.autoScrollInterval = 0.0
        view.isInfiniteLoop = false
        view.delegate = self
        view.dataSource = self
        view.registerClass(PagerViewCell.self, forCellWithReuseIdentifier: "111")
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        addSubview(pager)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("PagerView deinit")
    }
    
    
    func updateItems(_ items:[String], index: Int) {
        videos = items
        pager.reloadData()
    }
    
    
    func layoutConfigForPagerView(_ pageView: PagerView) -> PagerViewLayoutConfig {
        let layout = PagerViewLayoutConfig()
        layout.layoutType = .normal
        
        layout.itemHorizontalCenter = true
        layout.itemSize = CGSize(width: 500, height: 400)
        layout.itemSpacing = 10
        layout.minimumAlpha = 0.2
        layout.shouldOpenNormalOpcity = true
        return layout
    }
    
    func pagerView(_ pagerView: PagerView, cellForItemAtIndex index: Int) -> UICollectionViewCell {
        let cell = pagerView.dequeueReusableCellWithReuseIdentifier("111", forIndex: index)
        if let newCell = cell as? PagerViewCell {
            newCell.updateData("", index: index)
        }
        return cell
    }
    
    func numberOfItemsInPagerView(_ pageView: PagerView) -> Int {
        return videos?.count ?? 0
    }
    
    func pagerView(_ pageView: PagerView, didSelectedItemCell cell: UICollectionViewCell, atIndex index: Int) {
        print("selectIndex:\(index)")
        removeFromSuperview()
    }
    
    func pagerView(_ pageView: PagerView, didScrollFromIndex fromIndex: Int, toIndex: Int) {
        print("from:\(fromIndex) --> to:\(toIndex)")
    }
    
}


class PagerViewCell: PagerViewItemCell {
    
    var currentIndex = 0
    
    let imageView = UIImageView()
    let coverView = UIView()
    
    override init(frame: CGRect) {
       super.init(frame: frame)
        // 内容
        imageView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        imageView.backgroundColor = .red
        contentView.addSubview(imageView)
        
       // 蒙层
        coverView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        coverView.backgroundColor = .black
        contentView.addSubview(coverView)
   }

    required init?(coder: NSCoder) {
       fatalError("init(coder:) has not been implemented")
    }
    
    func updateData(_ data: String, index: Int) {
        currentIndex = index
        if 0 == index {
            imageView.frame = .zero
            imageView.center = CGPoint(x: contentView.frame.width / 2.0, y: contentView.frame.height / 2.0)
            UIView.animate(withDuration: 0.35) { [weak self] in
                self?.updateFrame()
            }
        }
    }
    
    func updateFrame() {
        imageView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
    }

    override func opcityDidChanged(_ opcity: CGFloat) {
        coverView.alpha = opcity
        print("\(currentIndex) ---- \(opcity)")
    }
    
    deinit {
        print("PagerViewCell deinit")
    }
    
}
