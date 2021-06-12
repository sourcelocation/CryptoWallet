//
//  CryptocompareAPI.swift
//  CryptoWalletTest
//
//  Created by Матвей Анисович on 6/11/21.
//

import Foundation

class CoinCap {
    func coins(ids: [String], completion: @escaping ([Coin]) -> Void) {
        let url = "https://api.coincap.io/v2/assets?limit=100&offset=0&ids=\(ids.joined(separator: ","))"
        dictionary(from: url) { dict in
            guard let dict = dict else { return }
            let coinsArray = dict["data"] as! [[String:Any]]
            var coins:[Coin] = []
            for coinDict in coinsArray {
                let newCoin = Coin(id: coinDict["id"] as? String, symbol: (coinDict["symbol"] as? String)?.lowercased(), name: coinDict["name"] as? String,price: Double(coinDict["priceUsd"] as? String ?? "0"), marketCap: Double(coinDict["marketCapUsd"] as? String ?? "0"), marketCapRank: Double(coinDict["rank"] as! String), totalVolume: Double(coinDict["volumeUsd24Hr"] as? String ?? "0"), priceChangePercentage24h: Double(coinDict["changePercent24Hr"] as? String ?? "0"))
                coins.append(newCoin)
            }
            completion(coins)
        }
    }
    
    func history(for coin: Coin, days: Double, pricePointsCompletion: @escaping ([PricePoint]) -> Void) {
        var interval = ""
        
        if days > 182 {
            interval = "d1"
        } else if days >= 100 {
            interval = "h12"
        } else if days >= 50 {
            interval = "h6"
        } else if days >= 25 {
            interval = "h2"
        } else if days >= 10 {
            interval = "h1"
        } else if days >= 5 {
            interval = "m30"
        } else if days >= 1 {
            interval = "m15"
        } else if days >= 0.5 {
            interval = "m5"
        } else if days >= 0.1 {
            interval = "m1"
        }
        guard let coinId = coin.id else { pricePointsCompletion([]); return }
        dictionary(from: "https://api.coincap.io/v2/assets/\(coinId)/history?interval=\(interval)&start=\(Int(Date().addingTimeInterval(TimeInterval(Int(days * 24 * 60 * 60 * -1))).timeIntervalSince1970) * 1000)&end=\(Int(Date().timeIntervalSince1970) * 1000)") { dict in
            guard let dict = dict else { pricePointsCompletion([]); return }
            var pricePoints:[PricePoint] = []
            let points = dict["data"] as! [[String:Any]]
            for point in points {
                let price = Double(point["priceUsd"] as? String ?? "0") ?? 0
                let time = Double(point["time"] as? Int ?? 0)
                pricePoints.append(PricePoint(price: price, unixTimestamp: time))
            }
            pricePointsCompletion(pricePoints)
        }
    }
    
    struct Coin {
        var id: String?
        var symbol: String?
        var name: String?
        var imageURL: String?
        
        var price: Double?
        
        var marketCap: Double?
        var marketCapRank: Double?
        var totalVolume: Double?
        
        var high24h: Double?
        var low24h: Double?
        
        var priceChange24h: Double?
        var priceChangePercentage24h: Double?
    }
    struct PricePoint {
        var price: Double
        var unixTimestamp: TimeInterval
        
        var date: Date {
            get {
                return Date(timeIntervalSince1970: unixTimestamp / 1000)
            } set {
                unixTimestamp = newValue.timeIntervalSince1970
            }
        }
    }
    
    private func dictionary(from url: String, completion: @escaping ([String: Any]?) -> Void) {
        text(from: url, completion: { response in
            completion(self.convertToDictionary(response))
        })
    }
    private func array(from url: String, completion: @escaping ([Any]?) -> Void) {
        text(from: url, completion: { response in
            completion(self.convertToArray(response))
        })
    }
    private func text(from url: String, completion: @escaping (String) -> Void) {
        guard let url = URL(string: url) else { return }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else { completion(""); return }
            guard let string = String(data: data, encoding: .utf8) else { completion(""); return }
            completion(string)
        }.resume()
    }

    private func convertToDictionary(_ text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
    private func convertToArray(_ text: String) -> [Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
func stringPrice(_ price: Double) -> String {
    if price < 0.1 {
        return "$\(price.rounded(toPlaces: 5).clean)"
    } else if price < 1 {
        return "$\(price.rounded(toPlaces: 4).clean)"
    } else if price < 5 {
        return "$\(price.rounded(toPlaces: 3).clean)"
    } else if price < 150 {
        return "$\(price.rounded(toPlaces: 2).clean)"
    } else if price < 1000 {
        return "$\(price.rounded(toPlaces: 1).clean)"
    } else {
        return "$\(price.rounded().clean)"
    }
}
