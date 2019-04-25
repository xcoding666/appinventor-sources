// -*- mode: swift; swift-mode:basic-offset: 2; -*-
// Copyright © 2017-2019 Massachusetts Institute of Technology, All rights reserved.

import Foundation

public class LinearViewItem: NSObject {

  @objc public let view: UIView

  @objc public init(_ view: UIView) {
    self.view = view
  }

}

extension UIView {
  @objc func isRTL() -> Bool {
    return UIView.userInterfaceLayoutDirection(for: self.semanticContentAttribute) == UIUserInterfaceLayoutDirection.rightToLeft
  }
}

private class HelperView: UIView {
  open override var intrinsicContentSize: CGSize {
    get {
      return CGSize.zero
    }
  }
}

let UILayoutPriorityDefaultMedium = (Int(UILayoutPriority.defaultHigh.rawValue + UILayoutPriority.defaultLow.rawValue)) / 2
let TightSizingPriority = UILayoutPriority(10)
let ConstraintPriority = UILayoutPriority(8)
let DefaultSizingPriority = UILayoutPriority(6)
let FillParentHuggingPriority = UILayoutPriority(5)

public class LinearView: UIView {
  fileprivate var _outer = UIStackView()
  fileprivate var _inner = UIStackView()
  fileprivate var _horizontalAlign = HorizontalGravity.left
  fileprivate var _verticalAlign = VerticalGravity.top
  fileprivate var _orientation = HVOrientation.vertical
  fileprivate var _items = [LinearViewItem]()
  fileprivate var _head = HelperView()
  fileprivate var _tail = HelperView()
  fileprivate var _innerHead = HelperView()
  fileprivate var _innerTail = HelperView()
  fileprivate var _outerEqualConstraint: NSLayoutConstraint!
  fileprivate var _innerEqualConstraint: NSLayoutConstraint!
  fileprivate var _equalConstraint: NSLayoutConstraint!
  fileprivate var _backgroundView = UIView()

  override init(frame aRect: CGRect) {
    super.init(frame: aRect)
    setup()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  private func setup() {
    clipsToBounds = true
    translatesAutoresizingMaskIntoConstraints = false
    _outer.translatesAutoresizingMaskIntoConstraints = false
    _inner.translatesAutoresizingMaskIntoConstraints = false
    _backgroundView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(_backgroundView)
    addSubview(_outer)
    addConstraint(_backgroundView.widthAnchor.constraint(equalTo: widthAnchor))
    addConstraint(_backgroundView.heightAnchor.constraint(equalTo: heightAnchor))
    addConstraint(_backgroundView.topAnchor.constraint(equalTo: topAnchor))
    addConstraint(_backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor))
    _outer.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
    _outer.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
    _outer.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    _outer.topAnchor.constraint(equalTo: topAnchor).isActive = true
    _outer.spacing = 0
    _outer.alignment = .top
    _outer.distribution = .fill
    _outer.axis = .horizontal
    _inner.spacing = 0
    _inner.alignment = .leading
    _inner.distribution = .fill
    _inner.axis = .vertical
    _outer.addArrangedSubview(_head)
    _outer.addArrangedSubview(_inner)
    _outer.addArrangedSubview(_tail)
    _inner.addArrangedSubview(_innerHead)
    _inner.addArrangedSubview(_innerTail)
    updatePositioningConstraints()
    updatePriorities()
    addDefaultDimension(for: widthAnchor, length: kEmptyHVArrangementWidth)
    addDefaultDimension(for: heightAnchor, length: kEmptyHVArrangementHeight)
  }

  @objc open var scrollEnabled: Bool {
    @objc(isScrollEnabled)
    get {
      return false
    }
    set(scroll) {
    }
  }

  open var horizontalAlignment: HorizontalGravity {
    get {
      return _horizontalAlign
    }
    set(align) {
      if _horizontalAlign != align {
        _horizontalAlign = align
        updatePriorities()
        updateHorizontalAlignment()
      }
    }
  }

  open var verticalAlignment: VerticalGravity {
    get {
      return _verticalAlign
    }
    set(align) {
      if _verticalAlign != align {
        _verticalAlign = align
        updatePriorities()
        updateVerticalAlignment()
      }
    }
  }

  open var orientation: HVOrientation {
    get {
      return _orientation
    }
    set(orientation) {
      if _orientation != orientation {
        _orientation = orientation
        removeConstraint(_outerEqualConstraint)
        _inner.removeConstraint(_innerEqualConstraint)
        if _orientation == .horizontal {
          _inner.axis = .horizontal
          _outer.axis = .vertical
        } else {
          _inner.axis = .vertical
          _outer.axis = .horizontal
        }
        updatePositioningConstraints()
        updatePriorities()
        updateHorizontalAlignment()
        updateVerticalAlignment()
      }
    }
  }

  @objc open func addItem(_ item: LinearViewItem) {
    _inner.insertSubview(item.view, at: _inner.subviews.count - 1)
    _inner.insertArrangedSubview(item.view, at: _inner.arrangedSubviews.count - 1)
    _items.append(item)
  }

  open override var backgroundColor: UIColor? {
    get {
      return super.backgroundColor
    }
    set(color) {
      _backgroundView.backgroundColor = color
    }
  }

  // MARK: Private Implementation

  private func updateHorizontalAlignment() {
    if _orientation == .vertical {
      switch _horizontalAlign {
      case .left:
        _inner.alignment = .leading
      case .center:
        _inner.alignment = .center
      case .right:
        _inner.alignment = .trailing
      }
    }
  }

  private func updateVerticalAlignment() {
    if _orientation == .horizontal {
      switch _verticalAlign {
      case .top:
        _inner.alignment = .top
      case .center:
        _inner.alignment = .center
      case .bottom:
        _inner.alignment = .bottom
      }
    }
  }

  private var horizontalHead: UIView {
    get {
      return _orientation == .horizontal ? _innerHead : _head
    }
  }

  private var horizontalTail: UIView {
    get {
      return _orientation == .horizontal ? _innerTail : _tail
    }
  }

  private var verticalHead: UIView {
    get {
      return _orientation == .vertical ? _innerHead : _head
    }
  }

  private var verticalTail: UIView {
    get {
      return _orientation == .vertical ? _innerTail : _tail
    }
  }

  private func updatePositioningConstraints() {
    if _outerEqualConstraint != nil {
      removeConstraint(_outerEqualConstraint)
      _inner.removeConstraint(_innerEqualConstraint)
    }
    if _orientation == .horizontal {
      _outerEqualConstraint = _head.heightAnchor.constraint(equalTo: _tail.heightAnchor)
      _innerEqualConstraint = _innerHead.widthAnchor.constraint(equalTo: _innerTail.widthAnchor)
      _equalConstraint = widthAnchor.constraint(equalTo: _inner.widthAnchor)
    } else {
      _outerEqualConstraint = _head.widthAnchor.constraint(equalTo: _tail.widthAnchor)
      _innerEqualConstraint = _innerHead.heightAnchor.constraint(equalTo: _innerTail.heightAnchor)
      _equalConstraint = heightAnchor.constraint(equalTo: _inner.heightAnchor)
    }
    _outerEqualConstraint.priority = ConstraintPriority
    _innerEqualConstraint.priority = ConstraintPriority
    addConstraint(_equalConstraint)
    addConstraint(_outerEqualConstraint)
    _inner.addConstraint(_innerEqualConstraint)
  }

  private func updatePriorities() {
    // Horizontal Head has the following fixed properties
    horizontalHead.setContentCompressionResistancePriority(DefaultSizingPriority, for: .horizontal)
    horizontalHead.setContentCompressionResistancePriority(DefaultSizingPriority, for: .vertical)
    horizontalHead.setContentHuggingPriority(DefaultSizingPriority, for: .vertical)

    // Horizontal Tail has the following fixed properties
    horizontalTail.setContentCompressionResistancePriority(DefaultSizingPriority, for: .horizontal)
    horizontalTail.setContentCompressionResistancePriority(DefaultSizingPriority, for: .vertical)
    horizontalTail.setContentHuggingPriority(DefaultSizingPriority, for: .vertical)

    // Vertical Head has the following fixed properties
    verticalHead.setContentCompressionResistancePriority(DefaultSizingPriority, for: .vertical)
    verticalHead.setContentCompressionResistancePriority(DefaultSizingPriority, for: .horizontal)
    verticalHead.setContentHuggingPriority(DefaultSizingPriority, for: .horizontal)

    // Vertical Tail has the following fixed properties
    verticalTail.setContentCompressionResistancePriority(DefaultSizingPriority, for: .vertical)
    verticalTail.setContentCompressionResistancePriority(DefaultSizingPriority, for: .horizontal)
    verticalTail.setContentHuggingPriority(DefaultSizingPriority, for: .horizontal)

    // Dynamic horizontal control
    horizontalHead.setContentHuggingPriority(DefaultSizingPriority, for: .horizontal)
    horizontalTail.setContentHuggingPriority(DefaultSizingPriority, for: .horizontal)
    switch _horizontalAlign {
    case .left:
      horizontalHead.setContentHuggingPriority(TightSizingPriority, for: .horizontal)
    case .center:
      break
    case .right:
      horizontalTail.setContentHuggingPriority(TightSizingPriority, for: .horizontal)
    }

    // Dynamic vertical control
    verticalHead.setContentHuggingPriority(DefaultSizingPriority, for: .vertical)
    verticalTail.setContentHuggingPriority(DefaultSizingPriority, for: .vertical)
    switch _verticalAlign {
    case .top:
      verticalHead.setContentHuggingPriority(TightSizingPriority, for: .vertical)
    case .center:
      break
    case .bottom:
      verticalTail.setContentHuggingPriority(TightSizingPriority, for: .vertical)
    }
  }
}
