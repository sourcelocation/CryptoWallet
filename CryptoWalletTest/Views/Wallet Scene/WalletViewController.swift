//
//  WalletViewController.swift
//  CryptoWalletTest
//
//  Created by Матвей Анисович on 6/11/21.
//

import UIKit
import Hero

class WalletViewController: UIViewController {
    var coinIds: [String] = ["bitcoin", "ethereum", "litecoin", "nano"]
    var coins: [CoinCap.Coin] = []
    let coinCap = CoinCap()
    
    var totalHoldingsInUsd = 0.0
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var changes24h: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        showIndicator(withTitle: "", and: "")
        coinCap.coins(ids: coinIds) { coins in
            self.coins = coins
            DispatchQueue.main.async {
                self.hideIndicator()
                self.tableView.insertSections(IndexSet(integersIn: 0...coins.count-1), with: .middle)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destination = segue.destination as? DetailsViewController else { return }
        destination.walletVC = self
        destination.selectedCoinIndex = (sender as! IndexPath).section
    }
}

extension WalletViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return coins.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! CoinTableViewCell
        let rowCoin = coins[indexPath.section]
        
        // Random values
        var holdingAmount = 0.0
        if indexPath.section == 0 {
            holdingAmount = .random(in: 0.1...1).rounded(toPlaces: 4)
        } else if indexPath.section == 1 {
            holdingAmount = .random(in: 1...3).rounded(toPlaces: 1)
        } else if indexPath.section == 2 {
            holdingAmount = .random(in: 10...100).rounded()
        } else if indexPath.section == 3 {
            holdingAmount = .random(in: 1...2000).rounded()
        }
        let coinHoldings = holdingAmount * (rowCoin.price ?? 0)
        totalHoldingsInUsd += coinHoldings
        cell.holdingsUsdLabel.text = "\(doublePrice(coinHoldings))"
        balanceLabel.text = doublePrice(totalHoldingsInUsd.rounded(toPlaces: 2), noDollarSign: true)
        
        let profit = Double.random(in: -2...2).rounded(toPlaces: 2)
        if profit > 0 {
            cell.profitLabel.text = "+ \(profit.clean)%"
            cell.profitLabel.textColor = .systemGreen
        } else {
            cell.profitLabel.text = "- \((-profit).clean)%"
            cell.profitLabel.textColor = .systemRed
        }
        
        
        cell.coinPriceLabel.text = "\(doublePrice(rowCoin.price ?? 0))"
        
        cell.nameLabel.text = rowCoin.name
        cell.symbolLabel.text = rowCoin.symbol?.uppercased()
        cell.iconImageView.image = UIImage(named: rowCoin.symbol ?? "btc")
        cell.holdingsLabel.text = holdingAmount.clean
        
        cell.holdingsLabel.hero.id = "Holdings"
        cell.nameLabel.hero.id = "Name"
        cell.symbolLabel.hero.id = "Symbol"
        cell.iconImageView.hero.id = "Icon"
        cell.profitLabel.hero.id = "Profit"
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowDetails", sender: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

func doublePrice(_ value:Double, noDollarSign: Bool = false) -> String {
    let currencyFormatter = NumberFormatter()
    currencyFormatter.usesGroupingSeparator = true
    currencyFormatter.numberStyle = .currency
    currencyFormatter.locale = Locale.current
    currencyFormatter.currencySymbol = noDollarSign ? "" : "$"
    return currencyFormatter.string(from: NSNumber(value:value)) ?? ""
}
