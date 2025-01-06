//
//  PagerViewLayout.swift
//  ZjcDemo
//
//  Created by zhangjc on 2024/12/19.
//

import Foundation
import UIKit

enum PagerLayoutItemDirection: UInt {
    case left
    case center
    case right
}

enum PagerLayoutType: UInt {
    case normal
    case linear
    case coverflow
}

class PagerViewLayoutConfig: NSObject {
    
    weak var pageView: UIView?
    
    var itemSize: CGSize = .zero
    var itemSpacing: CGFloat = 0
    var sectionInset: UIEdgeInsets = .zero
    var layoutType: PagerLayoutType = .normal
    
    // 特殊属性 - 用于坑位蒙层
    var shouldOpenNormalOpcity: Bool = false
    
    // 通用属性
    var minimumScale: CGFloat = 0.8
    var minimumAlpha: CGFloat = 1.0
    var maximumAngle: CGFloat = 0.2
    // 滚动速率
    var rateOfChange: CGFloat = 0.4
    // 是否循环滚动
    var isInfiniteLoop: Bool = false
    // 坑位居中
    var itemVerticalCenter: Bool = true
    var itemHorizontalCenter: Bool = false
    // 滚动时候自适应间距
    var adjustSpacingWhenScroling: Bool = true
    
    override init() {
        super.init()
        minimumScale = 0.8;
        minimumAlpha = 1.0;
        maximumAngle = 0.2;
        rateOfChange = 0.4;
        itemVerticalCenter = true;
        adjustSpacingWhenScroling = true;
    }

    var onlyOneSectionInset: UIEdgeInsets {
        let leftSpace = (pageView != nil) && !isInfiniteLoop && itemHorizontalCenter ? ((pageView?.frame.width ?? 0.0) - itemSize.width) / 2 : sectionInset.left
        let rightSpace = (pageView != nil) && !isInfiniteLoop && itemHorizontalCenter ? ((pageView?.frame.width ?? 0.0) - itemSize.width) / 2 : sectionInset.right
        if itemVerticalCenter {
            let verticalSpace = ((pageView?.frame.height ?? 0.0) - itemSize.height) / 2
            return UIEdgeInsets(top: verticalSpace, left: leftSpace, bottom: verticalSpace, right: rightSpace)
        }
        return UIEdgeInsets(top: sectionInset.top, left: leftSpace, bottom: sectionInset.bottom, right: rightSpace)
    }
    
    var firstSectionInset: UIEdgeInsets {
        if itemVerticalCenter {
            let verticalSpace = ((pageView?.frame.height ?? 0.0) - itemSize.height) / 2
            return UIEdgeInsets(top: verticalSpace, left: sectionInset.left, bottom: verticalSpace, right: itemSpacing)
        }
        return UIEdgeInsets(top: sectionInset.top, left: sectionInset.left, bottom: sectionInset.bottom, right: itemSpacing)
    }
    
    var lastSectionInset: UIEdgeInsets {
        if itemVerticalCenter {
            let verticalSpace = ((pageView?.frame.height ?? 0.0) - itemSize.height) / 2
            return UIEdgeInsets(top: verticalSpace, left: 0, bottom: verticalSpace, right: sectionInset.right)
        }
        return UIEdgeInsets(top: sectionInset.top, left: 0, bottom: sectionInset.bottom, right: sectionInset.right)
    }
    
    var middleSectionInset: UIEdgeInsets {
      if itemVerticalCenter {
          let verticalSpace = ((pageView?.frame.height ?? 0.0) - itemSize.height) / 2
          return UIEdgeInsets(top: verticalSpace, left: 0, bottom: verticalSpace, right: itemSpacing)
      }
      return sectionInset
    }
    
}


class PagerViewLayout: UICollectionViewFlowLayout {
                
    var layoutConfig: PagerViewLayoutConfig? {
        didSet {
            layoutConfig?.pageView = collectionView
            //属性设置
            itemSize = layoutConfig?.itemSize ?? .zero
            minimumLineSpacing = layoutConfig?.itemSpacing ?? 0.0
            minimumInteritemSpacing = layoutConfig?.itemSpacing ?? 0.0
        }
    }
    
    override var itemSize: CGSize {
        get {
            guard let layoutConfig = layoutConfig else {
                return super.itemSize
            }
            return layoutConfig.itemSize
        }
        set {
            super.itemSize = newValue
        }
    }
    
    override var minimumLineSpacing: CGFloat {
        get {
            guard let layoutConfig = layoutConfig else {
                return super.minimumLineSpacing
            }
            return layoutConfig.itemSpacing
        }
        set {
            super.minimumLineSpacing = newValue
        }
    }
    
    override var minimumInteritemSpacing: CGFloat {
        get {
            guard let layoutConfig = layoutConfig else {
                return super.minimumInteritemSpacing
            }
            return layoutConfig.itemSpacing
        }
        set {
            super.minimumInteritemSpacing = newValue
        }
    }
    
    func shouldUpdateCustomLayout() -> Bool {
        if let layoutConfig = layoutConfig, (layoutConfig.layoutType != .normal || layoutConfig.shouldOpenNormalOpcity) {
            return true
        }
        return false
    }
    
    
    override class var layoutAttributesClass: AnyClass {
        return PagerViewLayoutAttributes.self
    }
    
    
    override init() {
        super.init()
        scrollDirection = .horizontal
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        scrollDirection = .horizontal
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        if shouldUpdateCustomLayout() {
           return true
        } else {
            return super.shouldInvalidateLayout(forBoundsChange: newBounds)
        }
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        if shouldUpdateCustomLayout() {
            let attributesArray = super.layoutAttributesForElements(in: rect) ?? []
            let visibleRect: CGRect = CGRect(origin: collectionView?.contentOffset ?? .zero, size: collectionView?.bounds.size ?? .zero )
            // 遍历
            for attributes in attributesArray {
                if !visibleRect.intersects(attributes.frame) {
                    continue
                }
                applyTransformToAttributes(attributes, layoutType: (layoutConfig?.layoutType ?? .normal))
            }
            return attributesArray;
        }

        return super.layoutAttributesForElements(in: rect)
    }
    
    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attributes = super.layoutAttributesForItem(at: indexPath)
        if shouldUpdateCustomLayout() {
            initializeTransformAttributes(attributes, layoutType: (layoutConfig?.layoutType ?? .normal))
        }
        return attributes
    }
    
    
    // MARK: - private
    
    private func direction(withCenterX centerX: CGFloat) -> PagerLayoutItemDirection {
        var direction: PagerLayoutItemDirection = .right
        
        let contentCenterX = (collectionView?.contentOffset.x ?? 0.0) + (collectionView?.frame.width ?? 0.0) / 2
         if abs(centerX - contentCenterX) < 0.5 {
             direction = .center
         } else if centerX - contentCenterX < 0 {
             direction = .left
         }

         return direction
    }
    
    private func initializeTransformAttributes(_ attributes: UICollectionViewLayoutAttributes?, layoutType: PagerLayoutType) {
        switch layoutType {
        case.normal:
            applyNormalTransformToAttributes(attributes, alpha: layoutConfig?.minimumAlpha ?? 0)
        case .linear:
            applyLinearTransformToAttributes(attributes, scale: layoutConfig?.minimumScale ?? 0, alpha: layoutConfig?.minimumAlpha ?? 0)
        case .coverflow:
            applyCoverflowTransformToAttributes(attributes, angle: layoutConfig?.maximumAngle ?? 0, alpha: layoutConfig?.minimumAlpha ?? 0)
          break
        }
    }
    
    private func applyTransformToAttributes(_ attributes: UICollectionViewLayoutAttributes?, layoutType: PagerLayoutType) {
        switch layoutType {
        case .normal:
            applyNormalTransformToAttributes(attributes)
        case .linear:
            applyLinearTransformToAttributes(attributes)
        case .coverflow:
            applyCoverflowTransformToAttributes(attributes)
          break
        }
    }
    
    // MARK: - Normal
    private func applyNormalTransformToAttributes(_ attributes: UICollectionViewLayoutAttributes?) {
        let collectionViewWidth = collectionView?.frame.size.width ?? 0
        if collectionViewWidth <= 0 {
            return
        }

        let centerX = (collectionView?.contentOffset.x ?? 0) + collectionViewWidth / 2
        let delta = abs((attributes?.center.x ?? 0) - centerX)
        let alpha = max(1 - delta / collectionViewWidth, (layoutConfig?.minimumAlpha ?? 0))
        
        (attributes as? PagerViewLayoutAttributes)?.opacity = (1.0 - alpha)
    }
    
    private func applyNormalTransformToAttributes(_ attributes: UICollectionViewLayoutAttributes?, alpha: CGFloat) {
        var alpha = alpha

        if let adjustSpacingWhenScroling = layoutConfig?.adjustSpacingWhenScroling, adjustSpacingWhenScroling {
            let direction = direction(withCenterX: attributes?.center.x ?? 0)
            if direction == .center {
                alpha = 1.0
            }
        }

        (attributes as? PagerViewLayoutAttributes)?.opacity = (1.0 - alpha)
    }
    
    
    // MARK: - Linear

    private func applyLinearTransformToAttributes(_ attributes: UICollectionViewLayoutAttributes?) {
        let collectionViewWidth = collectionView?.frame.size.width ?? 0
        if collectionViewWidth <= 0 {
            return
        }

        let centerX = (collectionView?.contentOffset.x ?? 0) + collectionViewWidth / 2
        let delta = abs((attributes?.center.x ?? 0) - centerX)
        let alpha = max(1 - delta / collectionViewWidth, (layoutConfig?.minimumAlpha ?? 0))
        let scale = max(1 - delta / collectionViewWidth * (layoutConfig?.rateOfChange ?? 0), layoutConfig?.minimumScale ?? 0)

        applyLinearTransformToAttributes(attributes, scale: scale, alpha: alpha)
    }
    
    private func applyLinearTransformToAttributes(_ attributes: UICollectionViewLayoutAttributes?, scale: CGFloat, alpha: CGFloat) {
        var scale = scale
        var alpha = alpha
        var transform = CGAffineTransform(scaleX: scale, y: scale)

        if let adjustSpacingWhenScroling = layoutConfig?.adjustSpacingWhenScroling, adjustSpacingWhenScroling {
            let direction = direction(withCenterX: attributes?.center.x ?? 0)
            var translate: CGFloat = 0
            switch direction {
            case .left:
                translate = 1.15 * (attributes?.size.width ?? 0) * (1 - scale) / 2
            case .right:
                translate = -1.15 * (attributes?.size.width ?? 0) * (1 - scale) / 2
            default: // center
                scale = 1.0
                alpha = 1.0
            }

            transform = transform.translatedBy(x: translate, y: 0)
        }

        (attributes as? PagerViewLayoutAttributes)?.opacity = (1.0 - alpha)
        attributes?.transform = transform
        attributes?.alpha = alpha
    }
    
    
    // MARK: - CoverFlow
    
    private func applyCoverflowTransformToAttributes(_ attributes: UICollectionViewLayoutAttributes?) {
        let collectionViewWidth = collectionView?.frame.size.width ?? 0
        if collectionViewWidth <= 0 {
            return
        }

        let centerX = (collectionView?.contentOffset.x ?? 0) + collectionViewWidth / 2
        let delta = abs((attributes?.center.x ?? 0) - centerX)
        let alpha = max(1 - delta / collectionViewWidth, layoutConfig?.minimumAlpha ?? 0)
        let angle = min(delta / collectionViewWidth * (1 - (layoutConfig?.rateOfChange ?? 0)), layoutConfig?.maximumAngle ?? 0)

        applyCoverflowTransformToAttributes(attributes, angle: angle, alpha: alpha)
    }
    
    private func applyCoverflowTransformToAttributes(_ attributes: UICollectionViewLayoutAttributes?, angle: CGFloat, alpha: CGFloat) {
        var angle = angle
        var alpha = alpha
        var translate: CGFloat = 0
        let direction = direction(withCenterX: attributes?.center.x ?? 0)
        var transform3D = CATransform3DIdentity
        transform3D.m34 = -0.002

        switch direction {
        case .left:
            translate = (1 - cos(angle * 1.2 * CGFloat.pi)) * (attributes?.size.width ?? 0)
        case .right:
            translate = -(1 - cos(angle * 1.2 * CGFloat.pi)) * (attributes?.size.width ?? 0)
            angle = -angle
        default:
            // center
            angle = 0
            alpha = 1
        }

        transform3D = CATransform3DRotate(transform3D, CGFloat.pi * angle, 0, 1, 0)
        if layoutConfig?.adjustSpacingWhenScroling == true {
            transform3D = CATransform3DTranslate(transform3D, translate, 0, 0)
        }

        (attributes as? PagerViewLayoutAttributes)?.opacity = (1.0 - alpha)
        attributes?.transform3D = transform3D
        attributes?.alpha = alpha
    }
    
}


class PagerViewLayoutAttributes: UICollectionViewLayoutAttributes {
    
    // 新增类型
    var opacity: CGFloat = 1
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? PagerViewLayoutAttributes else {
            return false
        }
        var isEqual = super.isEqual(object)
        isEqual = isEqual && (self.opacity == object.opacity)
        return isEqual
   }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! PagerViewLayoutAttributes
        copy.opacity = self.opacity
        return copy
    }
    
}
