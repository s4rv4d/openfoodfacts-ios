//
//  ProductAddViewController.swift
//  OpenFoodFacts
//
//  Created by Andrés Pizá Bückmann on 19/07/2017.
//  Copyright © 2017 Andrés Pizá Bückmann. All rights reserved.
//

import UIKit
import NotificationBanner

class ProductAddViewController: TakePictureViewController {
    // IBOutlets

    @IBOutlet weak var barcodeTitleLabel: UILabel!
    @IBOutlet weak var barcodeLabel: UILabel!
    @IBOutlet weak var topExplainationText: UILabel!
    @IBOutlet weak var licenseExplainationLabel: UILabel!

    @IBOutlet weak var scrollView: UIScrollView!

    @IBOutlet weak var productSectionTitle: UILabel!
    @IBOutlet weak var productNameTitleLabel: UILabel!
    @IBOutlet weak var productNameField: UITextField!
    @IBOutlet weak var productCategoryTitleLabel: UILabel!
    @IBOutlet weak var productCategoryField: UITextField!
    @IBOutlet weak var brandsTitleLabel: UILabel!
    @IBOutlet weak var brandsField: UITextField!
    @IBOutlet weak var quantityTitleLabel: UILabel!
    @IBOutlet weak var quantityExampleLabel: UILabel!
    @IBOutlet weak var quantityField: UITextField!
    @IBOutlet weak var languageTitleLabel: UILabel!
    @IBOutlet weak var languageField: UITextField!
    @IBOutlet weak var productTextSection: UIView!
    @IBOutlet weak var saveProductInfosButton: UIButton!
    @IBOutlet var productInformationsTextFields: [UITextField]!
    @IBOutlet weak var lastSavedProductInfosLabel: UILabel!

    @IBOutlet weak var noNutritionDataSwitch: UISwitch!
    @IBOutlet weak var nutritiveSectionTitle: UILabel!
    @IBOutlet weak var nutriscoreStackView: UIStackView!
    @IBOutlet weak var nutriScoreView: NutriScoreView!
    @IBOutlet weak var portionSizeInputView: EditNutritiveValueView!
    @IBOutlet weak var nutritivePortionSegmentedControl: UISegmentedControl!
    @IBOutlet weak var nutritiveValuesStackView: UIStackView!
    @IBOutlet weak var addNutrimentButton: UIButton!
    @IBOutlet weak var saveNutrimentsButton: UIButton!
    @IBOutlet weak var lastSavedNutrimentsLabel: UILabel!

    @IBOutlet weak var ingredientsSectionTitle: UILabel!
    @IBOutlet weak var novaGroupStackView: UIStackView!
    @IBOutlet weak var novaGroupView: NovaGroupView!
    @IBOutlet weak var ingredientsExplainationLabel: UILabel!
    @IBOutlet weak var ingredientsTextField: UITextView!
    @IBOutlet weak var ignoreIngredientsButton: UIButton!
    @IBOutlet weak var saveIngredientsButton: UIButton!
    @IBOutlet weak var lastSavedIngredientsLabel: UILabel!

    @IBOutlet var saveButtons: [UIButton]!

    // Constants

    // ivars

    lazy var product = Product()
    lazy var productPostErrorAlert: UIAlertController = {
        let alert = UIAlertController(title: "product-add.save-error.title".localized,
                                      message: "product-add.save-error.message".localized,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "alert.action.ok".localized,
                                      style: .default,
                                      handler: { _ in alert.dismiss(animated: true, completion: nil) }))
        return alert
    }()

    // Mandatory ivars

    override var barcode: String! {
        didSet {
            product.barcode = barcode
        }
    }

    // Private vars

    fileprivate var activeField: UIView?
    fileprivate var lastOffset: CGPoint = CGPoint(x: 0, y: 0)

    private var languagePickerController: PickerViewController?
    private var languagePickerToolbarController: PickerToolbarViewController?
    private var languageValue: String = "en" // Use English as default

    private var productCategory: Category?
    private var productCategoryCustomName: String?

    static let displayedNutrimentItemsByDefault = [
        "energy",
        "fat",
        "saturated-fat",
        "carbohydrates",
        "sugars",
        "fiber",
        "proteins",
        "salt",
        "sodium",
        "alcohol"
    ]
    fileprivate var displayedNutrimentItems = displayedNutrimentItemsByDefault

    override func viewDidLoad() {
        self.title = "product-add.title".localized

        barcodeTitleLabel.text = "product-add.titles.barcode".localized
        topExplainationText.text = "product-add.titles.top-explainations".localized
        licenseExplainationLabel.text = "product-add.titles.license-explaination".localized

        productSectionTitle.text = "product-add.titles.product-info".localized
        productNameTitleLabel.text = "product-add.label.product-name".localized
        productCategoryTitleLabel.text = "product-add.label.category".localized
        productCategoryField.placeholder = "product-add.label.category".localized
        brandsTitleLabel.text = "product-add.placeholder.brand".localized
        quantityTitleLabel.text = "product-add.label.quantity".localized
        quantityExampleLabel.text = "product-add.label.quantity-example".localized
        languageTitleLabel.text = "product-add.label.language".localized
        saveButtons.forEach { (button: UIButton) in
            button.setTitle("generic.save".localized, for: .normal)
        }
        lastSavedProductInfosLabel.isHidden = true

        nutritiveSectionTitle.text = "product-add.titles.nutritive".localized
        nutriscoreStackView.isHidden = true
        nutritivePortionSegmentedControl.setTitle("product-add.nutritive.choice.per-hundred-grams".localized, forSegmentAt: 0)
        nutritivePortionSegmentedControl.setTitle("product-add.nutritive.choice.per-portion".localized, forSegmentAt: 1)
        portionSizeInputView.titleLabel.text = "product-detail.nutrition.serving-size".localized
        portionSizeInputView.inputTextField.placeholder = "product-detail.nutrition.serving-size".localized
        addNutrimentButton.setTitle("product-add.nutritive.add-nutriment".localized + " >", for: .normal)
        lastSavedNutrimentsLabel.isHidden = true

        refreshNutritiveInputsViews()

        ingredientsSectionTitle.text = "product-add.titles.ingredients".localized
        ingredientsExplainationLabel.text = "product-add.ingredients.explaination".localized
        novaGroupStackView.isHidden = true
        ingredientsTextField.text = ""
        ignoreIngredientsButton.setTitle("product-add.ingredients.button-delete".localized, for: .normal)
        saveIngredientsButton.setTitle("product-add.ingredients.button-save".localized, for: .normal)
        lastSavedIngredientsLabel.isHidden = true

        configureLanguageField()
        configureDelegates()
        configureNotifications()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        barcodeLabel.text = barcode

        if let barcode = self.barcode, let pendingUploadItem = dataManager.getItemPendingUpload(forBarcode: barcode) {
            fillForm(withPendingUploadItem: pendingUploadItem)
        }
    }

    @IBAction func didTapSaveProductButton(_ sender: UIButton) {
        self.view.endEditing(true)
        saveProductInfosButton.isEnabled = false
        self.showSavingIndication(label: lastSavedProductInfosLabel, key: "save-info")

        // Set field values in product
        product.name = productNameField.text
        product.lang = languageValue

        if let brand = brandsField.text {
            product.brands = [brand]
        }

        if let category = productCategory {
            product.categories = [category.code]
        } else if let category = productCategoryCustomName {
            product.categories = [(Bundle.main.preferredLocalizations.first ?? "en") + ":" + category]
        } else {
            product.categories = nil
        }

        product.quantity = quantityField.text

        dataManager.addProduct(product, onSuccess: { [weak self] in
            self?.showSavedSuccess(label: self?.lastSavedProductInfosLabel, key: "save-info")
            self?.saveProductInfosButton.isEnabled = true
        }, onError: { [weak self] _ in
            self?.showSavedError(label: self?.lastSavedProductInfosLabel, key: "save-info")
            self?.saveProductInfosButton.isEnabled = true
        })
    }

    @IBAction func didTapSaveNutrimentsButton(_ sender: Any) {
        self.view.endEditing(true)
        self.saveNutrimentsButton.isEnabled = false
        self.showSavingIndication(label: lastSavedNutrimentsLabel, key: "save-nutriments")

        if let servingSize = portionSizeInputView.inputTextField.text {
            product.servingSize = servingSize
        }

        var nutriments = [String: Any]()

        product.noNutritionData = noNutritionDataSwitch.isOn ? "on" : "off"

        if !noNutritionDataSwitch.isOn {
            if nutritivePortionSegmentedControl.selectedSegmentIndex == 0 {
                product.nutritionDataPer = .hundredGrams
            } else {
                product.nutritionDataPer = .serving
            }

            nutritiveValuesStackView.arrangedSubviews.forEach { (view: UIView) in
                if let view = view as? EditNutritiveValueView {
                    if let value = view.inputTextField.text, let doubleValue = Double(value) {
                        nutriments[view.nutrimentCode] = doubleValue
                        nutriments[view.nutrimentCode + "_unit"] = view.selectedUnit
                    }
                }
            }
        }

        dataManager.addProductNutritionTable(product, nutritionTable: nutriments, onSuccess: { [weak self] in
            self?.showSavedSuccess(label: self?.lastSavedNutrimentsLabel, key: "save-nutriments")
            self?.saveNutrimentsButton.isEnabled = true

            self?.refreshNovaScore()

            }, onError: { [weak self] _ in
                self?.showSavedError(label: self?.lastSavedNutrimentsLabel, key: "save-nutriments")
                self?.saveNutrimentsButton.isEnabled = true
        })
    }

    fileprivate func refreshNovaScore() {
        guard let barcode = product.barcode else { return }
        dataManager.getProduct(byBarcode: barcode, isScanning: false, isSummary: true, onSuccess: { [weak self] (distantProduct: Product?) in
            if let distantProduct = distantProduct {
                UIView.animate(withDuration: 0.2, animations: {
                    if let nutriscoreString = distantProduct.nutriscore, let score = NutriScoreView.Score(rawValue: nutriscoreString) {
                        self?.nutriScoreView.currentScore = score
                        self?.nutriscoreStackView.isHidden = false
                    } else {
                        self?.nutriscoreStackView.isHidden = true
                    }

                    if let novaGroupString = distantProduct.novaGroup, let novaGroup = NovaGroupView.NovaGroup(rawValue: novaGroupString) {
                        self?.novaGroupView.novaGroup = novaGroup
                        self?.novaGroupStackView.isHidden = false
                    } else {
                        self?.novaGroupStackView.isHidden = true
                    }
                })
            }
        }) { (_) in }
    }

    @IBAction func didTapIgnoreIngredientsButton(_ sender: Any) {
        self.ingredientsTextField.text = nil
        self.lastSavedIngredientsLabel.isHidden = true
    }

    @IBAction func didTapSaveIngredientsButton(_ sender: Any) {
        self.view.endEditing(true)
        self.ignoreIngredientsButton.isEnabled = false
        self.saveIngredientsButton.isEnabled = false
        self.showSavingIndication(label: lastSavedIngredientsLabel, key: "save-ingredients")

        self.product.ingredientsList = self.ingredientsTextField.text

        dataManager.addProduct(product, onSuccess: { [weak self] in
            self?.showSavedSuccess(label: self?.lastSavedIngredientsLabel, key: "save-ingredients")
            self?.ignoreIngredientsButton.isEnabled = true
            self?.saveIngredientsButton.isEnabled = true
            self?.refreshNovaScore()
            }, onError: { [weak self] _ in
                self?.showSavedError(label: self?.lastSavedIngredientsLabel, key: "save-ingredients")
                self?.ignoreIngredientsButton.isEnabled = true
                self?.saveIngredientsButton.isEnabled = true
        })
    }

    @IBAction func addNutrimentButtonTapped(_ sender: Any) {
        //open select nutriment
        let selectNutrimentViewController = SelectNutrimentViewController(nibName: "SelectNutrimentViewController", bundle: nil)
        selectNutrimentViewController.dataManager = self.dataManager
        selectNutrimentViewController.delegate = self
        self.navigationController?.pushViewController(selectNutrimentViewController, animated: true)
    }

    @IBAction func noNutritionDataSwitchToggled(_ sender: Any) {
        let isHidden = noNutritionDataSwitch.isOn
        UIView.animate(withDuration: 0.2) {
            self.nutritivePortionSegmentedControl.isHidden = isHidden
            self.nutritiveValuesStackView.isHidden = isHidden
            self.addNutrimentButton.isHidden = isHidden
        }
        showNotSavedIndication(label: lastSavedNutrimentsLabel, key: "save-nutriments")
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "TakePictureSegue" {
            guard let destination = segue.destination as? PictureTableViewController else { return; }
            destination.delegate = self
            destination.barcode = barcode
            destination.dataManager = dataManager
        }
    }

    fileprivate func refreshNutritiveInputsViews() {
        while nutritiveValuesStackView.arrangedSubviews.count < displayedNutrimentItems.count {
            let newView = EditNutritiveValueView(frame: CGRect())
            newView.inputTextField.delegate = self
            newView.inputTextField.keyboardType = .decimalPad
            nutritiveValuesStackView.addArrangedSubview(newView)
        }
        while nutritiveValuesStackView.arrangedSubviews.count > displayedNutrimentItems.count, let last = nutritiveValuesStackView.arrangedSubviews.last {
            nutritiveValuesStackView.removeArrangedSubview(last)
            last.removeFromSuperview()
        }

        displayedNutrimentItems.enumerated().forEach { (index: Int, element: String) in
            if let view = nutritiveValuesStackView.arrangedSubviews[index] as? EditNutritiveValueView {
                let nutriment = dataManager.nutriment(forTag: element)
                let nutrimentName = nutriment?.names.chooseForCurrentLanguage()?.value ?? element

                view.nutrimentCode = element
                view.titleLabel.text = nutrimentName
                view.inputTextField.placeholder = nutrimentName

                switch element {
                case "energy": view.displayedUnit = .energy
                case "alcohol": view.displayedUnit = .alcohol
                case "ph": view.displayedUnit = .none
                case let element where ProductAddViewController.displayedNutrimentItemsByDefault.contains(element):
                    view.displayedUnit = .units
                default: view.displayedUnit = .allUnits
                }
            }
        }
    }

    private func configureLanguageField() {
        let languages = dataManager.getLanguages()

        let defaultValue: Int? = languages.index(where: { $0.code == self.languageValue })

        self.languagePickerController = PickerViewController(data: languages, defaultValue: defaultValue, delegate: self)
        self.languagePickerToolbarController = PickerToolbarViewController(title: "product-add.language.toolbar-title".localized, delegate: self)

        if let pickerView = languagePickerController?.view as? UIPickerView {
            self.languageField.inputView = pickerView
        }

        if let toolbarView = languagePickerToolbarController?.view as? UIToolbar {
            self.languageField.inputAccessoryView = toolbarView
        }

        // Set current language as default
        if let languageCode = Locale.current.languageCode {
            self.languageValue = languageCode
        }

        self.languageField.text = Locale.current.localizedString(forIdentifier: self.languageValue)

        // Hide blinking cursor
        self.languageField.tintColor = .clear
    }

    private func configureDelegates() {
        productNameField.delegate = self
        brandsField.delegate = self
        productCategoryField.delegate = self
        quantityField.delegate = self
        languageField.delegate = self

        portionSizeInputView.displayedUnit = .none
        portionSizeInputView.inputTextField.delegate = self
        ingredientsTextField.delegate = self
    }

    private func configureNotifications() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name: Notification.Name.UIKeyboardWillShow, object: nil)
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name: Notification.Name.UIKeyboardWillHide, object: nil)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissKeyboard (_:)))
        self.view.addGestureRecognizer(tapGesture)
    }

    fileprivate func showNotSavedIndication(label: UILabel?, key: String) {
        label?.text = "⚠️ " + "product-add.\(key).not-yet".localized
        label?.isHidden = false
    }

    fileprivate func showSavingIndication(label: UILabel?, key: String) {
        label?.text = "📡 " + "product-add.\(key).saving".localized
        label?.isHidden = false
    }

    fileprivate func showSavedSuccess(label: UILabel?, key: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short

        label?.text = "💾 " + "product-add.\(key).success".localized + " " + dateFormatter.string(from: Date())
        label?.isHidden = false
    }

    fileprivate func showSavedError(label: UILabel?, key: String) {
        label?.text =  "🚨 " + "product-add.\(key).error".localized
        label?.isHidden = false
    }

    private func fillForm(withPendingUploadItem pendingUploadItem: PendingUploadItem) {
        if let productName = pendingUploadItem.productName {
            productNameField.text = productName
        }

        if let brand = pendingUploadItem.brand {
            brandsField.text = brand
        }

        if let quantityValue = pendingUploadItem.quantityValue {
            quantityField.text = quantityValue
        }

        // Set language
        didGetSelection(value: Language(code: pendingUploadItem.language, name: Locale.current.localizedString(forIdentifier: pendingUploadItem.language) ?? pendingUploadItem.language))
        showNotSavedIndication(label: lastSavedProductInfosLabel, key: "save-info")
    }
}

// MARK: - Keyboard notification handler
extension ProductAddViewController {
    @objc func keyboardWillShow(notification: Notification) {
        let userInfo = notification.userInfo
        // swiftlint:disable:next force_cast
        let keyboardFrame = userInfo?[UIKeyboardFrameEndUserInfoKey] as! CGRect
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset

        // move if keyboard hide input field
        let distanceToBottom = self.scrollView.frame.size.height - (activeField?.frame.origin.y ?? 0) - (activeField?.frame.size.height ?? 0)
        let collapseSpace = keyboardFrame.height - distanceToBottom
        if collapseSpace < 0 {
            // no collapse
            return
        }
        // set new offset for scroll view
        UIView.animate(withDuration: 0.3, animations: {
            // scroll to the position above keyboard 10 points
            self.scrollView.contentOffset = CGPoint(x: self.lastOffset.x, y: collapseSpace + 10)
        })
    }

    @objc func keyboardWillHide(notification: Notification) {
        let contentInset = UIEdgeInsets.zero
        scrollView.contentInset = contentInset
        scrollView.scrollIndicatorInsets = contentInset
    }

    @objc func dismissKeyboard (_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
}

extension ProductAddViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == productCategoryField {
            //open select category
            let selectCategoryViewController = SelectCategoryViewController(nibName: "SelectCategoryViewController", bundle: nil)
            selectCategoryViewController.dataManager = self.dataManager
            selectCategoryViewController.delegate = self
            self.navigationController?.pushViewController(selectCategoryViewController, animated: true)
            return false
        }
        activeField = textField
        lastOffset = self.scrollView.contentOffset
        return true
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if productInformationsTextFields.contains(textField) {
            showNotSavedIndication(label: lastSavedProductInfosLabel, key: "save-info")
        }
        if textField.isDescendant(of: nutritiveValuesStackView) {
            showNotSavedIndication(label: lastSavedNutrimentsLabel, key: "save-nutriments")
        }
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
}

extension ProductAddViewController: UITextViewDelegate {
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        activeField = textView
        lastOffset = self.scrollView.contentOffset
        return true
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        showNotSavedIndication(label: lastSavedIngredientsLabel, key: "save-ingredients")
        return true
    }
}

extension ProductAddViewController: PictureTableViewControllerDelegate {
    func didPostIngredientImage() {
        dataManager.getIngredientsOCR(forBarcode: barcode, productLanguageCode: self.languageValue) { [weak self] (ingredients: String?, _: Error?) in
            if let ingredients = ingredients {
                self?.ingredientsTextField.text = ingredients
                self?.showNotSavedIndication(label: self?.lastSavedIngredientsLabel, key: "save-ingredients")
            }
        }
    }
}

extension ProductAddViewController: SelectCategoryDelegate {
    func didSelect(category: Category) {
        productCategoryField.text = category.names.chooseForCurrentLanguage(defaultToFirst: true)?.value ?? category.code
        self.productCategory = category
        self.productCategoryCustomName = nil
        self.navigationController?.popToViewController(self, animated: true)
        showNotSavedIndication(label: lastSavedProductInfosLabel, key: "save-info")
    }

    func didSelect(customCategory: String) {
        productCategoryField.text = customCategory
        self.productCategory = nil
        self.productCategoryCustomName = customCategory
        self.navigationController?.popToViewController(self, animated: true)
        showNotSavedIndication(label: lastSavedProductInfosLabel, key: "save-info")
    }
}

extension ProductAddViewController: SelectNutrimentDelegate {
    func didSelect(nutriment: Nutriment) {
        if !displayedNutrimentItems.contains(nutriment.code) {
            displayedNutrimentItems.append(nutriment.code)
            refreshNutritiveInputsViews()
        }
        self.navigationController?.popToViewController(self, animated: true)
        showNotSavedIndication(label: lastSavedNutrimentsLabel, key: "save-nutriments")
    }
}

extension ProductAddViewController: PickerViewDelegate {
    func didGetSelection(value: Pickable) {
        switch value {
        case let language as Language:
            self.languageValue = language.code
            self.languageField.text = language.name
        default:
            // Do nothing
            return
        }
    }

    func didDismiss() {
        self.view.endEditing(true)
    }
}
