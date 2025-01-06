//
//  ViewController.swift
//  JCPagerView
//
//  Created by zhangjc on 2025/1/6.
//

import UIKit

class ViewController: UIViewController, PagerViewDelegate, PagerViewDataSource {
    
    private let items = ["1", "2", "3", "4", "5", "6", "7", "8"]
    
    private lazy var pager: PagerView = {
        let view = PagerView(frame: CGRect(x: 0, y: 100, width: view.frame.width, height: 300))
        view.autoScrollInterval = 0.0
        view.isInfiniteLoop = false
        view.dataSource = self
        view.delegate = self
        view.registerClass(PagerViewCell.self, forCellWithReuseIdentifier: "PagerViewCell")
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    
    //MARK: - PagerViewDelegate & PagerViewDataSource

    func layoutConfigForPagerView(_ pageView: PagerView) -> PagerViewLayoutConfig {
        let layout = PagerViewLayoutConfig()
        layout.layoutType = .normal
        layout.itemSize = CGSize(width: 300, height: 300)
        layout.itemSpacing = 20
        layout.minimumAlpha = 0.2
        layout.itemHorizontalCenter = true
        layout.shouldOpenNormalOpcity = true
        return layout
    }

    func numberOfItemsInPagerView(_ pageView: PagerView) -> Int {
        return items.count
    }

    func pagerView(_ pagerView: PagerView, cellForItemAtIndex index: Int) -> UICollectionViewCell {
        let cell = pagerView.dequeueReusableCellWithReuseIdentifier("PagerViewCell", forIndex: index)
        if let newCell = cell as? PagerViewCell {
            let itemModel = items[index]
            newCell.fillData(itemModel)
        }
        return cell
    }

    func pagerView(_ pageView: PagerView, didScrollFromIndex fromIndex: Int, toIndex: Int) {
        print("from:\(fromIndex) --> to:\(toIndex)")
    }
    
    func pagerView(_ pageView: PagerView, didSelectedItemCell cell: UICollectionViewCell, atIndex index: Int) {
        print("click:\(index)")
    }

}



class PagerViewCell: PagerViewItemCell {
    // 坑位内容
    lazy var itemView: UIView = {
        let view = UIView(frame: self.contentView.bounds)
        view.backgroundColor = .red
        return view
    }()
    
    // 蒙层view
    lazy var coverView: UIView = {
        let view = UIView(frame: self.contentView.bounds)
        view.backgroundColor = .black
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
   }
    
   required init?(coder: NSCoder) {
       super.init(coder: coder)
       setupUI()
   }
    
    func setupUI() {
        itemView.addSubview(coverView)
        contentView.addSubview(itemView)
    }
    
    func fillData(_ data: String) {
        
    }

    override func opcityDidChanged(_ opcity: CGFloat) {
        coverView.alpha = opcity
    }

}
