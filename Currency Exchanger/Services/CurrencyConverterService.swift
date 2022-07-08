//
//  CurrencyConverterService.swift
//  Currency Exchanger
//
//  Created by sandro shanshiashvili on 7/6/22.
//

import Foundation


class CurrencyConverterService {
  private let baseURL = "http://api.evp.lt/currency/commercial/exchange/"
  private let decoder = JSONDecoder()
  private let session = URLSession.shared
  
 
  
  func convertCurrency(amount: Double, fromCurrency: String, toCurrency: String,  completionHandler: @escaping (Result<CurrencyModel,Error>) -> Void) {
    guard let url = URL(string: "\(baseURL)\(amount)-\(fromCurrency)/\(toCurrency)/latest") else { return }
    session.dataTask(with: url) { data, response, error in
      if let error = error {
        completionHandler(.failure(error))
      }
      if let data = data, let model = self.serializeJson(data: data){
        completionHandler(.success(model))
      }
    }.resume()
  }
  
  private func serializeJson(data: Data) -> CurrencyModel? {
    let data = try? decoder.decode(CurrencyModel.self, from: data)
    return data
  }
}
