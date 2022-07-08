//
//  CurrencyExchangeViewController.swift
//  Currency Exchanger
//
//  Created by sandro shanshiashvili on 7/5/22.
//

import UIKit

class CurrencyExchangeViewController: UIViewController {
  

  //MARK: IBOutlets
  @IBOutlet var collectionView: UICollectionView!
  @IBOutlet var sellTextField: UITextField!
  @IBOutlet var receiveTextField: UITextField!
  @IBOutlet var sellCurrencyButton: UIButton!
  @IBOutlet var receiveCurrencyButton: UIButton!
  @IBOutlet var submitButton: UIButton!
  
  //MARK: Properties
  var viewModel: CurrencyExchangeViewModel!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    changeNavigationItemtitleColor()
    viewModel = CurrencyExchangeViewModel()
    collectionView.dataSource = self
    sellTextField.becomeFirstResponder()
    setupTextField(with: sellTextField)
    setupTextField(with: receiveTextField)
    setupSubmitButton()
    setupSellCurrencyButton()
    setupReceiveCurrencyButton()
}
  

  @IBAction func submitButtonPressed(_ sender: UIButton) {
    guard let amount = Double(sellTextField.text!) else { return }
    viewModel.submitButtonPressed(fromCurrency: sellCurrencyButton.titleLabel!.text!,
                                  toCurrency: receiveCurrencyButton.titleLabel!.text!,
                                  sellAmount: amount)
    { [weak self] result in
      guard let self = self else { return }
      var commissionFeeText = ""
      switch result {
      case .success(_):
        DispatchQueue.main.async {
          if !self.isUserFreeTrial() {
            commissionFeeText = "Commission Fee - \(amount * 0.007) \(self.sellCurrencyButton.titleLabel!.text!)"
          }
          self.collectionView.reloadData()
          self.createAlert(withTitle: "Currency Converted", withText: "You Have Converted \(self.sellTextField.text!) \(self.sellCurrencyButton.titleLabel!.text!) to \(self.receiveTextField.text!) \(self.receiveCurrencyButton.titleLabel!.text!). \(commissionFeeText)")
          self.clearTextViews()
        }
      case .failure(_):
        DispatchQueue.main.async {
          self.createAlert(withTitle: "Error", withText: "Not enough amount on account")
        }
      }
    }
    
  }
  
  @IBAction func textFieldValueChanged(_ sender: UITextField) {
    if isTextFieldStartedWithZero(text: sender.text!) {
      sellTextField.text = ""
      return
      
    }
    guard let amount = Double(sender.text!) else {
      viewModel.stopCurrentRequest()
      receiveTextField.text = ""
      return
    }
    viewModel.convertCurrency(fromCurrency: sellCurrencyButton.titleLabel?.text! ?? "",
                              toCurrency: receiveCurrencyButton.titleLabel?.text! ?? "",
                              sellAmount: amount) { [weak self] currencyModel in
      guard let self = self else { return }
      DispatchQueue.main.sync {
        self.receiveTextField.text = String(currencyModel.amount)
      }
    }
  }
  
  private func changeNavigationItemtitleColor() {
    let textAttributes = [NSAttributedString.Key.foregroundColor:UIColor.white]
    navigationController?.navigationBar.titleTextAttributes = textAttributes
  }
  
  
  //MARK: Setup Views
  private func setupTextField(with textfield: UITextField) {
    textfield.keyboardType = .numberPad
    textfield.textAlignment = .right
  }
  
  private func setupSubmitButton() {
    submitButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 50).isActive = true
    submitButton.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -50).isActive = true
    submitButton.layer.cornerRadius = submitButton.frame.size.height / 2
    submitButton.clipsToBounds = true
  }
  
  private func uiSellMenuItemFactory() -> [UIAction] {
    var menuItems: [UIAction] = []
    for currency in CurrencyExchangeViewModel.Currencies.allCases {
      let action = UIAction(title: currency.rawValue, handler: { [weak self] action in
        guard let self = self else { return }
        self.sellCurrencyButton.setTitle(action.title, for: .normal)
        self.clearTextViews()
      })
      menuItems.append(action)
    }
    return menuItems
  }
  
  private func uiReceiveMenuItemFactory() -> [UIAction] {
    var menuItems: [UIAction] = []
    for currency in CurrencyExchangeViewModel.Currencies.allCases {
      let action = UIAction(title: currency.rawValue, handler: { [weak self] action in
        guard let self = self else { return }
        self.receiveCurrencyButton.setTitle(action.title, for: .normal)
        self.clearTextViews()
      })
      menuItems.append(action)
    }
    return menuItems
  }
  
  private func setupSellCurrencyButton() {
    let menuItems = uiSellMenuItemFactory()

    var menu: UIMenu {
        return UIMenu(title: "Choose Selling Currency", options: [], children: menuItems)
    }
    sellCurrencyButton.menu = menu
  }
  
  private func setupReceiveCurrencyButton() {
    let menuItems = uiReceiveMenuItemFactory()
    
    var menu: UIMenu {
      return UIMenu(title: "Choose Receiving Currency", options: [], children: menuItems)
    }
    receiveCurrencyButton.menu = menu
  }
  
  private func clearTextViews() {
    sellTextField.text = ""
    receiveTextField.text = ""
  }
  
  private func isTextFieldStartedWithZero(text: String) -> Bool {
    text == "0" ? true : false
  }
  
  private func createAlert(withTitle title: String, withText text: String) {
    let dialogMessage = UIAlertController(title: title, message: text, preferredStyle: .alert)
    let doneAction = UIAlertAction(title: "Done", style: .default)
    dialogMessage.addAction(doneAction)
    self.present(dialogMessage, animated: true, completion: nil)
  }
  
  private func isUserFreeTrial() -> Bool {
    let transactionCount = UserDefaults.standard.double(forKey: "freeTrial")
    return transactionCount < 5 ? true : false
  }
}


//MARK: CollectionView Data Source

extension CurrencyExchangeViewController: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    CurrencyExchangeViewModel.Currencies.allCases.count
  }
  
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CurrencyCell.identifier, for: indexPath) as? CurrencyCell else { fatalError(CurrencyCell.currencyCreationError) }
    if let value = viewModel.accounts[CurrencyExchangeViewModel.Currencies.allCases[indexPath.row].rawValue] {
      cell.currencyLabel.text = "\(value) \(CurrencyExchangeViewModel.Currencies.allCases[indexPath.row])"
    }
    return cell
  }
}
