//
//  PagerView.swift
//  ZjcDemo
//
//  Created by zhangjc on 2024/12/19.
//

import Foundation
import UIKit

private let kPagerViewMaxSectionCount = 200
private let kPagerViewMinSectionCount = 18

enum PagerScrollDirection: UInt {
    case left
    case right
}

class IndexSection: NSObject {
    var index: Int = 0
    var section: Int = 0

    init(index: Int, section: Int) {
        self.index = index
        self.section = section
    }
}

func MakeIndexSection(_ index: Int, _ section: Int) -> IndexSection {
    let indexSection = IndexSection(index: index, section: section)
    return indexSection
}

func EqualIndexSection(_ indexSection1: IndexSection, _ indexSection2: IndexSection) -> Bool {
    return indexSection1.index == indexSection2.index && indexSection1.section == indexSection2.section
}

@objc 
protocol PagerViewDataSource: NSObjectProtocol {
    @objc optional func numberOfItemsInPagerView(_ pageView: PagerView) -> Int
    @objc optional func layoutConfigForPagerView(_ pageView: PagerView) -> PagerViewLayoutConfig
    @objc optional func pagerView(_ pagerView: PagerView, cellForItemAtIndex index: Int) -> UICollectionViewCell
}

@objc
protocol PagerViewDelegate: NSObjectProtocol {
    @objc optional func pagerView(_ pageView: PagerView, didScrollFromIndex fromIndex: Int, toIndex: Int)
    @objc optional func pagerView(_ pageView: PagerView, didSelectedItemCell cell: UICollectionViewCell, atIndex index: Int)
    @objc optional func pagerView(_ pageView: PagerView, didSelectedItemCell cell: UICollectionViewCell, atIndexSection indexSection: IndexSection)
    // scrollViewDelegate
    @objc optional func pagerViewDidScroll(_ pageView: PagerView)
    @objc optional func pagerViewWillBeginDragging(_ pageView: PagerView)
    @objc optional func pagerViewDidEndDragging(_ pageView: PagerView, willDecelerate decelerate: Bool)
    @objc optional func pagerViewWillBeginDecelerating(_ pageView: PagerView)
    @objc optional func pagerViewDidEndDecelerating(_ pageView: PagerView)
    @objc optional func pagerViewWillBeginScrollingAnimation(_ pageView: PagerView)
    @objc optional func pagerViewDidEndScrollingAnimation(_ pageView: PagerView)
}

class PagerView: UIView {
    
    private var _timer: Timer?
    private var _numberOfItems: Int = 0
    private var _dequeueSection: Int = 0
    private var _firstScrollIndex: Int = -1
    private var _didLayout: Bool = false
    private var _didReloadData: Bool = false
    private var _needResetIndex: Bool = false
    private var _needClearLayout: Bool = false
    private var _indexSection: IndexSection = IndexSection(index: -1, section: -1)
    private var _beginDragIndexSection: IndexSection = IndexSection(index: 0, section: 0)
    
    // 代理和数据源
    weak var delegate: PagerViewDelegate?
    weak var dataSource: PagerViewDataSource?
    
    // 自动轮播
    var isInfiniteLoop: Bool = false
    var autoScrollInterval: CGFloat = 0.0 {
        didSet {
            self.removeTimer()
            // 增加定时器
            if autoScrollInterval > 0 && (superview != nil) {
              self.addTimer()
            }
        }
    }
    
    var reloadDataNeedResetIndex: Bool = false
    
    var curIndex: Int {
        return _indexSection.index
    }

    var tracking: Bool {
        return collectionView.isTracking == true
    }
    
    var dragging: Bool {
        return collectionView.isDragging == true
    }
    
    var decelerating: Bool {
        return collectionView.isDecelerating == true
    }
    
    var contentOffset: CGPoint {
        return collectionView.contentOffset
    }
    
    var curIndexCell: UICollectionViewCell? {
        return collectionView.cellForItem(at: IndexPath(item: _indexSection.index, section: _indexSection.section))
    }
    
    var visibleCells: [UICollectionViewCell] {
        return collectionView.visibleCells
    }

    var visibleIndexs: [IndexPath] {
       var indexs = [IndexPath]()
       for indexPath in (collectionView.indexPathsForVisibleItems) {
           indexs.append(indexPath)
       }
       return indexs
    }
    
    var backgroundView: UIView? {
        get { return collectionView.backgroundView }
        set { collectionView.backgroundView = newValue }
    }
    
    func cellForIndexPath(_ index: IndexPath) -> UICollectionViewCell?  {
        return collectionView.cellForItem(at: index)
    }
    
    // collectionView
    private lazy var collectionView: UICollectionView = {
        let layout = PagerViewLayout()
        // view
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = UIScrollView.DecelerationRate(rawValue: 1 - 0.0076)
        if #available(iOS 10.0, *) {
            collectionView.isPrefetchingEnabled = false
        }
        return collectionView
    }()
    
    // layoutConfig
    private var _layoutConfig: PagerViewLayoutConfig?
    var layoutConfig: PagerViewLayoutConfig? {
        if _layoutConfig == nil {
            _layoutConfig = dataSource?.layoutConfigForPagerView?(self)
            _layoutConfig?.isInfiniteLoop = isInfiniteLoop
            // 判断
            if (_layoutConfig?.itemSize.width ?? 0) <= 0 || (_layoutConfig?.itemSize.height ?? 0) <= 0 {
                _layoutConfig = nil
            }
        }
        return _layoutConfig
    }
    
    private func configureProperty() {
        _needResetIndex = false;
        _didReloadData = false;
        _didLayout = false;
        _beginDragIndexSection.index = 0;
        _beginDragIndexSection.section = 0;
        _indexSection.index = -1;
        _indexSection.section = -1;
        _firstScrollIndex = -1;
        
        autoScrollInterval = 0;
        isInfiniteLoop = true;
    }
    
    
    // MARK: - init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureProperty()
        addSubview(collectionView)
     }
     
     required init?(coder: NSCoder) {
         super.init(coder: coder)
         configureProperty()
         addSubview(collectionView)
     }

     deinit {
         removeTimer()
         collectionView.delegate = nil
         collectionView.dataSource = nil
     }
    
    
    // MARK: - Timer
    
    func addTimer() {
        if _timer != nil || autoScrollInterval <= 0 {
            return
        }
        
        _timer = Timer(timeInterval: TimeInterval(autoScrollInterval), target: self, selector: #selector(timerFired(_:)), userInfo: nil, repeats: true)
        RunLoop.main.add(_timer!, forMode: .common)
    }
    
    func removeTimer() {
        if _timer == nil {
            return
        }
        
        _timer?.invalidate()
        _timer = nil
    }
    
    @objc 
    func timerFired(_ timer: Timer?) {
        if (superview == nil) || (window == nil) || _numberOfItems == 0 || tracking {
            return
        }

        scrollToNearlyIndexAtDirection(.right, animate: true)
    }
    
    
    // MARK: - 注册 & 复用
    func registerClass(_ Class: AnyClass?, forCellWithReuseIdentifier identifier: String) {
        collectionView.register(Class, forCellWithReuseIdentifier: identifier)
    }

    func dequeueReusableCellWithReuseIdentifier(_ identifier: String, forIndex index: Int) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: IndexPath(item: index, section: _dequeueSection))
        return cell
    }
    
    
    //MARK: - reloadData
    
    func reloadData() {
        _didReloadData = true
        _needResetIndex = true
        
        setNeedClearLayout()
        clearLayout()
        updateData()
    }
    
    func updateData() {
        updateLayout()
        _numberOfItems = dataSource?.numberOfItemsInPagerView?(self) ?? 0
        collectionView.reloadData()

        if !_didLayout && !collectionView.frame.isEmpty && _indexSection.index < 0 {
            _didLayout = true
        }

        let needResetIndex = _needResetIndex && reloadDataNeedResetIndex
        _needResetIndex = false

        if needResetIndex {
            removeTimer()
        }

        resetPagerViewAtIndex((_indexSection.index < 0 && !collectionView.frame.isEmpty) || needResetIndex ? 0 : _indexSection.index)

        if needResetIndex {
            addTimer()
        }
    }
    
    func scrollToNearlyIndexAtDirection(_ direction: PagerScrollDirection, animate: Bool) {
        let indexSection = self.nearlyIndexPathAtDirection(direction)
        self.scrollToItemAtIndexSection(indexSection, animate: animate)
    }

    func scrollToItemAtIndex(_ index: Int, animate: Bool) {
        if !_didLayout && _didReloadData {
            _firstScrollIndex = index
        } else {
            _firstScrollIndex = -1
        }

        if !isInfiniteLoop {
            self.scrollToItemAtIndexSection(MakeIndexSection(index, 0), animate: animate)
            return
        }

        self.scrollToItemAtIndexSection(MakeIndexSection(index, index >= self.curIndex ? _indexSection.section : _indexSection.section + 1), animate: animate)
    }

    func scrollToItemAtIndexSection(_ indexSection: IndexSection, animate: Bool) {
        if _numberOfItems <= 0 || !self.isValidIndexSection(indexSection) {
            return
        }

        if animate {
            delegate?.pagerViewWillBeginScrollingAnimation?(self)
        }

        let offset = self.caculateOffsetXAtIndexSection(indexSection)
        collectionView.setContentOffset(CGPoint(x: offset, y: collectionView.contentOffset.y ), animated: animate)
    }
    
    
    // MARK: - layout
  
    func updateLayout() {
        guard let layoutConfig = layoutConfig else {
            return
        }

        layoutConfig.isInfiniteLoop = isInfiniteLoop
        (collectionView.collectionViewLayout as? PagerViewLayout)?.layoutConfig = layoutConfig
    }
    
    func clearLayout() {
        if _needClearLayout {
            _layoutConfig = nil
            _needClearLayout = false
        }
    }
    
    func setNeedClearLayout() {
        _needClearLayout = true
    }
    
    func setNeedUpdateLayout() {
        guard layoutConfig != nil else {
            return
        }

        self.clearLayout()
        self.updateLayout()
        collectionView.collectionViewLayout.invalidateLayout()
        self.resetPagerViewAtIndex(_indexSection.index < 0 ? 0 : _indexSection.index)
    }
    
    func isValidIndexSection(_ indexSection: IndexSection) -> Bool {
        return indexSection.index >= 0 && indexSection.index < _numberOfItems && indexSection.section >= 0 && indexSection.section < kPagerViewMaxSectionCount
    }

    func nearlyIndexPathAtDirection(_ direction: PagerScrollDirection) -> IndexSection {
        return self.nearlyIndexPathForIndexSection(_indexSection, direction: direction)
    }
    
    func nearlyIndexPathForIndexSection(_ indexSection: IndexSection, direction: PagerScrollDirection) -> IndexSection {
        if indexSection.index < 0 || indexSection.index >= _numberOfItems {
            return indexSection
        }

        if !isInfiniteLoop {
            if direction == .right && indexSection.index == _numberOfItems - 1 {
                return autoScrollInterval > 0 ? MakeIndexSection(0, 0) : indexSection
            } else if direction == .right {
                return MakeIndexSection(indexSection.index + 1, 0)
            }

            if indexSection.index == 0 {
                return autoScrollInterval > 0 ? MakeIndexSection(_numberOfItems - 1, 0) : indexSection
            }

            return MakeIndexSection(indexSection.index - 1, 0)
        }

        if direction == .right {
            if indexSection.index < _numberOfItems - 1 {
                return MakeIndexSection(indexSection.index + 1, indexSection.section)
            }

            if indexSection.section >= kPagerViewMaxSectionCount - 1 {
                return MakeIndexSection(indexSection.index, kPagerViewMaxSectionCount - 1)
            }

            return MakeIndexSection(0, indexSection.section + 1)
        }

        if indexSection.index > 0 {
            return MakeIndexSection(indexSection.index - 1, indexSection.section)
        }

        if indexSection.section <= 0 {
            return MakeIndexSection(indexSection.index, 0)
        }

        return MakeIndexSection(_numberOfItems - 1, indexSection.section - 1)
    }
    
    func caculateIndexSectionWithOffsetX(_ offsetX: CGFloat) -> IndexSection {
        if _numberOfItems <= 0 {
            return MakeIndexSection(0, 0)
        }

        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        let itemWidth = (layout?.itemSize.width ?? 0) + (layout?.minimumInteritemSpacing ?? 0)
        let leftEdge = (isInfiniteLoop ? layoutConfig?.sectionInset.left : layoutConfig?.onlyOneSectionInset.left) ?? 0
        let width = collectionView.frame.width
        let middleOffset = offsetX + width / 2
        var curIndex = 0
        var curSection = 0

        if middleOffset - leftEdge >= 0 {
            var itemIndex = Int((middleOffset - leftEdge + CGFloat(layout?.minimumInteritemSpacing ?? 0) / 2) / itemWidth)
            if itemIndex < 0 {
                itemIndex = 0
            } else if itemIndex >= _numberOfItems * kPagerViewMaxSectionCount {
                itemIndex = _numberOfItems * kPagerViewMaxSectionCount - 1
            }

            curIndex = itemIndex % _numberOfItems
            curSection = itemIndex / _numberOfItems
        }

        return MakeIndexSection(curIndex, curSection)
    }
    
    func caculateOffsetXAtIndexSection(_ indexSection: IndexSection) -> CGFloat {
        if _numberOfItems == 0 {
            return 0
        }

        let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        let itemWidth = (layout?.itemSize.width ?? 0) + (layout?.minimumInteritemSpacing ?? 0)
        let edge = (isInfiniteLoop ? layoutConfig?.sectionInset : layoutConfig?.onlyOneSectionInset) ?? .zero
        let leftEdge = edge.left
        let rightEdge = edge.right
        let width = collectionView.frame.width
        var offsetX: CGFloat = 0

        if !isInfiniteLoop && !(layoutConfig?.itemHorizontalCenter == true) && indexSection.index == _numberOfItems - 1 {
            offsetX = leftEdge + itemWidth * CGFloat(indexSection.index + indexSection.section * _numberOfItems) - (width - itemWidth) - CGFloat(layout?.minimumInteritemSpacing ?? 0) + rightEdge
        } else {
            offsetX = leftEdge + itemWidth * CGFloat(indexSection.index + indexSection.section * _numberOfItems) - CGFloat((layout?.minimumInteritemSpacing ?? 0) / 2.0) - (width - itemWidth) / 2.0
        }

        return max(offsetX, 0)
    }
    
    func resetPagerViewAtIndex(_ index: Int) {
        var index = index
        if _didLayout && _firstScrollIndex >= 0 {
            index = _firstScrollIndex
            _firstScrollIndex = -1
        }

        if index < 0 {
            return
        }

        if index >= _numberOfItems {
            index = 0
        }

        self.scrollToItemAtIndexSection(MakeIndexSection(index, isInfiniteLoop ? kPagerViewMaxSectionCount / 3 : 0), animate: false)

        if !isInfiniteLoop && _indexSection.index < 0 {
            self.scrollViewDidScroll(collectionView)
        }
    }
    
    func recyclePagerViewIfNeed() {
        if !isInfiniteLoop {
            return
        }

        if _indexSection.section > kPagerViewMaxSectionCount - kPagerViewMinSectionCount || _indexSection.section < kPagerViewMinSectionCount {
            self.resetPagerViewAtIndex(_indexSection.index)
        }
    }
    

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let needUpdateLayout = !collectionView.frame.equalTo(bounds)
        collectionView.frame = bounds
        if (_indexSection.section < 0 || needUpdateLayout) && (_numberOfItems > 0 || _didReloadData) {
            _didLayout = true
            setNeedUpdateLayout()
        }
    }
    
}


extension PagerView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return isInfiniteLoop ? kPagerViewMaxSectionCount : 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
       _numberOfItems = dataSource?.numberOfItemsInPagerView?(self) ?? 0
       return _numberOfItems
    }
       
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       _dequeueSection = indexPath.section
       return dataSource?.pagerView?(self, cellForItemAtIndex: indexPath.row) ?? UICollectionViewCell()
    }
       
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
       if !isInfiniteLoop {
           return layoutConfig?.onlyOneSectionInset ?? .zero
       }

       if section == 0 {
           return layoutConfig?.firstSectionInset ?? .zero
       } else if section == kPagerViewMaxSectionCount - 1 {
           return layoutConfig?.lastSectionInset ?? .zero
       } else {
           return layoutConfig?.middleSectionInset ?? .zero
       }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
       if let cell = collectionView.cellForItem(at: indexPath) {
           delegate?.pagerView?(self, didSelectedItemCell: cell, atIndex: indexPath.item)
           delegate?.pagerView?(self, didSelectedItemCell: cell, atIndexSection: MakeIndexSection(indexPath.item, indexPath.section))
       }
    }


    // UIScrollViewDeleGate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
       if !_didLayout {
           return
       }

       let newIndexSection = self.caculateIndexSectionWithOffsetX(scrollView.contentOffset.x)
       if _numberOfItems <= 0 || !self.isValidIndexSection(newIndexSection) {
           return
       }

       let indexSection = _indexSection
       _indexSection = newIndexSection

       delegate?.pagerViewDidScroll?(self)

       if !EqualIndexSection(_indexSection, indexSection) {
           delegate?.pagerView?(self, didScrollFromIndex: max(indexSection.index, 0), toIndex: _indexSection.index)
       }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
       if autoScrollInterval > 0 {
           self.removeTimer()
       }

       _beginDragIndexSection = self.caculateIndexSectionWithOffsetX(scrollView.contentOffset.x)
       delegate?.pagerViewWillBeginDragging?(self)
    }
       
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
       if abs(velocity.x) < 0.35 || !EqualIndexSection(_beginDragIndexSection, _indexSection) { //velocity.x 滚动力度 默认0.35
           targetContentOffset.pointee.x = caculateOffsetXAtIndexSection(_indexSection)
           return
       }

       var direction = PagerScrollDirection.right
       if (scrollView.contentOffset.x < 0 && targetContentOffset.pointee.x <= 0) || (targetContentOffset.pointee.x < scrollView.contentOffset.x && scrollView.contentOffset.x < scrollView.contentSize.width - scrollView.frame.size.width) {
           direction = PagerScrollDirection.left
       }

       let indexSection = nearlyIndexPathForIndexSection(_indexSection, direction: direction)
       targetContentOffset.pointee.x = caculateOffsetXAtIndexSection(indexSection)
    }
       
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
       if autoScrollInterval > 0 {
           self.addTimer()
       }
       
       delegate?.pagerViewDidEndDragging?(self, willDecelerate: decelerate)
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
       delegate?.pagerViewWillBeginDecelerating?(self)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
       self.recyclePagerViewIfNeed()
       delegate?.pagerViewDidEndDecelerating?(self)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
       self.recyclePagerViewIfNeed()
       delegate?.pagerViewDidEndScrollingAnimation?(self)
    }
    
}


class PagerViewItemCell: UICollectionViewCell {
    
    func opcityDidChanged(_ opcity: CGFloat) {
        // 子类重载
    }
        
    override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        if let opacity = (layoutAttributes as? PagerViewLayoutAttributes)?.opacity {
            opcityDidChanged(opacity)
        }
    }
    
}
