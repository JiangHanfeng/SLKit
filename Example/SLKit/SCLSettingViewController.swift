//
//  SCLSettingViewController.swift
//  SLKit_Example
//
//  Created by 蒋函锋 on 2023/12/18.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import UIKit
import SnapKit

class SCLSettingViewController: SCLBaseViewController {
    
    enum Section {
    case one, two
    }
    
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Section, SCLSettingCellModel>!
    private var snapshot: NSDiffableDataSourceSnapshot<Section, SCLSettingCellModel>!
    
    private var items = [
        [
            SCLSettingCellModel(image: UIImage(named: "icon_phone"), title: "设备名称", content: ""),
            SCLSettingCellModel(image: UIImage(named: "icon_ calibration"), title: "屏幕校准", content: "")
        ],
        [
            SCLSettingCellModel(image: UIImage(named: "icon_feature_introduce"), title: "功能介绍", content: ""),
            SCLSettingCellModel(image: UIImage(named: "icon_about"), title: "关于超级互联Lite", content: "")
        ]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "设置"
        
        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(60))
        let item = NSCollectionLayoutItem(layoutSize: size)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 12, leading: 12, bottom: 12, trailing: 12)
        
        let background = NSCollectionLayoutDecorationItem.background(elementKind: "background")
        background.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        section.decorationItems = [background]
        let layout = UICollectionViewCompositionalLayout(section: section)
        layout.register(SCLSettingSectionBackgroundView.self, forDecorationViewOfKind: "background")
           
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .init(red: 247/255.0, green: 247/255.0, blue: 247/255.0, alpha: 1)
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.size.equalToSuperview()
            make.center.equalToSuperview()
        }
        
        collectionView.register(UINib(nibName: String(describing: SCLSettingCell.self), bundle: Bundle.main), forCellWithReuseIdentifier: SCLSettingCell.reuseIdentifier)
        
        dataSource = UICollectionViewDiffableDataSource<Section, SCLSettingCellModel>(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SCLSettingCell.reuseIdentifier, for: indexPath) as! SCLSettingCell
            cell.imageView.image = itemIdentifier.image
            cell.titleLabel.text = itemIdentifier.title
            cell.contentLabel.text = itemIdentifier.content
            return cell
        }
        
        snapshot = NSDiffableDataSourceSnapshot<Section, SCLSettingCellModel>()
        snapshot.appendSections([.one, .two])
        snapshot.appendItems(items.first!, toSection: .one)
        snapshot.appendItems(items.last!, toSection: .two)
        
        dataSource.apply(snapshot)
        
        collectionView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}

extension SCLSettingViewController : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.toast(items[indexPath.section][indexPath.row].title ?? "")
    }
}
