//
//  CurrencyExchangeViewModel.swift
//  Currency Exchanger
//
//  Created by sandro shanshiashvili on 7/5/22.
//

import Foundation

class CurrencyExchangeViewModel {
  
  //create dispachQueue to prevent unnessessary request calls
  private let myQueue = DispatchQueue(label: "myQueue")
  private var workItem: DispatchWorkItem!
  //Delay is in milliseconds
  private let delay = 400
  
  //MARK: Currency Enum
  enum Currencies: String, CaseIterable {
    case EUR = "EUR",
         USD = "USD",
         JPY = "JPY"
  }
  
  enum CurrencyError: Error {
    case NotEnoughAmountOnAccount
  }
  
  //MARK: Properties
  private let commissionFee = 0.007
  
  
  //MARK: Services
  private let currencyConverterService = CurrencyConverterService()
  
  var accounts = ["EUR": 1000.0, "USD": 0.0, "JPY": 0.0]
  
  func convertCurrency(fromCurrency: String, toCurrency: String, sellAmount: Double, completionHandler: @escaping (CurrencyModel) -> Void) {
    stopCurrentRequest()
    workItem = DispatchWorkItem {
      self.currencyConverterService.convertCurrency(amount: sellAmount, fromCurrency: fromCurrency, toCurrency: toCurrency) { response in
        switch response {
        case .success(let model):
          completionHandler(model)
        case .failure(let error):
          print(error)
        }
      }
    }
    myQueue.asyncAfter(deadline: .now() + .milliseconds(delay), execute: workItem)
  }
  
  func stopCurrentRequest() {
    if workItem != nil {
      workItem.cancel()
      workItem = nil
      
    }
  }
  
  func submitButtonPressed(fromCurrency: String, toCurrency: String, sellAmount: Double, completionHanlder: @escaping (Result<CurrencyModel, CurrencyError>) -> Void) {
    convertCurrency(fromCurrency: fromCurrency, toCurrency: toCurrency, sellAmount: sellAmount) {[weak self] model in
      guard let self = self else { return }
      if let _ = self.accounts[fromCurrency],
         let _ = self.accounts[toCurrency],
         let amount = Double(model.amount) {
        if self.accounts[fromCurrency]! > sellAmount {
          self.accounts[fromCurrency]! -= (sellAmount + self.chargeFee(amount: sellAmount))
          self.accounts[model.currency]! += amount
          completionHanlder(.success(model))
        } else {
          completionHanlder(.failure(.NotEnoughAmountOnAccount))
        }
      }
    }
  }
  
  private func chargeFee(amount: Double) -> Double {
    var fee = 0.0
    var freeTrial = UserDefaults.standard.double(forKey: "freeTrial")
    if freeTrial > 5 {
      fee = amount * commissionFee
    } else {
      fee = 0.0
      freeTrial += 1
      UserDefaults.standard.set(freeTrial, forKey: "freeTrial")
    }
    return fee
  }
}
