//
//  DetailsViewController.swift
//  CryptoWalletTest
//
//  Created by Матвей Анисович on 6/11/21.
//

import UIKit

class DetailsViewController: UIViewController {
    
    var walletVC: WalletViewController!
    let gray: UIColor = .init(red: 80 / 255, green: 84 / 255, blue: 97 / 255, alpha: 1)
    var selectedCoinIndex = 0
    var selectedDateIndex = 0
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var chart: Chart!
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var symbolLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var holdingsLabel: UILabel!
    @IBOutlet weak var profitLabel: UILabel!
    
    @IBAction func periodChanged(_ sender: UISegmentedControl) {
        selectedDateIndex = sender.selectedSegmentIndex
        if selectedDateIndex == 0 {
            chart.selectedPeriod = 4 * 60 * 60
        } else if selectedDateIndex == 1 {
            chart.selectedPeriod = 24 * 60 * 60
        } else if selectedDateIndex == 2 {
            chart.selectedPeriod = 5 * 24 * 60 * 60
        }
        updateChart()
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.delegate = self
        collectionView.dataSource = self
        
        updateChart()
        updateUI()
    }
    func updateUI() {
        let coin = walletVC.coins[selectedCoinIndex]
        iconImageView.image = UIImage(named: coin.symbol ?? "btc")
        symbolLabel.text = coin.symbol?.uppercased()
        nameLabel.text = coin.name
        let cell = (walletVC.tableView.cellForRow(at: IndexPath(row: 0, section: selectedCoinIndex)) as! CoinTableViewCell)
        holdingsLabel.text = cell.holdingsLabel.text
        profitLabel.text = cell.profitLabel.text
        profitLabel.textColor = cell.profitLabel.textColor
    }
    func updateChart() {
        CoinCap().history(for: walletVC.coins[selectedCoinIndex], days: [1,7,30][selectedDateIndex]) { points in
            self.chart.prices = points
            DispatchQueue.main.async {
                self.chart.setupLabelValues()
                self.chart.setup()
            }
        }
    }
}

extension DetailsViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return walletVC.coinIds.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CoinSelectionViewCell
        cell.layer.borderWidth = 0.5
        cell.layer.cornerRadius = 6
        cell.layer.borderColor = gray.cgColor
        
        if selectedCoinIndex == indexPath.row {
            cell.backgroundColor = gray
        } else {
            cell.backgroundColor = .clear
        }
        
        let rowCoin = walletVC.coins[indexPath.row]
        cell.iconImageView.image = UIImage(named: rowCoin.symbol ?? "btc")
        cell.symbolLabel.text = rowCoin.symbol?.uppercased()
        cell.nameLabel.text = rowCoin.name
        
        let coinCellInWallet: (CoinTableViewCell) = (walletVC.tableView.cellForRow(at: IndexPath(row: 0, section: indexPath.row)) as! CoinTableViewCell)
        cell.holdingsLabel.text = coinCellInWallet.holdingsLabel.text
        cell.profitLabel.text = coinCellInWallet.profitLabel.text
        cell.profitLabel.textColor = coinCellInWallet.profitLabel.textColor
        
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCoinIndex = indexPath.row
        collectionView.deselectItem(at: indexPath, animated: true)
        collectionView.reloadData()
        updateUI()
        updateChart()
    }
}
