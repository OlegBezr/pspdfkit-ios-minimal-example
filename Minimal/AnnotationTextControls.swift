//
//  AnnotationTextControls.swift
//  Minimal
//
//  Created by Oleg Bezrukavnikov on 4/1/25.
//  Copyright © 2025 PSPDFKit GmbH. All rights reserved.
//

import PSPDFKitUI
import UIKit

class AnnotationTextControls: FreeTextAnnotationView {
  private var currentFontName = UIFont.systemFont(ofSize: 10).fontName
  private var currentFontSize: CGFloat = 10.0
  private var currentUserFontSize: CGFloat { currentFontSize / 10 }
  private var currentColor: UIColor = .white
  private var currentFillColor: UIColor = .clear
  private var currentTextAlignment: NSTextAlignment = .left
  private var currentAlpha: CGFloat = 1.0

  private lazy var fontNameButton: UIButton = {
    var configuration = UIButton.Configuration.plain()
    configuration.titleLineBreakMode = .byTruncatingTail
    configuration.title = currentFontName
    configuration.baseForegroundColor = .white
    configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
      var outgoing = incoming
      outgoing.font = .system(size: 16)
      return outgoing
    }
    configuration.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 28)

    let button = UIButton(configuration: configuration)
    button.contentHorizontalAlignment = .leading
    button.titleLabel?.lineBreakMode = .byTruncatingTail
    button.titleLabel?.numberOfLines = 2
    button.addTarget(self, action: #selector(pickFont), for: .touchUpInside)

    // Add chevron icon
    let chevronImage = UIImage(systemName: "chevron.up.chevron.down")?.withRenderingMode(.alwaysTemplate)
    let chevronImageView = UIImageView(image: chevronImage)
    chevronImageView.tintColor = .white
    chevronImageView.translatesAutoresizingMaskIntoConstraints = false
    button.addSubview(chevronImageView)

    NSLayoutConstraint.activate([
      chevronImageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
      chevronImageView.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -8),
      chevronImageView.widthAnchor.constraint(equalToConstant: 12),
      chevronImageView.heightAnchor.constraint(equalToConstant: 12),
    ])

    return button
  }()

  private lazy var fontSizeButton: UIButton = {
    let button = UIButton(type: .system)
    button.setTitle("\(Int(currentUserFontSize))pt", for: .normal)
    button.setTitleColor(.white, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
    button.menu = createFontSizeMenu()
    button.showsMenuAsPrimaryAction = true
    return button
  }()

  private lazy var textColorCircle: UIView = {
    let circle = UIView(frame: CGRect(x: 0, y: 0, width: 25, height: 25))
    circle.layer.cornerRadius = 12
    circle.layer.masksToBounds = true
    circle.backgroundColor = currentColor
    circle.layer.borderWidth = 1
    circle.layer.borderColor = UIColor.white.cgColor
    return circle
  }()

  private lazy var bgColorCircle: UIView = {
    let circle = UIView(frame: CGRect(x: 20, y: 0, width: 24, height: 24))
    circle.layer.cornerRadius = 12
    circle.layer.masksToBounds = true
    circle.backgroundColor = currentFillColor

    // Configure dotted border
    let borderColor = UIColor.white.cgColor
    let shapeLayer = CAShapeLayer()
    let shapeRect = CGRect(x: 0, y: 0, width: 24, height: 24)
    shapeLayer.bounds = shapeRect
    shapeLayer.position = CGPoint(x: 12, y: 12)
    shapeLayer.fillColor = UIColor.clear.cgColor
    shapeLayer.strokeColor = borderColor
    shapeLayer.lineWidth = 1
    shapeLayer.lineJoin = CAShapeLayerLineJoin.round
    shapeLayer.lineDashPattern = [4, 4]
    shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: 12).cgPath
    circle.layer.addSublayer(shapeLayer)

    return circle
  }()

  private lazy var colorMenuButton: UIButton = {
    let button = UIButton(type: .system)

    // Create container view for the circles
    let containerView = UIView(frame: button.bounds)
    containerView.isUserInteractionEnabled = false

    containerView.addSubview(bgColorCircle)
    containerView.addSubview(textColorCircle)
    button.addSubview(containerView)

    button.menu = createColorMenu()
    button.showsMenuAsPrimaryAction = true
    return button
  }()

  private lazy var alignmentButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(currentTextAlignment.icon, for: .normal)
    button.tintColor = .white
    button.menu = createAlignmentMenu()
    button.showsMenuAsPrimaryAction = true
    return button
  }()

  private lazy var dismissButton: UIButton = {
    let button = UIButton(type: .system)
    button.setImage(UIImage(systemName: "keyboard.chevron.compact.down"), for: .normal)
    button.tintColor = .white
    button.addTarget(self, action: #selector(dismissKeyboard), for: .touchUpInside)
    return button
  }()

  private lazy var controlsContainer: UIView = {
    let container = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 50))
    container.backgroundColor = .black
    container.layer.cornerRadius = 8
    container.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

    // Font name button with fixed width
    fontNameButton.frame = CGRect(x: 16, y: 10, width: 120, height: 30)
    container.addSubview(fontNameButton)

    // Font size button
    fontSizeButton.frame = CGRect(x: fontNameButton.frame.maxX + 16, y: 10, width: 50, height: 30)
    container.addSubview(fontSizeButton)

    // Color menu button
    colorMenuButton.frame = CGRect(x: fontSizeButton.frame.maxX + 16, y: 13, width: 46, height: 24)
    container.addSubview(colorMenuButton)

    // Text alignment button
    alignmentButton.frame = CGRect(x: colorMenuButton.frame.maxX + 16, y: 10, width: 32, height: 30)
    container.addSubview(alignmentButton)

    // Dismiss button
    dismissButton.frame = CGRect(x: container.bounds.width - 46, y: 12, width: 30, height: 30)
    container.addSubview(dismissButton)

    return container
  }()

  override func textViewForEditing() -> UITextView {
    let textView = super.textViewForEditing()
    textView.inputAccessoryView = controlsContainer

    // Read initial values
    currentFontName = annotation?.fontName ?? currentFontName
    currentFontSize = annotation?.fontSize ?? currentFontSize
    currentColor = annotation?.color ?? currentColor
    currentFillColor = annotation?.fillColor ?? currentFillColor
    currentTextAlignment = annotation?.textAlignment ?? currentTextAlignment
    currentAlpha = annotation?.alpha ?? 1.0

    fontNameButton.configuration?.title = currentFontName
    fontSizeButton.setTitle("\(Int(currentUserFontSize))pt", for: .normal)
    fontSizeButton.menu = createFontSizeMenu()
    alignmentButton.setImage(currentTextAlignment.icon, for: .normal)
    alignmentButton.menu = createAlignmentMenu()

    textColorCircle.backgroundColor = currentColor
    bgColorCircle.backgroundColor = currentFillColor
    colorMenuButton.menu = createColorMenu()

    return textView
  }

  private func createFontSizeMenu() -> UIMenu {
    let sizes = stride(from: 2, through: 20, by: 1).map { $0 }
    let actions = sizes.map { size in
      let isSelected = currentUserFontSize == CGFloat(size)
      return UIAction(
        title: "\(size)pt",
        state: isSelected ? .on : .off
      ) { [weak self] _ in
        self?.updateFontSize(to: CGFloat(size * 10))
      }
    }
    return UIMenu(children: actions)
  }

  private func createAlignmentMenu() -> UIMenu {
    let alignments: [(NSTextAlignment, String, String)] = [
      (.left, "Left", "text.alignleft"),
      (.center, "Center", "text.aligncenter"),
      (.right, "Right", "text.alignright"),
    ]

    let actions = alignments.map { alignment, title, imageName in
      UIAction(
        title: title,
        image: UIImage(systemName: imageName),
        state: currentTextAlignment == alignment ? .on : .off
      ) { [weak self] _ in
        self?.updateTextAlignment(to: alignment)
      }
    }

    return UIMenu(children: actions)
  }

  private func createColorMenu() -> UIMenu {
    let textColorAction = UIAction(
      title: "Text Color",
      image: UIImage(systemName: "textformat")
    ) { [weak self] _ in
      self?.pickTextColor()
    }

    let backgroundColorAction = UIAction(
      title: "Background Color",
      image: UIImage(systemName: "square.fill")
    ) { [weak self] _ in
      self?.pickFillColor()
    }

    let removeBackgroundAction = UIAction(
      title: "Remove Background",
      image: UIImage(systemName: "square.slash.fill")
    ) { [weak self] _ in
      self?.removeBackgroundColor()
    }

    let opacityAction = UIAction(
      title: "Opacity",
      image: UIImage(systemName: "eye")
    ) { [weak self] _ in
      self?.showOpacitySlider()
    }

    return UIMenu(children: [textColorAction, backgroundColorAction, removeBackgroundAction, opacityAction])
  }

  private func createFontMenu() -> UIMenu {
    let fonts = ["DM Sans", "Inter", "Montserrat", "Arial", "Calibri"]
    let actions = fonts.map { fontName in
      let isSelected = currentFontName == fontName
      return UIAction(
        title: fontName,
        state: isSelected ? .on : .off
      ) { [weak self] _ in
        self?.updateFont(to: fontName)
      }
    }
    return UIMenu(children: actions)
  }

  private func updateFont(to fontName: String) {
    currentFontName = fontName
    annotation?.fontName = fontName

    let propertyKeyPath = "fontName"
    let userInfo = [PSPDFAnnotationChangedNotificationKeyPathKey: [propertyKeyPath]]
    NotificationCenter.default.post(name: .PSPDFAnnotationChanged, object: annotation, userInfo: userInfo)

    var configuration = fontNameButton.configuration
    configuration?.title = fontName
    fontNameButton.configuration = configuration
    fontNameButton.menu = createFontMenu()
  }

  private func showOpacitySlider() {
    let sheetVC = UIViewController()
    sheetVC.view.backgroundColor = .black

    let slider = UISlider()
    slider.translatesAutoresizingMaskIntoConstraints = false
    slider.minimumValue = 0
    slider.maximumValue = 100
    slider.value = Float(currentAlpha * 100)
    slider.addTarget(self, action: #selector(opacitySliderChanged(_:)), for: .valueChanged)

    let titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = "Opacity"
    titleLabel.textColor = .white
    titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)

    let doneButton = UIButton(type: .system)
    doneButton.translatesAutoresizingMaskIntoConstraints = false
    doneButton.setTitle("Done", for: .normal)
    doneButton.setTitleColor(.systemBlue, for: .normal)
    doneButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
    doneButton.addTarget(self, action: #selector(dismissOpacitySheet), for: .touchUpInside)

    sheetVC.view.addSubview(titleLabel)
    sheetVC.view.addSubview(slider)
    sheetVC.view.addSubview(doneButton)

    NSLayoutConstraint.activate([
      titleLabel.topAnchor.constraint(equalTo: sheetVC.view.topAnchor, constant: 12),
      titleLabel.leadingAnchor.constraint(equalTo: sheetVC.view.leadingAnchor, constant: 16),
      titleLabel.centerYAnchor.constraint(equalTo: doneButton.centerYAnchor),

      doneButton.topAnchor.constraint(equalTo: sheetVC.view.topAnchor, constant: 12),
      doneButton.trailingAnchor.constraint(equalTo: sheetVC.view.trailingAnchor, constant: -16),

      slider.leadingAnchor.constraint(equalTo: sheetVC.view.leadingAnchor, constant: 16),
      slider.trailingAnchor.constraint(equalTo: sheetVC.view.trailingAnchor, constant: -16),
      slider.bottomAnchor.constraint(equalTo: sheetVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
    ])

    if let window = self.window {
      sheetVC.modalPresentationStyle = .pageSheet
      sheetVC.isModalInPresentation = true

      if let sheet = sheetVC.sheetPresentationController {
        sheet.detents = [.custom(identifier: .init("opacity")) { _ in 120 }]
        sheet.preferredCornerRadius = 8
      }

      window.rootViewController?.present(sheetVC, animated: true)
    }
  }

  @objc private func dismissOpacitySheet() {
    if let window = self.window {
      window.rootViewController?.dismiss(animated: true)
    }
  }

  @objc private func opacitySliderChanged(_ slider: UISlider) {
    updateOpacity(to: CGFloat(slider.value) / 100)
  }

  private func updateFontSize(to size: CGFloat) {
    currentFontSize = size
    annotation?.fontSize = size

    let propertyKeyPath = "fontSize"
    let userInfo = [PSPDFAnnotationChangedNotificationKeyPathKey: [propertyKeyPath]]
    NotificationCenter.default.post(name: .PSPDFAnnotationChanged, object: annotation, userInfo: userInfo)

    //    pageView?.annotationView(for: annotation!)?.layoutSubviews()
    //    resizableView?.layoutSubviews()
    //    resizableView?.updateKnobs(animated: false)
    //    resizableView?.updateConstraints()
    //    textView?.layoutSubviews()
    //    textView?.font = textView?.font?.withSize(size)
    fontSizeButton.setTitle("\(Int(currentUserFontSize))pt", for: .normal)
  }

  private func updateTextAlignment(to alignment: NSTextAlignment) {
    currentTextAlignment = alignment
    annotation?.textAlignment = alignment
    textView?.textAlignment = alignment
    alignmentButton.setImage(alignment.icon, for: .normal)
    alignmentButton.menu = createAlignmentMenu()
  }

  private func removeBackgroundColor() {
    updateFillColor(to: .clear)
  }

  private func updateOpacity(to opacity: CGFloat) {
    currentAlpha = opacity
    annotation?.alpha = opacity

    let propertyKeyPath = "alpha"
    let userInfo = [PSPDFAnnotationChangedNotificationKeyPathKey: [propertyKeyPath]]
    NotificationCenter.default.post(
      name: .PSPDFAnnotationChanged, object: annotation, userInfo: userInfo)
  }

  // MARK: - Actions

  @objc private func pickFont() {
    let fontPicker = UIFontPickerViewController()
    fontPicker.delegate = self
    fontPicker.selectedFontDescriptor = UIFontDescriptor(name: currentFontName, size: currentFontSize)
    fontPicker.title = "Select Font"

    if let window = self.window {
      fontPicker.modalPresentationStyle = .pageSheet
      window.rootViewController?.present(fontPicker, animated: true)
    }
  }

  @objc private func pickTextColor() {
    let colorPicker = UIColorPickerViewController()
    colorPicker.delegate = self
    colorPicker.selectedColor = currentColor
    colorPicker.title = "Text Color"
    colorPicker.view.tag = 1
    colorPicker.supportsAlpha = false

    if let window = self.window {
      colorPicker.modalPresentationStyle = .pageSheet
      if let sheet = colorPicker.sheetPresentationController {
        sheet.detents = [.medium(), .large()]
        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = 8
      }

      window.rootViewController?.present(colorPicker, animated: true)
    }
  }

  @objc private func pickFillColor() {
    let colorPicker = UIColorPickerViewController()
    colorPicker.delegate = self

    // set to proper color to avoid bug with alpha
    if currentFillColor == .clear { currentFillColor = .blue }
    colorPicker.selectedColor = currentFillColor
    colorPicker.title = "Background Color"
    colorPicker.view.tag = 2
    colorPicker.supportsAlpha = false

    if let window = self.window {
      colorPicker.modalPresentationStyle = .pageSheet
      if let sheet = colorPicker.sheetPresentationController {
        sheet.detents = [.medium(), .large()]
        sheet.prefersGrabberVisible = true
        sheet.preferredCornerRadius = 8
      }

      window.rootViewController?.present(colorPicker, animated: true)
    }
  }

  @objc private func dismissKeyboard() {
    self.endEditing(true)
  }
}

extension AnnotationTextControls: UIColorPickerViewControllerDelegate {
  func colorPickerViewControllerDidSelectColor(_ viewController: UIColorPickerViewController) {
    let selectedColor = viewController.selectedColor

    // Check if this is for text color (1) or fill color (2)
    if viewController.view.tag == 1 {
      updateTextColor(to: selectedColor)
    } else {
      updateFillColor(to: selectedColor)
    }
  }

  private func updateTextColor(to color: UIColor) {
    currentColor = color
    annotation?.color = color
    textColorCircle.backgroundColor = color

    let propertyKeyPath = "color"
    let userInfo = [PSPDFAnnotationChangedNotificationKeyPathKey: [propertyKeyPath]]
    NotificationCenter.default.post(name: .PSPDFAnnotationChanged, object: annotation, userInfo: userInfo)
  }

  private func updateFillColor(to color: UIColor) {
    currentFillColor = color
    annotation?.fillColor = color
    bgColorCircle.backgroundColor = color

    let propertyKeyPath = "fillColor"
    let userInfo = [PSPDFAnnotationChangedNotificationKeyPathKey: [propertyKeyPath]]
    NotificationCenter.default.post(name: .PSPDFAnnotationChanged, object: annotation, userInfo: userInfo)
  }
}

extension AnnotationTextControls: UIFontPickerViewControllerDelegate {
  func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {
    guard let descriptor = viewController.selectedFontDescriptor else { return }
    let font = UIFont(descriptor: descriptor, size: currentFontSize)
    updateFont(to: font.fontName)

    if let window = self.window {
      window.rootViewController?.dismiss(animated: true)
    }
  }
}

private extension NSTextAlignment {
  var icon: UIImage? {
    let imageName =
      switch self {
      case .left:
        "text.alignleft"
      case .center:
        "text.aligncenter"
      case .right:
        "text.alignright"
      default:
        "text.alignleft"
      }
    return UIImage(systemName: imageName)
  }
}

